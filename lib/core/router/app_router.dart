import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/auth/presentation/pages/email_sign_in_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/invite/presentation/pages/join_invite_page.dart';
import '../../features/lists/presentation/pages/home_page.dart';
import '../../features/lists/presentation/pages/list_detail_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/shopping/presentation/pages/shopping_trip_page.dart';
import '../../features/usuals/presentation/pages/usuals_page.dart';
import 'app_shell.dart';

GoRouter buildRouter(SessionCubit session, {String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: _StreamListenable(session.stream),
    redirect: (context, state) => redirectFor(session.state, state.uri),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/home'),
      GoRoute(
        path: '/welcome',
        builder: (_, state) => WelcomePage(next: state.uri.queryParameters['next']),
      ),
      GoRoute(path: '/sign-in', builder: (_, _) => const EmailSignInPage()),
      // Deep link from an invite: https://sirine2907.github.io/fridge-note/invite/CODE
      // or fridgenote://app/invite/CODE on a phone.
      GoRoute(
        path: '/invite/:code',
        builder: (_, state) => JoinInvitePage(code: state.pathParameters['code']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomePage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/list', builder: (_, _) => const ListDetailPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/trip', builder: (_, _) => const ShoppingTripPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/usuals', builder: (_, _) => const UsualsPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfilePage())]),
        ],
      ),
    ],
  );
}

/// Where to send someone, given who is signed in. Kept outside the router so
/// it can be unit tested.
String? redirectFor(SessionState session, Uri uri) {
  final path = uri.path;
  // An https invite link opened in the app keeps the GitHub Pages folder in
  // its path (/fridge-note/invite/CODE). The web build strips it itself.
  if (path.startsWith('/fridge-note/')) return path.substring('/fridge-note'.length);

  final signedIn = session.status == SessionStatus.signedIn;
  final onPublicPage = path == '/welcome' || path == '/sign-in';

  if (!signedIn) {
    if (onPublicPage) return null;
    // Remember the invite, and open it once they are signed in.
    if (path.startsWith('/invite/')) return '/welcome?next=${Uri.encodeComponent(path)}';
    return '/welcome';
  }
  if (onPublicPage) return uri.queryParameters['next'] ?? '/home';
  return null;
}

/// Lets GoRouter re-run the redirect whenever the session changes.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
