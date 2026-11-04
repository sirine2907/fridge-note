import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/local_clock.dart';
import '../../../../core/sync/local_store.dart';
import '../../../../core/sync/record_patch.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/list_item.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/repositories/lists_repository.dart';

/// Reads from drift and writes through [LocalStore], which also fills the outbox.
class ListsRepositoryImpl implements ListsRepository {
  ListsRepositoryImpl({
    required this.db,
    required this.store,
    required this.clock,
    required this.userId,
  });

  final AppDatabase db;
  final LocalStore store;
  final LocalClock clock;

  /// The signed-in person.
  final String userId;

  static const _uuid = Uuid();

  // ---------------------------------------------------------------- reads

  @override
  Stream<List<ShoppingList>> watchLists() {
    final query = db.customSelect(
      '''
      SELECT l.*,
        (SELECT COUNT(*) FROM items i
          WHERE i.list_id = l.id AND i.deleted = 0) AS item_count,
        (SELECT COUNT(*) FROM items i
          WHERE i.list_id = l.id AND i.deleted = 0 AND i.checked = 0) AS left_count,
        (SELECT COALESCE(SUM(i.price * i.quantity), 0) FROM items i
          WHERE i.list_id = l.id AND i.deleted = 0) AS total
      FROM lists l
      WHERE l.deleted = 0
      ORDER BY l.created_at, l.name
      ''',
      readsFrom: {db.shoppingLists, db.items, db.listMembers, db.profiles},
    );

    return query.watch().asyncMap((rows) async {
      final people = await _people();
      final membersByList = await _membersByList(people);
      return rows.map((row) {
        final list = db.shoppingLists.map(row.data);
        return ShoppingList(
          id: list.id,
          name: list.name,
          store: list.store,
          ownerId: list.ownerId,
          members: membersByList[list.id] ?? const [],
          itemCount: row.data['item_count'] as int,
          leftCount: row.data['left_count'] as int,
          estimatedTotal: (row.data['total'] as num).toDouble(),
          shopper: list.shopperId == null ? null : _person(people, list.shopperId!),
          tripStartedAt: list.tripStartedAt == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(list.tripStartedAt!),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(list.updatedAt),
        );
      }).toList();
    });
  }

  @override
  Stream<ShoppingList?> watchList(String listId) {
    return watchLists().map((lists) {
      for (final list in lists) {
        if (list.id == listId) return list;
      }
      return null;
    });
  }

  @override
  Stream<List<ListItem>> watchItems(String listId) {
    final query = db.select(db.items)
      ..where((i) => i.listId.equals(listId) & i.deleted.equals(false))
      ..orderBy([(i) => OrderingTerm(expression: i.position), (i) => OrderingTerm(expression: i.createdAt)]);

    return query.watch().asyncMap((rows) async {
      final people = await _people();
      return rows.map((row) => _toItem(row, people)).toList();
    });
  }

  @override
  Stream<List<Activity>> watchActivity(String listId, {int limit = 20}) {
    final query = db.select(db.activities)
      ..where((a) => a.listId.equals(listId))
      ..orderBy([(a) => OrderingTerm(expression: a.createdAt, mode: OrderingMode.desc)])
      ..limit(limit);

    return query.watch().asyncMap((rows) async {
      final people = await _people();
      return rows
          .map((row) => Activity(
                id: row.id,
                listId: row.listId,
                actor: _person(people, row.actorId),
                kind: ActivityKind.fromName(row.kind),
                itemName: row.itemName,
                at: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
              ))
          .toList();
    });
  }

  // --------------------------------------------------------------- writes

  @override
  Future<String> createList({required String name, required String store}) async {
    final id = _uuid.v4();
    final at = clock.next();
    await this.store.applyLocal([
      RecordPatch.local(table: 'lists', id: id, at: at, values: {
        'name': name,
        'store': store,
        'owner_id': userId,
        'shopper_id': null,
        'trip_started_at': null,
        'created_at': at,
        'deleted': false,
      }),
      RecordPatch.local(table: 'list_members', id: '$id:$userId', at: at, values: {
        'list_id': id,
        'user_id': userId,
        'deleted': false,
      }),
    ]);
    return id;
  }

  @override
  Future<void> addItem(NewItem item) async {
    final at = clock.next();
    final last = await (db.selectOnly(db.items)
          ..addColumns([db.items.position.max()])
          ..where(db.items.listId.equals(item.listId)))
        .map((row) => row.read(db.items.position.max()))
        .getSingle();

    await store.applyLocal([
      RecordPatch.local(table: 'items', id: _uuid.v4(), at: at, values: {
        'list_id': item.listId,
        'name': item.name,
        'category': item.category.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'price': item.price,
        'checked': false,
        'checked_by': null,
        'position': (last ?? 0) + 1000,
        'added_by': userId,
        'created_at': at,
        'deleted': false,
      }),
      _activity(item.listId, ActivityKind.added, item.name, at),
    ]);
  }

