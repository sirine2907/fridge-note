import '../entities/list_item.dart';
import '../repositories/lists_repository.dart';

class ToggleItem {
  ToggleItem(this._repository);

  final ListsRepository _repository;

  Future<void> call(ListItem item) => _repository.setChecked(item, !item.checked);
}

class ChangeQuantity {
  ChangeQuantity(this._repository);

  final ListsRepository _repository;

  static const max = 99;

  /// Ignores the change when nothing would change, and clamps to 1..99.
  Future<void> call(ListItem item, int quantity) async {
    final value = quantity.clamp(1, max);
    if (value == item.quantity) return;
    await _repository.setQuantity(item, value);
  }
}

class RemoveItem {
  RemoveItem(this._repository);

  final ListsRepository _repository;

  Future<void> call(ListItem item) => _repository.removeItem(item);
}

class ReorderItems {
  ReorderItems(this._repository);

  final ListsRepository _repository;

  /// Moves the item at [oldIndex] to [newIndex], like ReorderableListView reports it.
  Future<List<ListItem>> call(List<ListItem> items, int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return items;
    final reordered = [...items];
    // ReorderableListView counts the new index as if the item was still in place.
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    if (items.isEmpty) return reordered;
    await _repository.reorder(items.first.listId, reordered.map((i) => i.id).toList());
    return reordered;
  }
}
