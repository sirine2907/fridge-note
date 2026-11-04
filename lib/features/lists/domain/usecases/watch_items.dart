import '../entities/list_item.dart';
import '../repositories/lists_repository.dart';

class WatchItems {
  WatchItems(this._repository);

  final ListsRepository _repository;

  Stream<List<ListItem>> call(String listId) => _repository.watchItems(listId);
}
