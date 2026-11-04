import '../entities/activity.dart';
import '../entities/list_item.dart';
import '../entities/member.dart';
import '../entities/shopping_list.dart';

/// Everything the screens can do with lists and items.
///
/// Reads always come from the local database, so they work offline.
/// Writes are saved locally first and synced in the background.
abstract class ListsRepository {
  Stream<List<ShoppingList>> watchLists();

  Stream<ShoppingList?> watchList(String listId);

  Stream<List<ListItem>> watchItems(String listId);

  Stream<List<Activity>> watchActivity(String listId, {int limit = 20});

  /// Returns the id of the new list.
  Future<String> createList({required String name, required String store});

  Future<void> addItem(NewItem item);

  Future<void> setChecked(ListItem item, bool checked);

  Future<void> setQuantity(ListItem item, int quantity);

  Future<void> removeItem(ListItem item);

  /// [orderedIds] is the new order of the items, top to bottom.
  Future<void> reorder(String listId, List<String> orderedIds);

  Future<void> startTrip(String listId);

  /// Ends the trip and clears the checked items from the list.
  Future<void> finishTrip(String listId);

  Future<void> nudge(String listId, Member shopper);
}
