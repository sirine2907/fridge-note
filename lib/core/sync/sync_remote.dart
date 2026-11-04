import 'record_patch.dart';

/// The server side of sync. The app only talks to this interface, so the
/// Supabase version and the in-memory demo version are interchangeable.
abstract class SyncRemote {
  /// Every row the signed-in person is allowed to see.
  Future<List<RecordPatch>> fetchAll();

  /// Sends one change. Throws [RemoteUnavailable] when the server can't be reached.
  /// The server merges it field by field, the same way the app does.
  Future<void> push(RecordPatch patch);

  /// Full rows changed by anyone (including us), as they happen.
  Stream<RecordPatch> changes();

  /// Emits true when the connection comes back and false when it drops.
  Stream<bool> connection();

  Future<void> dispose();
}

class RemoteUnavailable implements Exception {
  const RemoteUnavailable([this.message = 'Server not reachable']);

  final String message;

  @override
  String toString() => 'RemoteUnavailable: $message';
}
