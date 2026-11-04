import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/usual_item.dart';
import '../../domain/usecases/usual_actions.dart';

enum UsualsFilter { all, hearted }

class UsualsState extends Equatable {
  const UsualsState({
    this.loading = true,
    this.usuals = const [],
    this.filter = UsualsFilter.all,
    this.justAdded = const {},
  });

  final bool loading;
  final List<UsualItem> usuals;
  final UsualsFilter filter;

  /// Ids added a moment ago, so their button can say "Added".
  final Set<String> justAdded;

  List<UsualItem> get visible =>
      filter == UsualsFilter.all ? usuals : usuals.where((u) => u.favorite).toList();

  UsualsState copyWith({
    List<UsualItem>? usuals,
    UsualsFilter? filter,
    Set<String>? justAdded,
  }) {
    return UsualsState(
      loading: false,
      usuals: usuals ?? this.usuals,
      filter: filter ?? this.filter,
      justAdded: justAdded ?? this.justAdded,
    );
  }

  @override
  List<Object?> get props => [loading, usuals, filter, justAdded];
}

class UsualsCubit extends Cubit<UsualsState> {
  UsualsCubit({
    required WatchUsuals watchUsuals,
    required ToggleFavorite toggleFavorite,
    required AddUsualToList addUsualToList,
  })  : _toggleFavorite = toggleFavorite,
        _addUsualToList = addUsualToList,
        super(const UsualsState()) {
    _subscription = watchUsuals().listen((usuals) => emit(state.copyWith(usuals: usuals)));
  }

  final ToggleFavorite _toggleFavorite;
  final AddUsualToList _addUsualToList;
  late final StreamSubscription<List<UsualItem>> _subscription;

  void setFilter(UsualsFilter filter) => emit(state.copyWith(filter: filter));

  Future<void> toggleFavorite(UsualItem usual) => _toggleFavorite(usual);

  Future<void> addToList(UsualItem usual, String listId) async {
    emit(state.copyWith(justAdded: {...state.justAdded, usual.id}));
    await _addUsualToList(usual, listId);
    // Let the "Added" label show for a moment.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!isClosed) {
      emit(state.copyWith(justAdded: {...state.justAdded}..remove(usual.id)));
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
