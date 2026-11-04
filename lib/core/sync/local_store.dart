import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import 'merge.dart';
import 'record_patch.dart';

/// The only place that writes synced rows to the local database.
///
/// Local edits go through [applyLocal], which also adds them to the outbox.
/// Changes from the server go through [applyRemote]. Both merge field by
/// field, so neither side can wipe out a newer value.
class LocalStore {
  LocalStore(this.db);

  final AppDatabase db;
  final _localChanges = StreamController<void>.broadcast();

  /// Fires after every local edit, so the sync engine can push right away.
  Stream<void> get localChanges => _localChanges.stream;

  Future<void> applyLocal(List<RecordPatch> patches) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction(() async {
      for (final patch in patches) {
        await _merge(patch);
        await db.into(db.outbox).insert(OutboxCompanion.insert(
              targetTable: patch.table,
              rowId: patch.id,
              payload: jsonEncode(patch.values),
              times: jsonEncode(patch.times),
              createdAt: now,
            ));
      }
    });
    _localChanges.add(null);
  }

  /// Returns how many of the patches actually changed something.
  Future<int> applyRemote(List<RecordPatch> patches) {
    return db.transaction(() async {
      var changed = 0;
      for (final patch in patches) {
        if (await _merge(patch)) changed++;
      }
      return changed;
    });
  }

  Future<bool> _merge(RecordPatch patch) async {
    final table = db.tableByName(patch.table);
    final idColumn = table.columnsByName['id']! as GeneratedColumn<String>;
    final existing = await (db.select(table)..where((_) => idColumn.equals(patch.id)))
        .getSingleOrNull();

    var currentValues = <String, Object?>{};
    var currentTimes = <String, int>{};
    if (existing != null) {
      final json = (existing as DataClass).toJson();
      currentTimes = decodeTimes(json.remove('field_times'));
      json.remove('updated_at');
      currentValues = json;
    }

    final result = mergeFields(
      currentValues: currentValues,
      currentTimes: currentTimes,
      incomingValues: patch.values,
      incomingTimes: patch.times,
    );
    if (existing != null && !result.changed) return false;

    final row = <String, Object?>{
      ...result.values,
      'id': patch.id,
      'field_times': jsonEncode(result.times),
      'updated_at': result.times.values.fold<int>(0, (a, b) => a > b ? a : b),
    };

    if (existing == null && !_fillDefaults(table, row)) {
      // A partial change for a row we have never seen. The full row will come
      // with the next snapshot, so it is safe to skip it.
      debugPrint('Skipped partial ${patch.table}/${patch.id}');
      return false;
    }

    await db.into(table).insertOnConflictUpdate(db.rowFromJson(patch.table, row));
    return true;
  }

  /// Adds column defaults for a new row. Returns false if a required column is missing.
  bool _fillDefaults(TableInfo<Table, dynamic> table, Map<String, Object?> row) {
    for (final column in table.$columns) {
      if (row.containsKey(column.name)) continue;
      final defaultValue = column.defaultValue;
      if (defaultValue is Constant) {
        row[column.name] = defaultValue.value;
      } else if (column.$nullable) {
        row[column.name] = null;
      } else {
        return false;
      }
    }
    return true;
  }

  Future<void> dispose() => _localChanges.close();
}
