import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/sync/sync_status.dart';
import '../../domain/entities/list_item.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/usecases/add_item.dart';
import '../../domain/usecases/item_actions.dart';
import '../../domain/usecases/watch_items.dart';
import '../../domain/usecases/watch_lists.dart';

// ---------------------------------------------------------------- events

sealed class ListDetailEvent extends Equatable {
  const ListDetailEvent();

  @override
  List<Object?> get props => [];
}

class ListDetailStarted extends ListDetailEvent {
  const ListDetailStarted(this.listId);

  final String listId;

  @override
  List<Object?> get props => [listId];
}

class ItemToggled extends ListDetailEvent {
  const ItemToggled(this.item);

  final ListItem item;

  @override
  List<Object?> get props => [item];
}

class QuantityChanged extends ListDetailEvent {
  const QuantityChanged(this.item, this.quantity);

  final ListItem item;
  final int quantity;

  @override
  List<Object?> get props => [item, quantity];
}

class ItemRemoved extends ListDetailEvent {
  const ItemRemoved(this.item);

  final ListItem item;

  @override
  List<Object?> get props => [item];
}

class ItemsReordered extends ListDetailEvent {
  const ItemsReordered(this.oldIndex, this.newIndex);

  final int oldIndex;
  final int newIndex;

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class ItemAdded extends ListDetailEvent {
  const ItemAdded(this.item);

  final NewItem item;

  @override
  List<Object?> get props => [item];
}

class _ListChanged extends ListDetailEvent {
  const _ListChanged(this.list);

  final ShoppingList? list;
}

class _ItemsChanged extends ListDetailEvent {
  const _ItemsChanged(this.items);

  final List<ListItem> items;
}

class _SyncChanged extends ListDetailEvent {
  const _SyncChanged(this.status);

  final SyncStatus status;
}

// ----------------------------------------------------------------- state

class ListDetailState extends Equatable {
  const ListDetailState({
    this.loading = true,
    this.list,
    this.items = const [],
    this.sync,
  });

  final bool loading;
  final ShoppingList? list;
  final List<ListItem> items;
  final SyncStatus? sync;

  int get leftCount => items.where((i) => !i.checked).length;

  double get estimatedTotal => items.fold(0, (sum, item) => sum + item.total);

  ListDetailState copyWith({
    bool? loading,
    ShoppingList? list,
    List<ListItem>? items,
    SyncStatus? sync,
  }) {
    return ListDetailState(
      loading: loading ?? this.loading,
      list: list ?? this.list,
      items: items ?? this.items,
      sync: sync ?? this.sync,
    );
  }

  @override
  List<Object?> get props => [loading, list, items, sync];
}

// ------------------------------------------------------------------ bloc

class ListDetailBloc extends Bloc<ListDetailEvent, ListDetailState> {
  ListDetailBloc({
    required WatchList watchList,
    required WatchItems watchItems,
    required ToggleItem toggleItem,
    required ChangeQuantity changeQuantity,
    required RemoveItem removeItem,
    required ReorderItems reorderItems,
    required AddItem addItem,
    required Stream<SyncStatus> Function() syncStatus,
  })  : _watchList = watchList,
        _watchItems = watchItems,
        _toggleItem = toggleItem,
        _changeQuantity = changeQuantity,
        _removeItem = removeItem,
        _reorderItems = reorderItems,
        _addItem = addItem,
        _syncStatus = syncStatus,
        super(const ListDetailState()) {
    on<ListDetailStarted>(_onStarted);
    on<_ListChanged>((event, emit) => emit(ListDetailState(
          loading: false,
          list: event.list,
          items: state.items,
          sync: state.sync,
        )));
    on<_ItemsChanged>((event, emit) => emit(state.copyWith(items: event.items)));
    on<_SyncChanged>((event, emit) => emit(state.copyWith(sync: event.status)));
    on<ItemToggled>((event, emit) => _toggleItem(event.item));
    on<QuantityChanged>((event, emit) => _changeQuantity(event.item, event.quantity));
    on<ItemRemoved>(_onRemoved);
    on<ItemsReordered>(_onReordered);
    on<ItemAdded>((event, emit) => _addItem(event.item));
  }

  final WatchList _watchList;
  final WatchItems _watchItems;
  final ToggleItem _toggleItem;
  final ChangeQuantity _changeQuantity;
  final RemoveItem _removeItem;
  final ReorderItems _reorderItems;
  final AddItem _addItem;
  final Stream<SyncStatus> Function() _syncStatus;

  Future<void> _onStarted(ListDetailStarted event, Emitter<ListDetailState> emit) async {
    // Three streams feed this screen. Each one turns into an internal event.
    await Future.wait([
      emit.onEach<ShoppingList?>(_watchList(event.listId), onData: (list) => add(_ListChanged(list))),
      emit.onEach<List<ListItem>>(_watchItems(event.listId), onData: (items) => add(_ItemsChanged(items))),
      emit.onEach<SyncStatus>(_syncStatus(), onData: (status) => add(_SyncChanged(status))),
    ]);
  }

  Future<void> _onRemoved(ItemRemoved event, Emitter<ListDetailState> emit) async {
    // Hide it straight away so the Dismissible doesn't jump back.
    emit(state.copyWith(items: state.items.where((i) => i.id != event.item.id).toList()));
    await _removeItem(event.item);
  }

  Future<void> _onReordered(ItemsReordered event, Emitter<ListDetailState> emit) async {
    final previous = state.items;
    // Show the new order right away; the database stream confirms it after.
    final reordered = [...previous];
    var newIndex = event.newIndex;
    if (newIndex > event.oldIndex) newIndex -= 1;
    reordered.insert(newIndex, reordered.removeAt(event.oldIndex));
    emit(state.copyWith(items: reordered));
    await _reorderItems(previous, event.oldIndex, event.newIndex);
  }
}
