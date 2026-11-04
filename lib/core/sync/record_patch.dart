import 'dart:convert';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// One change to one row: some column values, each with the time it was made.
///
/// Local edits, outbox entries, server rows and realtime events all use this
/// same shape, so there is only one merge function for all of them.
class RecordPatch extends Equatable {
  const RecordPatch({
    required this.table,
    required this.id,
    required this.values,
    required this.times,
  });

  /// A change made on this device, where every column has the same time.
  factory RecordPatch.local({
    required String table,
    required String id,
    required Map<String, Object?> values,
    required int at,
  }) {
    return RecordPatch(
      table: table,
      id: id,
      values: values,
      times: {for (final key in values.keys) key: at},
    );
  }

  /// A full row as the server sends it (with field_times and updated_at).
  factory RecordPatch.fromServerRow(String table, Map<String, dynamic> row) {
    final values = Map<String, Object?>.of(row);
    final rawTimes = values.remove('field_times');
    final updatedAt = (values.remove('updated_at') as num?)?.toInt() ?? 0;
    final id = values.remove('id').toString();

    final times = decodeTimes(rawTimes);
    // Columns without their own time fall back to the row time.
    for (final key in values.keys) {
      times.putIfAbsent(key, () => updatedAt);
    }
    return RecordPatch(table: table, id: id, values: values, times: times);
  }

  final String table;
  final String id;
  final Map<String, Object?> values;
  final Map<String, int> times;

  int get newestTime => times.values.fold(0, math.max);

  @override
  List<Object?> get props => [table, id, values, times];

  @override
  String toString() => 'RecordPatch($table/$id, $values)';
}

/// Reads field_times, which is a JSON string locally and a map from Supabase.
Map<String, int> decodeTimes(Object? raw) {
  if (raw == null) return {};
  final map = raw is String ? jsonDecode(raw) as Map<String, dynamic> : raw as Map;
  return {
    for (final entry in map.entries) entry.key.toString(): (entry.value as num).toInt(),
  };
}
