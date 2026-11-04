import '../sync/record_patch.dart';

/// The pretend household for demo mode: Sirine & Anis, two lists, 17 items.
class DemoSeed {
  DemoSeed._();

  static const sirineId = 'user-sirine';
  static const anisId = 'user-anis';
  static const yasmineId = 'user-yasmine';

  static const weeklyListId = 'list-weekly';
  static const dinnerListId = 'list-dinner';
  static const movieListId = 'list-movie';

  /// Invite code that joins Yasmine's "Movie night" list.
  static const movieInviteCode = 'MOVIE24';

  static List<RecordPatch> build({DateTime? now}) {
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    int minutesAgo(int m) => t - m * 60 * 1000;

    final patches = <RecordPatch>[
      _profile(sirineId, 'Sirine', 0xFF7360F2, minutesAgo(9000)),
      _profile(anisId, 'Anis', 0xFF2FB67C, minutesAgo(9000)),
      _profile(yasmineId, 'Yasmine', 0xFFF2994A, minutesAgo(9000)),
      _list(weeklyListId, 'Weekly groceries', 'Green Corner Market', sirineId, minutesAgo(8000),
          shopperId: anisId, tripStartedAt: minutesAgo(6)),
      _list(dinnerListId, 'Saturday dinner', 'Old town market', anisId, minutesAgo(3000)),
      _list(movieListId, 'Movie night', 'Corner shop', yasmineId, minutesAgo(2000)),
      _member(weeklyListId, sirineId, minutesAgo(8000)),
      _member(weeklyListId, anisId, minutesAgo(8000)),
      _member(dinnerListId, sirineId, minutesAgo(3000)),
      _member(dinnerListId, anisId, minutesAgo(3000)),
      _member(movieListId, yasmineId, minutesAgo(2000)),
    ];

    final weekly = [
      ('milk', 'Milk', 'dairy', 2, 'L', 1.15, sirineId, false),
      ('eggs', 'Eggs', 'dairy', 12, 'pcs', 0.28, anisId, false),
      ('bread', 'Sourdough bread', 'bakery', 1, 'pcs', 3.40, sirineId, false),
      ('bananas', 'Bananas', 'produce', 6, 'pcs', 0.30, anisId, true),
      ('tomatoes', 'Cherry tomatoes', 'produce', 1, 'pack', 2.50, sirineId, false),
      ('yogurt', 'Greek yogurt', 'dairy', 4, 'pcs', 0.95, sirineId, false),
      ('chicken', 'Chicken breast', 'meat', 1, 'kg', 8.90, anisId, false),
      ('oil', 'Olive oil', 'pantry', 1, 'bottle', 7.80, sirineId, false),
      ('coffee', 'Coffee beans', 'drinks', 1, 'pack', 9.50, anisId, true),
      ('soap', 'Dish soap', 'household', 1, 'bottle', 2.20, sirineId, false),
      ('spinach', 'Baby spinach', 'produce', 1, 'pack', 1.90, anisId, false),
      ('water', 'Sparkling water', 'drinks', 6, 'bottle', 0.60, sirineId, false),
    ];
    for (var i = 0; i < weekly.length; i++) {
      final w = weekly[i];
      patches.add(_item(
        id: 'item-${w.$1}',
        listId: weeklyListId,
        name: w.$2,
        category: w.$3,
        quantity: w.$4,
        unit: w.$5,
        price: w.$6,
        addedBy: w.$7,
        checkedBy: w.$8 ? anisId : null,
        position: (i + 1) * 1000.0,
        at: minutesAgo(w.$8 ? 3 : 300 - i * 10),
      ));
    }

    final dinner = [
      ('salmon', 'Salmon fillet', 'fish', 2, 'pcs', 6.50, anisId),
      ('lemons', 'Lemons', 'produce', 3, 'pcs', 0.45, anisId),
      ('basil', 'Fresh basil', 'produce', 1, 'pack', 1.50, sirineId),
      ('parmesan', 'Parmesan', 'dairy', 1, 'pcs', 4.80, anisId),
      ('chocolate', 'Dark chocolate', 'snacks', 2, 'pcs', 2.30, sirineId),
    ];
    for (var i = 0; i < dinner.length; i++) {
      final d = dinner[i];
      patches.add(_item(
        id: 'item-${d.$1}',
        listId: dinnerListId,
        name: d.$2,
        category: d.$3,
        quantity: d.$4,
        unit: d.$5,
        price: d.$6,
        addedBy: d.$7,
        position: (i + 1) * 1000.0,
        at: minutesAgo(1200 - i * 20),
      ));
    }

    final movie = [
      ('popcorn', 'Popcorn', 'snacks', 2, 'pack', 1.80),
      ('lemonade', 'Lemonade', 'drinks', 1, 'bottle', 2.10),
      ('nachos', 'Nachos', 'snacks', 1, 'pack', 2.60),
    ];
    for (var i = 0; i < movie.length; i++) {
      final m = movie[i];
      patches.add(_item(
        id: 'item-${m.$1}',
        listId: movieListId,
        name: m.$2,
        category: m.$3,
        quantity: m.$4,
        unit: m.$5,
        price: m.$6,
        addedBy: yasmineId,
        position: (i + 1) * 1000.0,
        at: minutesAgo(900 - i * 5),
      ));
    }

    patches.addAll([
      _activity('a1', weeklyListId, anisId, 'tripStarted', '', minutesAgo(6)),
      _activity('a2', weeklyListId, anisId, 'checked', 'Bananas', minutesAgo(4)),
      _activity('a3', weeklyListId, anisId, 'checked', 'Coffee beans', minutesAgo(3)),
      _activity('a4', dinnerListId, anisId, 'added', 'Salmon fillet', minutesAgo(1200)),
    ]);

    final usuals = [
      ('milk', 'Milk', 'dairy', 2, 'L', 1.15, 'Weekly', true, 24),
      ('eggs', 'Eggs', 'dairy', 12, 'pcs', 0.28, 'Weekly', true, 20),
      ('bread', 'Sourdough bread', 'bakery', 1, 'pcs', 3.40, 'Weekly', false, 18),
      ('bananas', 'Bananas', 'produce', 6, 'pcs', 0.30, null, true, 15),
      ('coffee', 'Coffee beans', 'drinks', 1, 'pack', 9.50, null, true, 11),
      ('yogurt', 'Greek yogurt', 'dairy', 4, 'pcs', 0.95, null, false, 9),
      ('pasta', 'Penne pasta', 'pantry', 2, 'pack', 1.20, null, false, 8),
      ('apples', 'Apples', 'produce', 6, 'pcs', 0.40, null, false, 7),
      ('soap', 'Dish soap', 'household', 1, 'bottle', 2.20, 'Monthly', false, 4),
      ('rice', 'Basmati rice', 'pantry', 1, 'kg', 2.90, 'Monthly', false, 3),
    ];
    for (final u in usuals) {
      patches.add(RecordPatch.local(table: 'usuals', id: 'usual-${u.$1}', at: minutesAgo(5000), values: {
        'owner_id': sirineId,
        'name': u.$2,
        'category': u.$3,
        'quantity': u.$4,
        'unit': u.$5,
        'price': u.$6,
        'badge': u.$7,
        'favorite': u.$8,
        'times_bought': u.$9,
        'deleted': false,
      }));
    }

    return patches;
  }

