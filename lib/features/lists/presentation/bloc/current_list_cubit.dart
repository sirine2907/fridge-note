import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/shopping_list.dart';
import '../../domain/usecases/watch_lists.dart';

/// Which list the "list", "trip" and "usuals" tabs work on.
/// Falls back to the first list when nothing was picked yet.
class CurrentListCubit extends Cubit<String?> {
  CurrentListCubit(WatchLists watchLists) : super(null) {
    _subscription = watchLists().listen(_onLists);
  }

  late final StreamSubscription<List<ShoppingList>> _subscription;
  List<ShoppingList> _lists = const [];

  void select(String listId) => emit(listId);

  void _onLists(List<ShoppingList> lists) {
    _lists = lists;
    final stillThere = lists.any((list) => list.id == state);
    if (!stillThere) emit(lists.isEmpty ? null : lists.first.id);
  }

  ShoppingList? get current {
    for (final list in _lists) {
      if (list.id == state) return list;
    }
    return null;
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
