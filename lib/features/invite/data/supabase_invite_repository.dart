import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/invite_preview.dart';
import '../domain/repositories/invite_repository.dart';

/// Invites through the create_invite / preview_invite / join_list functions
/// in supabase/schema.sql. They run as security definer, because the person
/// joining can't see the list yet.
class SupabaseInviteRepository implements InviteRepository {
  SupabaseInviteRepository(this.client);

  final SupabaseClient client;

  @override
  Future<String> createInvite(String listId) async {
    final code = await client.rpc<String>('create_invite', params: {'p_list_id': listId});
    return code;
  }

  @override
  Future<InvitePreview?> preview(String code) async {
    final List<dynamic> rows = await client.rpc('preview_invite', params: {'p_code': code});
    if (rows.isEmpty) return null;
    final row = rows.first as Map<String, dynamic>;
    return InvitePreview(
      code: code,
      listId: row['list_id'] as String,
      listName: row['list_name'] as String,
      inviterName: row['inviter_name'] as String,
      memberCount: row['member_count'] as int,
      itemCount: row['item_count'] as int,
      alreadyMember: row['already_member'] as bool,
    );
  }

  @override
  Future<String> join(String code) async {
    try {
      return await client.rpc<String>('join_list', params: {'p_code': code});
    } on PostgrestException {
      throw const InviteFailure('This invite link is not valid any more.');
    }
  }
}
