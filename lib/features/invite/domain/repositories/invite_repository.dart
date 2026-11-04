import '../entities/invite_preview.dart';

abstract class InviteRepository {
  /// Returns a short code like "K7Q2MX".
  Future<String> createInvite(String listId);

  /// Null when the code does not exist (or expired).
  Future<InvitePreview?> preview(String code);

  /// Adds the signed-in person to the list. Returns the list id.
  Future<String> join(String code);
}

class InviteFailure implements Exception {
  const InviteFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
