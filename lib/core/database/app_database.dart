import 'package:drift/drift.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Profiles, ShoppingLists, ListMembers, Items, Activities, Usuals, Outbox],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  /// The synced tables, by their SQL name. The outbox is local only.
  static const syncedTables = [
    'profiles',
    'lists',
    'list_members',
    'items',
    'activities',
    'usuals',
  ];

  TableInfo<Table, dynamic> tableByName(String name) {
    return allTables.firstWhere(
      (table) => table.actualTableName == name,
      orElse: () => throw ArgumentError('Unknown table $name'),
    );
  }

  /// Turns a JSON row (SQL column names as keys) into something drift can insert.
  Insertable<dynamic> rowFromJson(String table, Map<String, dynamic> json) {
    switch (table) {
      case 'profiles':
        return ProfileRow.fromJson(json);
      case 'lists':
        return ListRow.fromJson(json);
      case 'list_members':
        return MemberRow.fromJson(json);
      case 'items':
        return ItemRow.fromJson(json);
      case 'activities':
        return ActivityRow.fromJson(json);
      case 'usuals':
        return UsualRow.fromJson(json);
    }
    throw ArgumentError('Unknown table $table');
  }
}
