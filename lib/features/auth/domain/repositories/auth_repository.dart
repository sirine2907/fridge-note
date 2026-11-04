import '../entities/app_user.dart';

abstract class AuthRepository {
  /// False when the build has no Supabase keys.
  bool get emailSignInAvailable;

  /// The user from the last session, if they are still signed in.
  Future<AppUser?> restore();

  /// Emails a 6 digit sign-in code.
  Future<void> sendEmailCode(String email);

  Future<AppUser> verifyEmailCode({required String email, required String code});

  Future<AppUser> startDemo();

  Future<void> signOut();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
