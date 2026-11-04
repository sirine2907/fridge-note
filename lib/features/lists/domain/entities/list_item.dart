import 'package:equatable/equatable.dart';

import 'item_category.dart';
import 'member.dart';

class ListItem extends Equatable {
  const ListItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.checked,
    required this.position,
    required this.addedBy,
    this.checkedBy,
    required this.updatedAt,
  });

  final String id;
  final String listId;
  final String name;
  final ItemCategory category;
  final int quantity;
  final String unit;

  /// Rough price for one unit, used for the estimated total.
  final double price;
  final bool checked;

  /// Sort order inside the list. Lower comes first.
  final double position;
  final Member addedBy;
  final Member? checkedBy;
  final DateTime updatedAt;

  double get total => price * quantity;

  @override
  List<Object?> get props => [
        id,
        listId,
        name,
        category,
        quantity,
        unit,
        price,
        checked,
        position,
        addedBy,
        checkedBy,
        updatedAt,
      ];
}

/// What the user fills in when adding an item.
class NewItem extends Equatable {
  const NewItem({
    required this.listId,
    required this.name,
    this.category = ItemCategory.other,
    this.quantity = 1,
    this.unit = 'pcs',
    this.price = 0,
  });

  final String listId;
  final String name;
  final ItemCategory category;
  final int quantity;
  final String unit;
  final double price;

  @override
  List<Object?> get props => [listId, name, category, quantity, unit, price];
}
