import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../sync/record_patch.dart';
import '../sync/sync_remote.dart';

/// [SyncRemote] backed by Supabase: Postgres tables, the apply_patch()
/// function from supabase/schema.sql, and Realtime for live changes.
class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this.client, {Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final SupabaseClient client;
  final Connectivity _connectivity;

  static const tables = ['profiles', 'lists', 'list_members', 'items', 'activities', 'usuals'];

  final _changes = StreamController<RecordPatch>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  RealtimeChannel? _channel;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  Future<List<RecordPatch>> fetchAll() {
    return _guard(() async {
      final result = <RecordPatch>[];
      for (final table in tables) {
        // Row level security only returns rows this person may see.
        var query = client.from(table).select();
        final List<Map<String, dynamic>> rows;
        if (table == 'activities') {
          // The feed only shows the newest ones, no need to load years of it.
          rows = await query.order('created_at', ascending: false).limit(300);
        } else {
          rows = await query;
        }
        result.addAll(rows.map((row) => RecordPatch.fromServerRow(table, row)));
      }
      return result;
    });
  }

  @override
  Future<void> push(RecordPatch patch) {
    return _guard(() => client.rpc<void>('apply_patch', params: {
          'p_table': patch.table,
          'p_id': patch.id,
          'p_values': patch.values,
          'p_times': patch.times,
        }));
  }

  @override
  Stream<RecordPatch> changes() {
    if (_channel == null) {
      var channel = client.channel('fridge-note-sync');
      for (final table in tables) {
        channel = channel.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isEmpty || _changes.isClosed) return;
            _changes.add(RecordPatch.fromServerRow(table, row));
          },
        );
      }
      _channel = channel.subscribe((status, error) {
        if (_connection.isClosed) return;
        _connection.add(status == RealtimeSubscribeStatus.subscribed);
      });
    }
    return _changes.stream;
  }

  @override
  Stream<bool> connection() {
    _connectivitySub ??= _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (!_connection.isClosed) _connection.add(online);
    });
    return _connection.stream;
  }

  @override
  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    if (_channel != null) await client.removeChannel(_channel!);
    await _changes.close();
    await _connection.close();
  }

  /// Turns Supabase errors into the two cases the sync engine understands.
  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (error) {
      // The server answered but said no (bad data, row level security...).
      // Trying again would not help.
      throw RemoteRejected(error.message);
    } on RemoteRejected {
      rethrow;
    } catch (error) {
      // No answer at all: offline, timeout, DNS...
      throw RemoteUnavailable(error.toString());
    }
  }
}
