import '../entities/shopping_list.dart';
import '../repositories/lists_repository.dart';

class WatchLists {
  WatchLists(this._repository);

  final ListsRepository _repository;

  Stream<List<ShoppingList>> call() => _repository.watchLists();
}

class WatchList {
  WatchList(this._repository);

  final ListsRepository _repository;

  Stream<ShoppingList?> call(String listId) => _repository.watchList(listId);
}