  static RecordPatch _profile(String id, String name, int color, int at) {
    return RecordPatch.local(table: 'profiles', id: id, at: at, values: {'name': name, 'color': color});
  }

  static RecordPatch _list(
    String id,
    String name,
    String store,
    String ownerId,
    int at, {
    String? shopperId,
    int? tripStartedAt,
  }) {
    return RecordPatch.local(table: 'lists', id: id, at: at, values: {
      'name': name,
      'store': store,
      'owner_id': ownerId,
      'shopper_id': shopperId,
      'trip_started_at': tripStartedAt,
      'created_at': at,
      'deleted': false,
    });
  }

  static RecordPatch _member(String listId, String userId, int at) {
    return RecordPatch.local(table: 'list_members', id: '$listId:$userId', at: at, values: {
      'list_id': listId,
      'user_id': userId,
      'deleted': false,
    });
  }

  static RecordPatch _item({
    required String id,
    required String listId,
    required String name,
    required String category,
    required int quantity,
    required String unit,
    required double price,
    required String addedBy,
    String? checkedBy,
    required double position,
    required int at,
  }) {
    return RecordPatch.local(table: 'items', id: id, at: at, values: {
      'list_id': listId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'checked': checkedBy != null,
      'checked_by': checkedBy,
      'position': position,
      'added_by': addedBy,
      'created_at': at,
      'deleted': false,
    });
  }

  static RecordPatch _activity(String id, String listId, String actorId, String kind, String itemName, int at) {
    return RecordPatch.local(table: 'activities', id: 'activity-$id', at: at, values: {
      'list_id': listId,
      'actor_id': actorId,
      'kind': kind,
      'item_name': itemName,
      'created_at': at,
    });
  }
}
