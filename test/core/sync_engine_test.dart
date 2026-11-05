import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_note/core/database/app_database.dart';
import 'package:fridge_note/core/demo/fake_remote.dart';
import 'package:fridge_note/core/sync/local_clock.dart';
import 'package:fridge_note/core/sync/local_store.dart';
import 'package:fridge_note/core/sync/record_patch.dart';
import 'package:fridge_note/core/sync/sync_engine.dart';
import 'package:fridge_note/core/sync/sync_remote.dart';
import 'package:fridge_note/features/lists/data/repositories/lists_repository_impl.dart';

const me = 'sirine';
const other = 'anis';

/// A shared list with one item, Milk, as it is on the server at time 100.
List<RecordPatch> seed() => [
      RecordPatch.local(table: 'profiles', id: me, at: 100, values: {'name': 'Sirine', 'color': 1}),
      RecordPatch.local(table: 'profiles', id: other, at: 100, values: {'name': 'Anis', 'color': 2}),
      RecordPatch.local(table: 'lists', id: 'list', at: 100, values: {
        'name': 'Weekly',
        'store': '',
        'owner_id': me,
        'created_at': 100,
        'deleted': false,
      }),
      RecordPatch.local(table: 'list_members', id: 'list:$me', at: 100, values: {
        'list_id': 'list',
        'user_id': me,
        'deleted': false,
      }),
      RecordPatch.local(table: 'items', id: 'milk', at: 100, values: {
        'list_id': 'list',
        'name': 'Milk',
        'quantity': 1,
        'checked': false,
        'checked_by': null,
        'position': 1000.0,
        'added_by': other,
        'deleted': false,
      }),
    ];

class _Harness {
  _Harness({int Function()? now, SyncRemote? remote}) {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    store = LocalStore(db);
    clock = LocalClock(now: now);
    this.remote = remote ?? FakeRemote(userId: me, seed: seed(), latency: Duration.zero);
    engine = SyncEngine(db: db, store: store, remote: this.remote, clock: clock);
    lists = ListsRepositoryImpl(db: db, store: store, clock: clock, userId: me);
  }

  late final AppDatabase db;
  late final LocalStore store;
  late final LocalClock clock;
  late final SyncRemote remote;
  late final SyncEngine engine;
  late final ListsRepositoryImpl lists;

  FakeRemote get fake => remote as FakeRemote;

  Future<ItemRow> localMilk() => (db.select(db.items)..where((i) => i.id.equals('milk'))).getSingle();

  Future<int> outboxSize() async => (await db.select(db.outbox).get()).length;

  Future<void> dispose() async {
    await engine.dispose();
    await remote.dispose();
    await store.dispose();
    await db.close();
  }
}

/// Waits until the sync engine has handled everything that is queued.
Future<void> idle() => pumpEventQueue(times: 50);