  @override
  Future<void> setChecked(ListItem item, bool checked) async {
    final at = clock.next();
    await store.applyLocal([
      // Only the two check columns: a rename or quantity change from someone
      // else can never undo this toggle.
      RecordPatch.local(table: 'items', id: item.id, at: at, values: {
        'checked': checked,
        'checked_by': checked ? userId : null,
      }),
      _activity(item.listId, checked ? ActivityKind.checked : ActivityKind.unchecked, item.name, at),
    ]);
  }

  @override
  Future<void> setQuantity(ListItem item, int quantity) async {
    final at = clock.next();
    await store.applyLocal([
      RecordPatch.local(table: 'items', id: item.id, at: at, values: {'quantity': quantity}),
      _activity(item.listId, ActivityKind.quantity, '${item.name} to $quantity ${item.unit}', at),
    ]);
  }

  @override
  Future<void> removeItem(ListItem item) async {
    final at = clock.next();
    await store.applyLocal([
      RecordPatch.local(table: 'items', id: item.id, at: at, values: {'deleted': true}),
      _activity(item.listId, ActivityKind.removed, item.name, at),
    ]);
  }

  @override
  Future<void> reorder(String listId, List<String> orderedIds) async {
    final at = clock.next();
    await store.applyLocal([
      for (var i = 0; i < orderedIds.length; i++)
        RecordPatch.local(
          table: 'items',
          id: orderedIds[i],
          at: at,
          values: {'position': (i + 1) * 1000.0},
        ),
    ]);
  }

  @override
  Future<void> startTrip(String listId) async {
    final at = clock.next();
    await store.applyLocal([
      RecordPatch.local(table: 'lists', id: listId, at: at, values: {
        'shopper_id': userId,
        'trip_started_at': at,
      }),
      _activity(listId, ActivityKind.tripStarted, '', at),
    ]);
  }

  @override
  Future<void> finishTrip(String listId) async {
    final at = clock.next();
    final checkedItems = await (db.select(db.items)
          ..where((i) =>
              i.listId.equals(listId) & i.checked.equals(true) & i.deleted.equals(false)))
        .get();

    await store.applyLocal([
      for (final item in checkedItems)
        RecordPatch.local(table: 'items', id: item.id, at: at, values: {'deleted': true}),
      RecordPatch.local(table: 'lists', id: listId, at: at, values: {
        'shopper_id': null,
        'trip_started_at': null,
      }),
      _activity(listId, ActivityKind.tripFinished, '', at),
    ]);
  }

  @override
  Future<void> nudge(String listId, Member shopper) async {
    final at = clock.next();
    await store.applyLocal([_activity(listId, ActivityKind.nudged, shopper.firstName, at)]);
  }

  // -------------------------------------------------------------- helpers

  RecordPatch _activity(String listId, ActivityKind kind, String itemName, int at) {
    return RecordPatch.local(table: 'activities', id: _uuid.v4(), at: at, values: {
      'list_id': listId,
      'actor_id': userId,
      'kind': kind.name,
      'item_name': itemName,
      'created_at': at,
    });
  }

  Future<Map<String, Member>> _people() async {
    final rows = await db.select(db.profiles).get();
    return {
      for (final row in rows) row.id: Member(id: row.id, name: row.name, color: row.color),
    };
  }

  Member _person(Map<String, Member> people, String id) {
    return people[id] ?? Member(id: id, name: 'Someone', color: Member.unknown.color);
  }

  Future<Map<String, List<Member>>> _membersByList(Map<String, Member> people) async {
    final rows = await (db.select(db.listMembers)..where((m) => m.deleted.equals(false))).get();
    final result = <String, List<Member>>{};
    for (final row in rows) {
      result.putIfAbsent(row.listId, () => []).add(_person(people, row.userId));
    }
    // Show the signed-in person first.
    for (final members in result.values) {
      members.sort((a, b) => (a.id == userId ? 0 : 1).compareTo(b.id == userId ? 0 : 1));
    }
    return result;
  }

  ListItem _toItem(ItemRow row, Map<String, Member> people) {
    return ListItem(
      id: row.id,
      listId: row.listId,
      name: row.name,
      category: ItemCategory.fromName(row.category),
      quantity: row.quantity,
      unit: row.unit,
      price: row.price,
      checked: row.checked,
      position: row.position,
      addedBy: _person(people, row.addedBy),
      checkedBy: row.checkedBy == null ? null : _person(people, row.checkedBy!),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }
}
