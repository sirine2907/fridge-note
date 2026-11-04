import 'package:equatable/equatable.dart';

/// What someone sees before joining a list from an invite link.
class InvitePreview extends Equatable {
  const InvitePreview({
    required this.code,
    required this.listId,
    required this.listName,
    required this.inviterName,
    required this.memberCount,
    required this.itemCount,
    this.alreadyMember = false,
  });

  final String code;
  final String listId;
  final String listName;
  final String inviterName;
  final int memberCount;
  final int itemCount;
  final bool alreadyMember;

  @override
  List<Object?> get props =>
      [code, listId, listName, inviterName, memberCount, itemCount, alreadyMember];
}
