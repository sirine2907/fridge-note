import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../lists/domain/entities/member.dart';
import '../../domain/usecases/profile_usecases.dart';

/// The signed-in person's name and avatar color.
class ProfileCubit extends Cubit<Member?> {
  ProfileCubit({
    required this.userId,
    required WatchProfile watchProfile,
    required UpdateProfile updateProfile,
  })  : _updateProfile = updateProfile,
        super(null) {
    _subscription = watchProfile(userId).listen(emit);
  }

  final String userId;
  final UpdateProfile _updateProfile;
  late final StreamSubscription<Member?> _subscription;

  Future<void> rename(String name) => _updateProfile(userId, name: name);

  Future<void> setColor(int color) => _updateProfile(userId, color: color);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
