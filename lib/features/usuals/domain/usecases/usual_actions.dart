import '../../../lists/domain/entities/list_item.dart';
import '../../../lists/domain/repositories/lists_repository.dart';
import '../entities/usual_item.dart';
import '../repositories/usuals_repository.dart';

class WatchUsuals {
  WatchUsuals(this._repository);

  final UsualsRepository _repository;

  Stream<List<UsualItem>> call() => _repository.watchUsuals();
}

class ToggleFavorite {
  ToggleFavorite(this._repository);

  final UsualsRepository _repository;

  Future<void> call(UsualItem usual) => _repository.setFavorite(usual, !usual.favorite);
}

/// Copies a usual into a shopping list.
class AddUsualToList {
  AddUsualToList(this._usuals, this._lists);

  final UsualsRepository _usuals;
  final ListsRepository _lists;

  Future<void> call(UsualItem usual, String listId) async {
    await _lists.addItem(NewItem(
      listId: listId,
      name: usual.name,
      category: usual.category,
      quantity: usual.quantity,
      unit: usual.unit,
      price: usual.price,
    ));
    await _usuals.markBought(usual);
  }
}
