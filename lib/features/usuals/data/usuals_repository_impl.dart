import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/local_clock.dart';
import '../../../core/sync/local_store.dart';
import '../../../core/sync/record_patch.dart';
import '../../lists/domain/entities/item_category.dart';
import '../domain/entities/usual_item.dart';
import '../domain/repositories/usuals_repository.dart';

class UsualsRepositoryImpl implements UsualsRepository {
  UsualsRepositoryImpl({required this.db, required this.store, required this.clock});

  final AppDatabase db;
  final LocalStore store;
  final LocalClock clock;

  @override
  Stream<List<UsualItem>> watchUsuals() {
    final query = db.select(db.usuals)
      ..where((u) => u.deleted.equals(false))
      ..orderBy([
        (u) => OrderingTerm(expression: u.timesBought, mode: OrderingMode.desc),
        (u) => OrderingTerm(expression: u.name),
      ]);
    return query.watch().map((rows) => rows.map(_toUsual).toList());
  }

  @override
  Future<void> setFavorite(UsualItem usual, bool favorite) {
    return store.applyLocal([
      RecordPatch.local(table: 'usuals', id: usual.id, at: clock.next(), values: {'favorite': favorite}),
    ]);
  }

  @override
  Future<void> markBought(UsualItem usual) {
    return store.applyLocal([
      RecordPatch.local(
        table: 'usuals',
        id: usual.id,
        at: clock.next(),
        values: {'times_bought': usual.timesBought + 1},
      ),
    ]);
  }

  UsualItem _toUsual(UsualRow row) {
    return UsualItem(
      id: row.id,
      name: row.name,
      category: ItemCategory.fromName(row.category),
      quantity: row.quantity,
      unit: row.unit,
      price: row.price,
      favorite: row.favorite,
      timesBought: row.timesBought,
      badge: row.badge,
    );
  }
}
