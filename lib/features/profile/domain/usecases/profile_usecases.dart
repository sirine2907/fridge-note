import '../../../lists/domain/entities/member.dart';
import '../repositories/profile_repository.dart';

class WatchProfile {
  WatchProfile(this._repository);

  final ProfileRepository _repository;

  Stream<Member?> call(String userId) => _repository.watchProfile(userId);
}

class UpdateProfile {
  UpdateProfile(this._repository);

  final ProfileRepository _repository;

  Future<void> call(String userId, {String? name, int? color}) {
    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isEmpty) {
      throw ArgumentError('Name can not be empty');
    }
    return _repository.updateProfile(userId, name: cleanName, color: color);
  }
}
