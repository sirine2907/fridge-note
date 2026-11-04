import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/session_scope.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/auth_usecases.dart';

enum SessionStatus { unknown, signedOut, signedIn }

class SessionState extends Equatable {
  const SessionState({required this.status, this.user, this.busy = false, this.error});

  const SessionState.unknown() : this(status: SessionStatus.unknown);

  final SessionStatus status;
  final AppUser? user;
  final bool busy;
  final String? error;

  bool get isDemo => user?.isDemo ?? false;

  @override
  List<Object?> get props => [status, user, busy, error];
}

/// Knows who is signed in, and opens or closes their [SessionScope].
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required StartDemo startDemo,
    required RestoreSession restoreSession,
    required SignOut signOut,
    required SessionScope scope,
    required this.startInDemo,
  })  : _startDemo = startDemo,
        _restoreSession = restoreSession,
        _signOut = signOut,
        _scope = scope,
        super(const SessionState.unknown());

  final StartDemo _startDemo;
  final RestoreSession _restoreSession;
  final SignOut _signOut;
  final SessionScope _scope;

  /// The web build skips the welcome screen and opens the demo straight away.
  final bool startInDemo;

  Future<void> init() async {
    if (startInDemo) return startDemo();
    final user = await _restoreSession();
    if (user == null) {
      emit(const SessionState(status: SessionStatus.signedOut));
    } else {
      await signedIn(user);
    }
  }

  Future<void> startDemo() async {
    emit(SessionState(status: state.status, user: state.user, busy: true));
    final user = await _startDemo();
    await signedIn(user);
  }

  /// Called after the email code was accepted, or by [startDemo].
  Future<void> signedIn(AppUser user) async {
    try {
      await _scope.open(user);
      emit(SessionState(status: SessionStatus.signedIn, user: user));
    } catch (error) {
      debugPrint('Could not open session: $error');
      emit(const SessionState(
        status: SessionStatus.signedOut,
        error: 'Something went wrong while loading your lists.',
      ));
    }
  }

  Future<void> signOut() async {
    // Leave the screens first, then close the database they were reading from.
    emit(const SessionState(status: SessionStatus.signedOut));
    await Future<void>.delayed(closeDelay);
    await _scope.close();
    await _signOut();
  }

  /// Time for the screens of the old session to go away.
  static Duration closeDelay = const Duration(milliseconds: 400);

  /// Keeps the name and color in the state in sync with the profile screen.
  void profileChanged({required String name, required int color}) {
    final user = state.user;
    if (user == null) return;
    emit(SessionState(
      status: state.status,
      user: AppUser(id: user.id, name: name, color: color, email: user.email, isDemo: user.isDemo),
    ));
  }
}
