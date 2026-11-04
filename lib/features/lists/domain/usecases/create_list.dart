import '../repositories/lists_repository.dart';

class CreateList {
  CreateList(this._repository);

  final ListsRepository _repository;

  /// Returns the id of the new list. Throws [ArgumentError] for an empty name.
  Future<String> call({required String name, String store = ''}) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('A list needs a name');
    }
    return _repository.createList(name: cleanName, store: store.trim());
  }
}