void main() {
  late _Harness h;

  tearDown(() => h.dispose());

  test('start pulls the server snapshot into the local database', () async {
    h = _Harness();
    await h.engine.start();

    final milk = await h.localMilk();
    expect(milk.name, 'Milk');
    expect(h.engine.phase, SyncPhase.synced);
  });

  test('a local change is pushed and then removed from the outbox', () async {
    h = _Harness();
    await h.engine.start();

    final item = (await h.lists.watchItems('list').first).single;
    await h.lists.setChecked(item, true);
    await idle();

    expect(await h.outboxSize(), 0);
    expect(h.fake.row('items', 'milk')!['checked'], isTrue);
    expect(h.fake.row('items', 'milk')!['checked_by'], me);
  });

  test('offline changes wait in the outbox and go out when the connection is back', () async {
    h = _Harness();
    await h.engine.start();
    h.fake.online = false;
    await idle();

    final item = (await h.lists.watchItems('list').first).single;
    await h.lists.setChecked(item, true);
    await h.lists.setQuantity(item, 3);
    await idle();

    expect(h.engine.phase, SyncPhase.offline);
    expect(await h.outboxSize(), greaterThan(0));
    expect(h.fake.row('items', 'milk')!['checked'], isFalse, reason: 'nothing reached the server');
    final local = await h.localMilk();
    expect(local.checked, isTrue, reason: 'the screen reads local data, so it already shows the check');

    h.fake.online = true;
    await idle();

    expect(await h.outboxSize(), 0);
    expect(h.fake.row('items', 'milk')!['checked'], isTrue);
    expect(h.fake.row('items', 'milk')!['quantity'], 3);
  });

  test('a change from the other phone arrives through realtime', () async {
    h = _Harness();
    await h.engine.start();

    h.fake.receive(RecordPatch.local(table: 'items', id: 'milk', at: 500, values: {
      'checked': true,
      'checked_by': other,
    }));
    await idle();

    final milk = await h.localMilk();
    expect(milk.checked, isTrue);
    expect(milk.checkedBy, other);
  });

  test('changes missed while offline are caught up from a snapshot', () async {
    h = _Harness();
    await h.engine.start();
    h.fake.online = false;
    await idle();

    // Anis keeps shopping. This phone doesn't get the realtime event.
    h.fake.receive(RecordPatch.local(table: 'items', id: 'milk', at: 500, values: {'quantity': 4}));
    await idle();
    expect((await h.localMilk()).quantity, 1);

    h.fake.online = true;
    await idle();
    expect((await h.localMilk()).quantity, 4);
  });

  test('an offline toggle survives a later rename and quantity change by someone else', () async {
    var now = 1000;
    h = _Harness(now: () => now);
    await h.engine.start();
    h.fake.online = false;
    await idle();

    // 10:00 Sirine, offline in the shop, checks off Milk.
    final item = (await h.lists.watchItems('list').first).single;
    await h.lists.setChecked(item, true);

    // 10:05 Anis renames it and changes the quantity. The server has it, we don't.
    h.fake.receive(RecordPatch.local(table: 'items', id: 'milk', at: 5000, values: {
      'name': 'Oat milk',
      'quantity': 2,
    }));

    // 10:10 Sirine gets signal again.
    now = 10000;
    h.fake.online = true;
    await idle();

    final local = await h.localMilk();
    final server = h.fake.row('items', 'milk')!;
    for (final row in [
      {'name': local.name, 'quantity': local.quantity, 'checked': local.checked},
      {'name': server['name'], 'quantity': server['quantity'], 'checked': server['checked']},
    ]) {
      expect(row, {'name': 'Oat milk', 'quantity': 2, 'checked': true});
    }
  });

  test('an older uncheck from a snapshot does not undo a newer local check', () async {
    var now = 1000;
    h = _Harness(now: () => now);
    await h.engine.start();
    h.fake.online = false;
    await idle();

    // Anis unchecked it at 900 (it was never checked, but the time matters).
    h.fake.receive(RecordPatch.local(table: 'items', id: 'milk', at: 900, values: {'checked': false}));

    final item = (await h.lists.watchItems('list').first).single;
    await h.lists.setChecked(item, true); // at 1000

    h.fake.online = true;
    await idle();

    expect((await h.localMilk()).checked, isTrue);
    expect(h.fake.row('items', 'milk')!['checked'], isTrue);
  });

  test('two people toggling: the later toggle wins on both phones', () async {
    var now = 1000;
    h = _Harness(now: () => now);
    await h.engine.start();
    h.fake.online = false;
    await idle();

    final item = (await h.lists.watchItems('list').first).single;
    await h.lists.setChecked(item, true); // Sirine checks at 1000
    h.fake.receive(RecordPatch.local(table: 'items', id: 'milk', at: 2000, values: {
      'checked': false, // Anis puts it back at 2000
      'checked_by': null,
    }));

    h.fake.online = true;
    await idle();

    expect((await h.localMilk()).checked, isFalse);
    expect(h.fake.row('items', 'milk')!['checked'], isFalse);
  });

  test('a toggle made right after seeing a remote change wins even with a slow clock', () async {
    // This phone's clock is far behind the server.
    h = _Harness(now: () => 10);
    await h.engine.start();

    h.fake.receive(RecordPatch.local(table: 'items', id: 'milk', at: 90000, values: {'checked': true}));
    await idle();

    final item = (await h.lists.watchItems('list').first).single;
    expect(item.checked, isTrue);
    await h.lists.setChecked(item, false);
    await idle();

    expect((await h.localMilk()).checked, isFalse);
    expect(h.fake.row('items', 'milk')!['checked'], isFalse);
  });

  test('a change the server refuses is dropped so the rest can go through', () async {
    final remote = _RefusesQuantity(FakeRemote(userId: me, seed: seed(), latency: Duration.zero));
    h = _Harness(remote: remote);
    await h.engine.start();

    final item = (await h.lists.watchItems('list').first).single;
    await h.lists.setQuantity(item, 5);
    await h.lists.setChecked(item, true);
    await idle();

    expect(await h.outboxSize(), 0);
    expect(remote.inner.row('items', 'milk')!['checked'], isTrue);
    expect(remote.inner.row('items', 'milk')!['quantity'], 1);
  });

  test('the status stream reports pending changes', () async {
    h = _Harness();
    await h.engine.start();
    h.fake.online = false;
    await idle();

    final statuses = <SyncStatus>[];
    final sub = h.engine.watchStatus().listen(statuses.add);
    final item = (await h.lists.watchItems('list').first).single;
    await h.lists.setChecked(item, true);
    await idle();

    expect(statuses.last.phase, SyncPhase.offline);
    expect(statuses.last.pending, 2, reason: 'the item change and its activity line');
    await sub.cancel();
  });
}

/// Wraps the fake server and refuses every quantity change.
class _RefusesQuantity implements SyncRemote {
  _RefusesQuantity(this.inner);

  final FakeRemote inner;

  @override
  Future<void> push(RecordPatch patch) async {
    if (patch.values.containsKey('quantity') && patch.table == 'items') {
      throw const RemoteRejected('quantity not allowed');
    }
    await inner.push(patch);
  }

  @override
  Future<List<RecordPatch>> fetchAll() => inner.fetchAll();

  @override
  Stream<RecordPatch> changes() => inner.changes();

  @override
  Stream<bool> connection() => inner.connection();

  @override
  Future<void> dispose() => inner.dispose();
}
