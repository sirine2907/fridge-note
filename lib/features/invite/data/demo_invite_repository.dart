import 'dart:math';

import '../../../core/demo/demo_seed.dart';
import '../../../core/demo/fake_remote.dart';
import '../../../core/sync/record_patch.dart';
import '../domain/entities/invite_preview.dart';
import '../domain/repositories/invite_repository.dart';

/// Invites for demo mode, stored in the fake server.
class DemoInviteRepository implements InviteRepository {
  DemoInviteRepository(this.remote, {Random? random}) : _random = random ?? Random() {
    remote.invites[DemoSeed.movieInviteCode] = DemoSeed.movieListId;
  }

  final FakeRemote remote;
  final Random _random;

  // No 0/O or 1/I, they are easy to mix up when typing a code.
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  @override
  Future<String> createInvite(String listId) async {
    final code = List.generate(6, (_) => _alphabet[_random.nextInt(_alphabet.length)]).join();
    remote.invites[code] = listId;
    return code;
  }

  @override
  Future<InvitePreview?> preview(String code) async {
    final listId = remote.invites[code];
    if (listId == null) return null;
    final list = remote.row('lists', listId);
    if (list == null) return null;

    final members = remote
        .rowsOf('list_members')
        .where((m) => m['list_id'] == listId && m['deleted'] != true)
        .toList();
    final items = remote
        .rowsOf('items')
        .where((i) => i['list_id'] == listId && i['deleted'] != true)
        .length;
    final owner = remote.row('profiles', list['owner_id'] as String);

    return InvitePreview(
      code: code,
      listId: listId,
      listName: list['name'] as String,
      inviterName: owner?['name'] as String? ?? 'Someone',
      memberCount: members.length,
      itemCount: items,
      alreadyMember: members.any((m) => m['user_id'] == remote.userId),
    );
  }

  @override
  Future<String> join(String code) async {
    final listId = remote.invites[code];
    if (listId == null) throw const InviteFailure('This invite link is not valid any more.');
    final at = DateTime.now().millisecondsSinceEpoch;
    final me = remote.userId;

    remote.receive(RecordPatch.local(table: 'list_members', id: '$listId:$me', at: at, values: {
      'list_id': listId,
      'user_id': me,
      'deleted': false,
    }));
    remote.receive(RecordPatch.local(table: 'activities', id: 'join-$listId-$at', at: at, values: {
      'list_id': listId,
      'actor_id': me,
      'kind': 'joined',
      'item_name': '',
      'created_at': at,
    }));
    return listId;
  }
}
