import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/invite_preview.dart';
import '../../domain/usecases/invite_usecases.dart';

// --------------------------------------------------- share sheet (sender)

class InviteLinkState extends Equatable {
  const InviteLinkState({this.link, this.error});

  final String? link;
  final String? error;

  bool get loading => link == null && error == null;

  @override
  List<Object?> get props => [link, error];
}

class InviteLinkCubit extends Cubit<InviteLinkState> {
  InviteLinkCubit(this._createLink) : super(const InviteLinkState());

  final CreateInviteLink _createLink;

  Future<void> create(String listId) async {
    try {
      emit(InviteLinkState(link: await _createLink(listId)));
    } catch (_) {
      emit(const InviteLinkState(error: 'Invites need a connection. Try again in a moment.'));
    }
  }

  /// "https://.../invite/K7Q2MX" -> "K7Q2MX"
  String? get code => state.link?.split('/').last;
}

// ------------------------------------------------------ join page (receiver)

enum JoinStatus { loading, ready, notFound, joining, joined, error }

class JoinState extends Equatable {
  const JoinState({this.status = JoinStatus.loading, this.preview, this.listId, this.error});

  final JoinStatus status;
  final InvitePreview? preview;
  final String? listId;
  final String? error;

  @override
  List<Object?> get props => [status, preview, listId, error];
}

class JoinCubit extends Cubit<JoinState> {
  JoinCubit({required PreviewInvite previewInvite, required JoinList joinList})
      : _previewInvite = previewInvite,
        _joinList = joinList,
        super(const JoinState());

  final PreviewInvite _previewInvite;
  final JoinList _joinList;

  Future<void> load(String code) async {
    try {
      final preview = await _previewInvite(code);
      emit(preview == null
          ? const JoinState(status: JoinStatus.notFound)
          : JoinState(status: JoinStatus.ready, preview: preview));
    } catch (_) {
      emit(const JoinState(status: JoinStatus.error, error: 'Could not load this invite.'));
    }
  }

  Future<void> join() async {
    final preview = state.preview;
    if (preview == null) return;
    if (preview.alreadyMember) {
      emit(JoinState(status: JoinStatus.joined, preview: preview, listId: preview.listId));
      return;
    }
    emit(JoinState(status: JoinStatus.joining, preview: preview));
    try {
      final listId = await _joinList(preview.code);
      emit(JoinState(status: JoinStatus.joined, preview: preview, listId: listId));
    } catch (error) {
      emit(JoinState(status: JoinStatus.ready, preview: preview, error: error.toString()));
    }
  }
}
