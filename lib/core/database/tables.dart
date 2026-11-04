import 'package:drift/drift.dart';

// Every synced table has the same two bookkeeping columns:
//  - field_times: JSON map of column name -> time it was last changed (ms).
//    This is what makes per-field last-write-wins possible.
//  - updated_at: the newest of those times, handy for "updated 2 min ago".
//
// Nothing is ever hard deleted. Rows get deleted = true instead, so a delete
// can be synced and compared by time like any other change.

@DataClassName('ProfileRow')
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get color => integer()();
  TextColumn get fieldTimes => text().withDefault(const Constant('{}'))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ListRow')
class ShoppingLists extends Table {
  @override
  String get tableName => 'lists';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get store => text().withDefault(const Constant(''))();
  TextColumn get ownerId => text()();
  TextColumn get shopperId => text().nullable()();
  IntColumn get tripStartedAt => integer().nullable()();
  IntColumn get createdAt => integer().withDefault(const Constant(0))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  TextColumn get fieldTimes => text().withDefault(const Constant('{}'))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Who can see which list. The id is "listId:userId".
@DataClassName('MemberRow')
class ListMembers extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text()();
  TextColumn get userId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  TextColumn get fieldTimes => text().withDefault(const Constant('{}'))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ItemRow')
class Items extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text()();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant('other'))();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get price => real().withDefault(const Constant(0))();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
  TextColumn get checkedBy => text().nullable()();
  RealColumn get position => real().withDefault(const Constant(0))();
  TextColumn get addedBy => text()();
  IntColumn get createdAt => integer().withDefault(const Constant(0))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  TextColumn get fieldTimes => text().withDefault(const Constant('{}'))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ActivityRow')
class Activities extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text()();
  TextColumn get actorId => text()();
  TextColumn get kind => text()();
  TextColumn get itemName => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();
  TextColumn get fieldTimes => text().withDefault(const Constant('{}'))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UsualRow')
class Usuals extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant('other'))();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get price => real().withDefault(const Constant(0))();
  TextColumn get badge => text().nullable()();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  IntColumn get timesBought => integer().withDefault(const Constant(0))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  TextColumn get fieldTimes => text().withDefault(const Constant('{}'))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local changes that still have to be sent to the server, oldest first.
@DataClassName('OutboxRow')
class Outbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text()();
  TextColumn get rowId => text()();

  /// JSON of the changed columns.
  TextColumn get payload => text()();

  /// JSON of column -> change time.
  TextColumn get times => text()();
  IntColumn get createdAt => integer()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
}
