import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/shopping_list.dart';
import '../../domain/usecases/create_list.dart';
import '../../domain/usecases/watch_lists.dart';

// ---------------------------------------------------------------- events

sealed class ListsEvent extends Equatable {
  const ListsEvent();

  @override
  List<Object?> get props => [];
}

class ListsStarted extends ListsEvent {
  const ListsStarted();
}

class ListCreated extends ListsEvent {
  const ListCreated({required this.name, this.store = ''});

  final String name;
  final String store;

  @override
  List<Object?> get props => [name, store];
}

// ----------------------------------------------------------------- state

class ListsState extends Equatable {
  const ListsState({this.loading = true, this.lists = const [], this.createdListId});

  final bool loading;
  final List<ShoppingList> lists;

  /// Set right after a new list was created, so the page can open it.
  final String? createdListId;

  @override
  List<Object?> get props => [loading, lists, createdListId];
}

// ------------------------------------------------------------------ bloc

/// Home screen: all the lists I share.
class ListsBloc extends Bloc<ListsEvent, ListsState> {
  ListsBloc({required WatchLists watchLists, required CreateList createList})
      : _watchLists = watchLists,
        _createList = createList,
        super(const ListsState()) {
    on<ListsStarted>(_onStarted);
    on<ListCreated>(_onCreated);
  }

  final WatchLists _watchLists;
  final CreateList _createList;

  Future<void> _onStarted(ListsStarted event, Emitter<ListsState> emit) {
    return emit.forEach<List<ShoppingList>>(
      _watchLists(),
      onData: (lists) => ListsState(loading: false, lists: lists),
    );
  }

  Future<void> _onCreated(ListCreated event, Emitter<ListsState> emit) async {
    final id = await _createList(name: event.name, store: event.store);
    emit(ListsState(loading: false, lists: state.lists, createdListId: id));
  }
}
