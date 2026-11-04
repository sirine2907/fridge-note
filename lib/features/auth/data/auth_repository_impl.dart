import '../../../core/demo/demo_seed.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/auth_repository.dart';

/// The part of auth that needs a real server. Supabase implements it.
abstract class EmailAuthSource {
  /// (id, email) of the stored session, or null.
  (String, String)? get currentUser;

  Future<void> sendCode(String email);

  /// Returns the user id.
  Future<String> verifyCode(String email, String code);

  Future<void> signOut();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({this.email});

  /// Null when the build has no Supabase keys.
  final EmailAuthSource? email;

  @override
  bool get emailSignInAvailable => email != null;

  @override
  Future<AppUser?> restore() async {
    final current = email?.currentUser;
    if (current == null) return null;
    return _userFor(current.$1, current.$2);
  }

  @override
  Future<void> sendEmailCode(String address) async {
    final source = _requireEmail();
    await source.sendCode(address);
  }

  @override
  Future<AppUser> verifyEmailCode({required String email, required String code}) async {
    final source = _requireEmail();
    final id = await source.verifyCode(email, code);
    return _userFor(id, email);
  }

  @override
  Future<AppUser> startDemo() async {
    return const AppUser(
      id: DemoSeed.sirineId,
      name: 'Sirine',
      color: 0xFF7360F2,
      email: 'sirine@demo.fridge-note',
      isDemo: true,
    );
  }

  @override
  Future<void> signOut() async {
    await email?.signOut();
  }

  EmailAuthSource _requireEmail() {
    final source = email;
    if (source == null) {
      throw const AuthFailure('Email sign-in is not set up in this build. Try the demo!');
    }
    return source;
  }

  AppUser _userFor(String id, String address) {
    // The real name and color live in the profile row and can be changed later.
    final name = address.split('@').first;
    return AppUser(
      id: id,
      name: name.isEmpty ? 'Me' : name[0].toUpperCase() + name.substring(1),
      color: AppColors.avatarChoices.first.toARGB32(),
      email: address,
    );
  }
}
