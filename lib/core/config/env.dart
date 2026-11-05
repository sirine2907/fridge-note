import 'package:flutter/foundation.dart';

/// Build settings passed with --dart-define (see .env.example).
class Env {
  Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  /// The publishable key (sb_publishable_...). A legacy anon key works too.
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Force demo mode on start. The web build always starts in demo mode.
  static const _demo = bool.fromEnvironment('DEMO');

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  static bool get startInDemo => _demo || kIsWeb;

  /// Base of the links we put in invites.
  static const inviteBaseUrl = 'https://sirine2907.github.io/fridge-note/invite/';
}
