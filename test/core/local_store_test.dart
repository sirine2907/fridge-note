import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_note/core/database/app_database.dart';
import 'package:fridge_note/core/sync/local_store.dart';
import 'package:fridge_note/core/sync/record_patch.dart';

void main() {
  late AppDatabase db;
  late LocalStore store;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    store = LocalStore(db);
  });

  tearDown(() async {
    await store.dispose();
    await db.close();
  });

  RecordPatch milk({required int at}) => RecordPatch.local(table: 'items', id: 'milk', at: at, values: {
        'list_id': 'list-1',
        'name': 'Milk',
        'category': 'dairy',
        'quantity': 1,
        'unit': 'L',
        'price': 1.2,
        'checked': false,
        'checked_by': null,
        'position': 1000.0,
        'added_by': 'sirine',
        'created_at': at,
        'deleted': false,
      });

  test('a local change is saved and queued in the outbox', () async {
    await store.applyLocal([milk(at: 100)]);

    final item = await db.select(db.items).getSingle();
    expect(item.name, 'Milk');
    expect(item.updatedAt, 100);

    final outbox = await db.select(db.outbox).get();
    expect(outbox, hasLength(1));
    expect(outbox.single.rowId, 'milk');
  });

  test('a remote change does not go into the outbox', () async {
    await store.applyRemote([milk(at: 100)]);

    expect(await db.select(db.items).get(), hasLength(1));
    expect(await db.select(db.outbox).get(), isEmpty);
  });

  test('an older remote value does not overwrite a newer local one', () async {
    await store.applyLocal([milk(at: 100)]);
    await store.applyLocal([
      RecordPatch.local(table: 'items', id: 'milk', at: 300, values: {'checked': true}),
    ]);

    final changed = await store.applyRemote([
      RecordPatch.local(table: 'items', id: 'milk', at: 200, values: {'checked': false, 'quantity': 3}),
    ]);

    final item = await db.select(db.items).getSingle();
    expect(changed, 1);
    expect(item.checked, isTrue, reason: 'the local toggle is newer');
    expect(item.quantity, 3, reason: 'quantity had no newer local change');
  });

  test('a partial change for an unknown row is skipped', () async {
    final changed = await store.applyRemote([
      RecordPatch.local(table: 'items', id: 'ghost', at: 10, values: {'checked': true}),
    ]);

    expect(changed, 0);
    expect(await db.select(db.items).get(), isEmpty);
  });

  test('missing columns get their defaults', () async {
    await store.applyRemote([
      RecordPatch.local(table: 'items', id: 'eggs', at: 10, values: {
        'list_id': 'list-1',
        'name': 'Eggs',
        'added_by': 'anis',
      }),
    ]);

    final item = await db.select(db.items).getSingle();
    expect(item.quantity, 1);
    expect(item.unit, 'pcs');
    expect(item.checked, isFalse);
    expect(item.checkedBy, isNull);
  });
}
