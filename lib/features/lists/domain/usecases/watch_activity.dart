import '../entities/activity.dart';
import '../repositories/lists_repository.dart';

class WatchActivity {
  WatchActivity(this._repository);

  final ListsRepository _repository;

  Stream<List<Activity>> call(String listId, {int limit = 20}) =>
      _repository.watchActivity(listId, limit: limit);
}
