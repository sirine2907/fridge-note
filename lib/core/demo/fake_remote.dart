import 'dart:async';

import '../sync/merge.dart';
import '../sync/record_patch.dart';
import '../sync/sync_remote.dart';

/// An in-memory stand-in for Supabase, used by demo mode and tests.
///
/// It keeps rows the same way the real server does (values + field times),
/// merges pushes with the same per-field rule, and only shows a person the
/// lists they are a member of, like the row level security on Supabase.
class FakeRemote implements SyncRemote {
  FakeRemote({
    required this.userId,
    List<RecordPatch> seed = const [],
    this.latency = const Duration(milliseconds: 180),
  }) {
    for (final patch in seed) {
      _merge(patch);
    }
  }

  /// Who is signed in on this device.
  final String userId;
  final Duration latency;

  /// table -> id -> values
  final _rows = <String, Map<String, Map<String, Object?>>>{};

  /// table -> id -> field times
  final _times = <String, Map<String, Map<String, int>>>{};

  final _changes = StreamController<RecordPatch>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  bool _online = true;

  /// Invite codes -> list id.
  final invites = <String, String>{};

  bool get isOnline => _online;

  /// Pretend the phone lost (or got back) its connection.
  set online(bool value) {
    if (value == _online) return;
    _online = value;
    _connection.add(value);
  }

  // ------------------------------------------------------------ SyncRemote

  @override
  Future<List<RecordPatch>> fetchAll() async {
    await _wait();
    final result = <RecordPatch>[];
    for (final table in _rows.keys) {
      for (final id in _rows[table]!.keys) {
        final patch = _fullRow(table, id);
        if (_isVisible(patch)) result.add(patch);
      }
    }
    return result;
  }

  @override
  Future<void> push(RecordPatch patch) async {
    await _wait();
    receive(patch);
  }

  @override
  Stream<RecordPatch> changes() => _changes.stream;

  @override
  Stream<bool> connection() => _connection.stream;

  @override
  Future<void> dispose() async {
    await _changes.close();
    await _connection.close();
  }

  // --------------------------------------------------------- server side

  /// A change arriving at the server, from this phone or someone else's.
  /// Merges it and tells everyone who can see the row.
  void receive(RecordPatch patch) {
    final wasMemberBefore = _memberLists();
    if (!_merge(patch)) return;
    final row = _fullRow(patch.table, patch.id);
    _broadcast(row);

    // Someone just joined a list: send them everything in it.
    final newLists = _memberLists().difference(wasMemberBefore);
    for (final listId in newLists) {
      for (final table in _rows.keys) {
        for (final id in _rows[table]!.keys) {
          final other = _fullRow(table, id);
          if (other.values['list_id'] == listId || (table == 'lists' && id == listId)) {
            _broadcast(other);
          }
        }
      }
    }
  }

  /// Read access for the demo partner.
  List<Map<String, Object?>> rowsOf(String table) {
    final rows = _rows[table] ?? {};
    return [
      for (final entry in rows.entries) {...entry.value, 'id': entry.key},
    ];
  }

  Map<String, Object?>? row(String table, String id) {
    final values = _rows[table]?[id];
    return values == null ? null : {...values, 'id': id};
  }

  bool _merge(RecordPatch patch) {
    final rows = _rows.putIfAbsent(patch.table, () => {});
    final times = _times.putIfAbsent(patch.table, () => {});
    final result = mergeFields(
      currentValues: rows[patch.id] ?? {},
      currentTimes: times[patch.id] ?? {},
      incomingValues: patch.values,
      incomingTimes: patch.times,
    );
    if (!result.changed && rows.containsKey(patch.id)) return false;
    rows[patch.id] = result.values;
    times[patch.id] = result.times;
    return true;
  }

  RecordPatch _fullRow(String table, String id) {
    return RecordPatch(
      table: table,
      id: id,
      values: Map.of(_rows[table]![id]!),
      times: Map.of(_times[table]![id]!),
    );
  }

  void _broadcast(RecordPatch row) {
    // While "offline" this phone misses realtime events. It catches up with
    // fetchAll when the connection comes back, like the real app.
    if (!_online || _changes.isClosed) return;
    if (_isVisible(row)) _changes.add(row);
  }

  Set<String> _memberLists() {
    final members = _rows['list_members'] ?? {};
    return {
      for (final row in members.values)
        if (row['user_id'] == userId && row['deleted'] != true) row['list_id'] as String,
    };
  }

  bool _isVisible(RecordPatch row) {
    switch (row.table) {
      case 'profiles':
        return true;
      case 'usuals':
        return row.values['owner_id'] == userId;
      case 'lists':
        return _memberLists().contains(row.id);
      default:
        return _memberLists().contains(row.values['list_id']);
    }
  }

  Future<void> _wait() async {
    await Future<void>.delayed(latency);
    if (!_online) throw const RemoteUnavailable('Demo is offline');
  }
}
