import '../entities/list_item.dart';
import '../repositories/lists_repository.dart';

class AddItem {
  AddItem(this._repository);

  final ListsRepository _repository;

  /// Trims the name and keeps the quantity at least 1.
  /// Throws [ArgumentError] for an empty name.
  Future<void> call(NewItem item) {
    final name = item.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('An item needs a name');
    }
    return _repository.addItem(NewItem(
      listId: item.listId,
      name: name[0].toUpperCase() + name.substring(1),
      category: item.category,
      quantity: item.quantity < 1 ? 1 : item.quantity,
      unit: item.unit,
      price: item.price < 0 ? 0 : item.price,
    ));
  }
}
