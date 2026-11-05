import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/utils/formatters.dart';
import '../../lists/domain/entities/list_item.dart';
import '../../lists/domain/entities/shopping_list.dart';
import '../../lists/domain/usecases/watch_items.dart';
import '../../lists/domain/usecases/watch_lists.dart';
import '../../lists/presentation/bloc/current_list_cubit.dart';

/// Writes the values the Android widget shows. Wraps the home_widget plugin
/// so tests can replace it.
class HomeWidgetBridge {
  /// The Kotlin class in android/app/src/main/kotlin/.../FridgeNoteWidgetProvider.kt
  static const androidName = 'FridgeNoteWidgetProvider';

  Future<void> show(Map<String, String> values) async {
    for (final entry in values.entries) {
      await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
    }
    await HomeWidget.updateWidget(androidName: androidName);
  }
}

/// Keeps the home-screen widget showing the current list.
///
/// It watches the same local database as the screens, so the widget also
/// updates when Anis checks something off on his phone.
class HomeWidgetUpdater {
  HomeWidgetUpdater({
    required this.currentList,
    required this.watchList,
    required this.watchItems,
    HomeWidgetBridge? bridge,
  }) : bridge = bridge ?? HomeWidgetBridge();

  final CurrentListCubit currentList;
  final WatchList watchList;
  final WatchItems watchItems;
  final HomeWidgetBridge bridge;

  StreamSubscription<String?>? _listIdSub;
  StreamSubscription<ShoppingList?>? _listSub;
  StreamSubscription<List<ListItem>>? _itemsSub;
  ShoppingList? _list;
  List<ListItem> _items = const [];

  /// The widget only exists on Android.
  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void start() {
    _follow(currentList.state);
    _listIdSub = currentList.stream.listen(_follow);
  }

  void _follow(String? listId) {
    _listSub?.cancel();
    _itemsSub?.cancel();
    _list = null;
    _items = const [];
    if (listId == null) return;
    _listSub = watchList(listId).listen((list) {
      _list = list;
      _push();
    });
    _itemsSub = watchItems(listId).listen((items) {
      _items = items;
      _push();
    });
  }

  void _push() {
    final list = _list;
    if (list == null) return;
    bridge.show(widgetValues(list, _items)).catchError((Object error) {
      debugPrint('Could not update the home widget: $error');
    });
  }

  /// What the widget shows, as plain strings. Kept separate so it can be tested.
  static Map<String, String> widgetValues(ShoppingList list, List<ListItem> items, {int maxLines = 6}) {
    final open = items.where((i) => !i.checked).toList();
    final lines = open.take(maxLines).map((i) => '•  ${i.name}   ${amount(i.quantity, i.unit)}').toList();
    if (open.length > maxLines) lines.add('+ ${open.length - maxLines} more');

    return {
      'list_name': list.name,
      'items_left': open.isEmpty ? 'All done' : '${open.length} left',
      'items': open.isEmpty ? 'Nothing left to buy.' : lines.join('\n'),
      'shopper': list.shopper == null ? '' : '${list.shopper!.firstName} is shopping',
    };
  }

  Future<void> dispose() async {
    await _listIdSub?.cancel();
    await _listSub?.cancel();
    await _itemsSub?.cancel();
  }
}
