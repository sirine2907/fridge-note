import '../entities/member.dart';
import '../repositories/lists_repository.dart';

class StartTrip {
  StartTrip(this._repository);

  final ListsRepository _repository;

  Future<void> call(String listId) => _repository.startTrip(listId);
}

class FinishTrip {
  FinishTrip(this._repository);

  final ListsRepository _repository;

  Future<void> call(String listId) => _repository.finishTrip(listId);
}

class NudgeShopper {
  NudgeShopper(this._repository);

  final ListsRepository _repository;

  Future<void> call(String listId, Member shopper) => _repository.nudge(listId, shopper);
}
