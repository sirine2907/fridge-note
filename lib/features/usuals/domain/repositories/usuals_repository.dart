import '../entities/usual_item.dart';

abstract class UsualsRepository {
  /// Most bought first.
  Stream<List<UsualItem>> watchUsuals();

  Future<void> setFavorite(UsualItem usual, bool favorite);

  /// Counts one more purchase, so the item moves up the grid.
  Future<void> markBought(UsualItem usual);
}
