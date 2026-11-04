import 'dart:async';
import 'dart:math';

import '../sync/record_patch.dart';
import 'demo_seed.dart';
import 'fake_remote.dart';

/// Pretends to be Anis, walking through the shop with the other phone.
///
/// Every few seconds he does one thing on the weekly list: checks off an
/// item, adds something he remembered, or changes a quantity. The changes go
/// into the fake server, so they reach this phone through the normal sync path.
class DemoPartner {
  DemoPartner(
    this.remote, {
    this.every = const Duration(seconds: 5),
    Random? random,
  }) : _random = random ?? Random();

  final FakeRemote remote;
  final Duration every;
  final Random _random;
  Timer? _timer;
  int _counter = 0;

  static const listId = DemoSeed.weeklyListId;
  static const anisId = DemoSeed.anisId;

  static const _ideas = [
    ('Avocados', 'produce', 2, 'pcs', 1.20),
    ('Oat milk', 'dairy', 1, 'L', 2.10),
    ('Garlic', 'produce', 1, 'pcs', 0.50),
    ('Butter', 'dairy', 1, 'pcs', 2.40),
    ('Honey', 'pantry', 1, 'pcs', 5.90),
    ('Paper towels', 'household', 1, 'pack', 3.10),
    ('Orange juice', 'drinks', 1, 'L', 2.70),
    ('Mozzarella', 'dairy', 2, 'pcs', 1.30),
    ('Granola', 'pantry', 1, 'pack', 4.20),
    ('Cucumber', 'produce', 2, 'pcs', 0.60),
  ];

  bool get isRunning => _timer != null;

  void start() {
    _timer ??= Timer.periodic(every, (_) => tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// One move. Public so tests can call it without waiting.
  void tick() {
    final items = remote
        .rowsOf('items')
        .where((i) => i['list_id'] == listId && i['deleted'] != true)
        .toList()
      ..sort((a, b) => (a['position'] as num).compareTo(b['position'] as num));
    final open = items.where((i) => i['checked'] != true).toList();

    final roll = _random.nextDouble();
    if (open.length <= 2 || roll > 0.85) {
      _addSomething(items);
    } else if (roll > 0.72) {
      _changeQuantity(open[_random.nextInt(open.length)]);
    } else {
      // Mostly walks the list from the top, like a real shopper.
      final pick = _random.nextDouble() < 0.7 ? open.first : open[_random.nextInt(open.length)];
      _checkOff(pick);
    }
  }

  void _checkOff(Map<String, Object?> item) {
    final at = _now();
    remote.receive(RecordPatch.local(table: 'items', id: item['id'] as String, at: at, values: {
      'checked': true,
      'checked_by': anisId,
    }));
    _log('checked', item['name'] as String, at);
  }

  void _changeQuantity(Map<String, Object?> item) {
    final at = _now();
    final quantity = (item['quantity'] as int) + 1;
    remote.receive(RecordPatch.local(
      table: 'items',
      id: item['id'] as String,
      at: at,
      values: {'quantity': quantity},
    ));
    _log('quantity', '${item['name']} to $quantity ${item['unit']}', at);
  }

  void _addSomething(List<Map<String, Object?>> items) {
    final names = items.map((i) => i['name']).toSet();
    final options = _ideas.where((idea) => !names.contains(idea.$1)).toList();
    if (options.isEmpty) return;
    final idea = options[_random.nextInt(options.length)];
    final at = _now();
    final lastPosition = items.isEmpty
        ? 0.0
        : items.map((i) => (i['position'] as num).toDouble()).reduce(max);

    remote.receive(RecordPatch.local(table: 'items', id: 'demo-${at}_${_counter++}', at: at, values: {
      'list_id': listId,
      'name': idea.$1,
      'category': idea.$2,
      'quantity': idea.$3,
      'unit': idea.$4,
      'price': idea.$5,
      'checked': false,
      'checked_by': null,
      'position': lastPosition + 1000,
      'added_by': anisId,
      'created_at': at,
      'deleted': false,
    }));
    _log('added', idea.$1, at);
  }

  void _log(String kind, String itemName, int at) {
    remote.receive(RecordPatch.local(table: 'activities', id: 'demo-activity-${at}_${_counter++}', at: at, values: {
      'list_id': listId,
      'actor_id': anisId,
      'kind': kind,
      'item_name': itemName,
      'created_at': at,
    }));
  }

  int _now() => DateTime.now().millisecondsSinceEpoch;

  void dispose() => stop();
}
