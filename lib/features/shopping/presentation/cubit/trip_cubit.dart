import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/sync/sync_status.dart';
import '../../../lists/domain/entities/activity.dart';
import '../../../lists/domain/entities/list_item.dart';
import '../../../lists/domain/entities/shopping_list.dart';
import '../../../lists/domain/usecases/item_actions.dart';
import '../../../lists/domain/usecases/trip_actions.dart';
import '../../../lists/domain/usecases/watch_activity.dart';
import '../../../lists/domain/usecases/watch_items.dart';
import '../../../lists/domain/usecases/watch_lists.dart';

class TripState extends Equatable {
  const TripState({
    this.loading = true,
    this.list,
    this.items = const [],
    this.activity = const [],
    this.sync,
  });

  final bool loading;
  final ShoppingList? list;
  final List<ListItem> items;
  final List<Activity> activity;
  final SyncStatus? sync;

  TripStage get stage => list?.stage ?? TripStage.planned;

  List<ListItem> get remaining => items.where((i) => !i.checked).toList();

  /// Newest change on the list, for the "Updated 2 min ago" tile.
  DateTime? get lastUpdate {
    final times = [
      if (list != null) list!.updatedAt,
      ...items.map((i) => i.updatedAt),
      if (activity.isNotEmpty) activity.first.at,
    ];
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  TripState copyWith({
    ShoppingList? list,
    List<ListItem>? items,
    List<Activity>? activity,
    SyncStatus? sync,
  }) {
    return TripState(
      loading: false,
      list: list ?? this.list,
      items: items ?? this.items,
      activity: activity ?? this.activity,
      sync: sync ?? this.sync,
    );
  }

  @override
  List<Object?> get props => [loading, list, items, activity, sync];
}

/// The shopping trip screen: progress, who is in the shop, and live activity.
class TripCubit extends Cubit<TripState> {
  TripCubit({
    required this.listId,
    required WatchList watchList,
    required WatchItems watchItems,
    required WatchActivity watchActivity,
    required Stream<SyncStatus> Function() syncStatus,
    required StartTrip startTrip,
    required FinishTrip finishTrip,
    required NudgeShopper nudgeShopper,
    required ToggleItem toggleItem,
  })  : _startTrip = startTrip,
        _finishTrip = finishTrip,
        _nudgeShopper = nudgeShopper,
        _toggleItem = toggleItem,
        super(const TripState()) {
    _subscriptions.addAll([
      watchList(listId).listen((list) => emit(state.copyWith(list: list))),
      watchItems(listId).listen((items) => emit(state.copyWith(items: items))),
      watchActivity(listId, limit: 6).listen((activity) => emit(state.copyWith(activity: activity))),
      syncStatus().listen((status) => emit(state.copyWith(sync: status))),
    ]);
  }

  final String listId;
  final StartTrip _startTrip;
  final FinishTrip _finishTrip;
  final NudgeShopper _nudgeShopper;
  final ToggleItem _toggleItem;
  final _subscriptions = <StreamSubscription<dynamic>>[];

  Future<void> start() => _startTrip(listId);

  Future<void> finish() => _finishTrip(listId);

  Future<void> nudge() async {
    final shopper = state.list?.shopper;
    if (shopper != null) await _nudgeShopper(listId, shopper);
  }

  Future<void> toggle(ListItem item) => _toggleItem(item);

  @override
  Future<void> close() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    return super.close();
  }
}
