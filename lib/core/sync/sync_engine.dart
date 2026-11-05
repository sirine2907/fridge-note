import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import 'local_clock.dart';
import 'local_store.dart';
import 'record_patch.dart';
import 'sync_remote.dart';
import 'sync_status.dart';

export 'sync_status.dart';

/// Moves changes between the local database and the server.
///
/// - Local edits are already in the outbox (see [LocalStore.applyLocal]).
///   [flush] sends them one by one, oldest first, and only deletes an entry
///   once the server has accepted it. If a push fails we stop and try again
///   later, so nothing is lost and the order is kept.
/// - Remote changes from realtime are merged into the local database.
/// - When the connection comes back we pull a full snapshot, in case we missed
///   realtime events while offline.
class SyncEngine {
  SyncEngine({
    required this.db,
    required this.store,
    required this.remote,
    required this.clock,
    this.retryEvery = const Duration(seconds: 15),
  });

  final AppDatabase db;
  final LocalStore store;
  final SyncRemote remote;
  final LocalClock clock;
  final Duration retryEvery;

  final _phaseChanges = StreamController<void>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  Timer? _retryTimer;

  SyncPhase _phase = SyncPhase.syncing;
  DateTime? _lastSyncedAt;
  bool _flushing = false;
  bool _flushAgain = false;
  bool _disposed = false;

  SyncPhase get phase => _phase;

  Future<void> start() async {
    _subscriptions
      ..add(remote.changes().listen(_onRemoteChange))
      ..add(store.localChanges.listen((_) => flush()))
      ..add(remote.connection().listen(_onConnectionChanged));
    _retryTimer = Timer.periodic(retryEvery, (_) {
      if (_phase == SyncPhase.offline) _catchUp();
    });
    await _catchUp();
  }

  /// Pulls everything from the server, then pushes our pending changes.
  Future<void> _catchUp() async {
    await pull();
    await flush();
  }

  Future<void> pull() async {
    try {
      final rows = await remote.fetchAll();
      if (_disposed) return;
      for (final row in rows) {
        clock.observe(row.newestTime);
      }
      await store.applyRemote(rows);
      _lastSyncedAt = DateTime.now();
      _setPhase(SyncPhase.synced);
    } on RemoteUnavailable {
      _setPhase(SyncPhase.offline);
    } on RemoteRejected catch (error) {
      debugPrint('Snapshot refused: ${error.message}');
    }
  }

  /// Sends the outbox to the server.
  Future<void> flush() async {
    if (_disposed) return;
    if (_flushing) {
      // A new change came in while we were busy. Go round once more after.
      _flushAgain = true;
      return;
    }
    _flushing = true;
    try {
      do {
        _flushAgain = false;
        final ok = await _sendOutbox();
        if (!ok) return;
      } while (_flushAgain);
    } finally {
      _flushing = false;
    }
  }

  /// Returns false if the server could not be reached.
  Future<bool> _sendOutbox() async {
    final entries = await (db.select(db.outbox)
          ..orderBy([(o) => OrderingTerm(expression: o.id)]))
        .get();
    if (entries.isEmpty) {
      if (_phase == SyncPhase.syncing) _setPhase(SyncPhase.synced);
      return true;
    }

    _setPhase(SyncPhase.syncing);
    for (final entry in entries) {
      if (_disposed) return false;
      final patch = RecordPatch(
        table: entry.targetTable,
        id: entry.rowId,
        values: Map<String, Object?>.from(jsonDecode(entry.payload) as Map),
        times: decodeTimes(entry.times),
      );
      try {
        await remote.push(patch);
      } on RemoteUnavailable {
        if (_disposed) return false;
        await (db.update(db.outbox)..where((o) => o.id.equals(entry.id)))
            .write(OutboxCompanion(attempts: Value(entry.attempts + 1)));
        _setPhase(SyncPhase.offline);
        return false;
      } on RemoteRejected catch (error) {
        // Keeping it would block everything behind it forever. The next
        // snapshot puts the server's version back on this phone.
        debugPrint('Dropped ${patch.table}/${patch.id}: ${error.message}');
      }
      // Signed out while the push was on its way: the database is closed now.
      // The entry stays in the outbox of the old database, which is fine.
      if (_disposed) return false;
      await (db.delete(db.outbox)..where((o) => o.id.equals(entry.id))).go();
    }
    _lastSyncedAt = DateTime.now();
    _setPhase(SyncPhase.synced);
    return true;
  }

  Future<void> _onRemoteChange(RecordPatch patch) async {
    if (_disposed) return;
    clock.observe(patch.newestTime);
    try {
      await store.applyRemote([patch]);
      _lastSyncedAt = DateTime.now();
      _phaseChanges.add(null);
      // A membership changed, maybe someone added us to a list. Realtime only
      // sends rows we could already see, so fetch the rest of that list.
      if (patch.table == 'list_members') unawaited(pull());
    } catch (error) {
      debugPrint('Could not apply ${patch.table}/${patch.id}: $error');
    }
  }

  void _onConnectionChanged(bool online) {
    if (online) {
      _catchUp();
    } else {
      _setPhase(SyncPhase.offline);
    }
  }

  void _setPhase(SyncPhase phase) {
    if (_disposed) return;
    _phase = phase;
    _phaseChanges.add(null);
  }

  Stream<int> _pendingCount() {
    final count = db.outbox.id.count();
    return (db.selectOnly(db.outbox)..addColumns([count]))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  Stream<SyncStatus> watchStatus() {
    late final StreamController<SyncStatus> controller;
    StreamSubscription<int>? pendingSub;
    StreamSubscription<void>? phaseSub;
    var pending = 0;

    void emit() {
      if (controller.isClosed) return;
      controller.add(SyncStatus(phase: _phase, pending: pending, lastSyncedAt: _lastSyncedAt));
    }

    controller = StreamController<SyncStatus>(
      onListen: () {
        pendingSub = _pendingCount().listen((value) {
          pending = value;
          emit();
        });
        phaseSub = _phaseChanges.stream.listen((_) => emit());
        emit();
      },
      onCancel: () async {
        await pendingSub?.cancel();
        await phaseSub?.cancel();
      },
    );
    return controller.stream;
  }

  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _phaseChanges.close();
  }
}
