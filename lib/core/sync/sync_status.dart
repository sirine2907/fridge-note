import 'package:equatable/equatable.dart';

enum SyncPhase { syncing, synced, offline }

class SyncStatus extends Equatable {
  const SyncStatus({required this.phase, required this.pending, this.lastSyncedAt});

  final SyncPhase phase;

  /// Local changes still waiting in the outbox.
  final int pending;
  final DateTime? lastSyncedAt;

  @override
  List<Object?> get props => [phase, pending, lastSyncedAt];
}
