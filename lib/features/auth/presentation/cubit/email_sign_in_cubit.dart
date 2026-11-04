import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/usecases/auth_usecases.dart';

enum EmailStep { enterEmail, enterCode }

class EmailSignInState extends Equatable {
  const EmailSignInState({
    this.step = EmailStep.enterEmail,
    this.email = '',
    this.busy = false,
    this.error,
    this.user,
  });

  final EmailStep step;
  final String email;
  final bool busy;
  final String? error;

  /// Set once the code was accepted.
  final AppUser? user;

  @override
  List<Object?> get props => [step, email, busy, error, user];
}

class EmailSignInCubit extends Cubit<EmailSignInState> {
  EmailSignInCubit({required SendEmailCode sendCode, required VerifyEmailCode verifyCode})
      : _sendCode = sendCode,
        _verifyCode = verifyCode,
        super(const EmailSignInState());

  final SendEmailCode _sendCode;
  final VerifyEmailCode _verifyCode;

  Future<void> sendCode(String email) async {
    emit(EmailSignInState(email: email, busy: true));
    try {
      await _sendCode(email);
      emit(EmailSignInState(step: EmailStep.enterCode, email: email.trim().toLowerCase()));
    } catch (error) {
      emit(EmailSignInState(email: email, error: error.toString()));
    }
  }

  Future<void> verify(String code) async {
    emit(EmailSignInState(step: EmailStep.enterCode, email: state.email, busy: true));
    try {
      final user = await _verifyCode(email: state.email, code: code);
      emit(EmailSignInState(step: EmailStep.enterCode, email: state.email, user: user));
    } catch (error) {
      emit(EmailSignInState(step: EmailStep.enterCode, email: state.email, error: error.toString()));
    }
  }

  void changeEmail() => emit(EmailSignInState(email: state.email));
}
