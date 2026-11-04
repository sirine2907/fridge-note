import '../entities/invite_preview.dart';
import '../repositories/invite_repository.dart';

class CreateInviteLink {
  CreateInviteLink(this._repository, {required this.baseUrl});

  final InviteRepository _repository;

  /// For example https://sirine2907.github.io/fridge-note/invite/
  final String baseUrl;

  Future<String> call(String listId) async {
    final code = await _repository.createInvite(listId);
    return '$baseUrl$code';
  }
}

class PreviewInvite {
  PreviewInvite(this._repository);

  final InviteRepository _repository;

  Future<InvitePreview?> call(String code) => _repository.preview(normalizeCode(code));
}

class JoinList {
  JoinList(this._repository);

  final InviteRepository _repository;

  Future<String> call(String code) => _repository.join(normalizeCode(code));
}

/// Codes are not case sensitive and people sometimes paste spaces.
String normalizeCode(String code) => code.trim().toUpperCase().replaceAll(' ', '');
