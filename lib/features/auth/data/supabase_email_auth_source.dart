import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/repositories/auth_repository.dart';
import 'auth_repository_impl.dart';

/// Email one-time codes with Supabase Auth.
///
/// The "Magic Link" email template in the Supabase dashboard has to contain
/// {{ .Token }} so the email shows the 6 digit code (see README).
class SupabaseEmailAuthSource implements EmailAuthSource {
  SupabaseEmailAuthSource(this.client);

  final SupabaseClient client;

  @override
  (String, String)? get currentUser {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return (user.id, user.email ?? '');
  }

  @override
  Future<void> sendCode(String email) async {
    try {
      await client.auth.signInWithOtp(email: email, shouldCreateUser: true);
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    } catch (_) {
      throw const AuthFailure('Could not reach the server. Check your connection.');
    }
  }

  @override
  Future<String> verifyCode(String email, String code) async {
    try {
      final response = await client.auth.verifyOTP(type: OtpType.email, email: email, token: code);
      final user = response.user;
      if (user == null) throw const AuthFailure('That code did not work. Try again.');
      return user.id;
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<void> signOut() => client.auth.signOut();
}
