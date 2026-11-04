import 'package:equatable/equatable.dart';

import '../../../lists/domain/entities/item_category.dart';

/// Something the household buys often, ready to add with one tap.
class UsualItem extends Equatable {
  const UsualItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.favorite,
    required this.timesBought,
    this.badge,
  });

  final String id;
  final String name;
  final ItemCategory category;
  final int quantity;
  final String unit;
  final double price;
  final bool favorite;
  final int timesBought;

  /// Optional label like "Weekly".
  final String? badge;

  @override
  List<Object?> get props => [id, name, category, quantity, unit, price, favorite, timesBought, badge];
}
