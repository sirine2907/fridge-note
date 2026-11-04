import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class StartDemo {
  StartDemo(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call() => _repository.startDemo();
}

class RestoreSession {
  RestoreSession(this._repository);

  final AuthRepository _repository;

  Future<AppUser?> call() => _repository.restore();
}

class SendEmailCode {
  SendEmailCode(this._repository);

  final AuthRepository _repository;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> call(String email) {
    final clean = email.trim().toLowerCase();
    if (!_emailPattern.hasMatch(clean)) {
      throw const AuthFailure('That email address does not look right.');
    }
    return _repository.sendEmailCode(clean);
  }
}

class VerifyEmailCode {
  VerifyEmailCode(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String code}) {
    final clean = code.replaceAll(' ', '');
    if (clean.length != 6 || int.tryParse(clean) == null) {
      throw const AuthFailure('The code has 6 digits.');
    }
    return _repository.verifyEmailCode(email: email.trim().toLowerCase(), code: clean);
  }
}

class SignOut {
  SignOut(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}
