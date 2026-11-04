import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/item_category.dart';

/// Icon and pastel colors for each category.
class CategoryStyle {
  const CategoryStyle(this.icon, this.tile, this.ink);

  final IconData icon;
  final Color tile;
  final Color ink;

  static CategoryStyle of(BuildContext context, ItemCategory category) {
    final c = context.colors;
    const green = Color(0xFF2FA36B);
    const blue = Color(0xFF3B82D6);
    const orange = Color(0xFFE07A4F);
    final violet = c.primary;

    switch (category) {
      case ItemCategory.produce:
        return CategoryStyle(Icons.eco_rounded, c.mint, green);
      case ItemCategory.dairy:
        return CategoryStyle(Icons.egg_alt_rounded, c.sky, blue);
      case ItemCategory.bakery:
        return CategoryStyle(Icons.bakery_dining_rounded, c.peach, orange);
      case ItemCategory.meat:
        return CategoryStyle(Icons.kebab_dining_rounded, c.peach, orange);
      case ItemCategory.fish:
        return CategoryStyle(Icons.set_meal_rounded, c.sky, blue);
      case ItemCategory.drinks:
        return CategoryStyle(Icons.local_drink_rounded, c.sky, blue);
      case ItemCategory.frozen:
        return CategoryStyle(Icons.ac_unit_rounded, c.sky, blue);
      case ItemCategory.pantry:
        return CategoryStyle(Icons.rice_bowl_rounded, c.lilac, violet);
      case ItemCategory.snacks:
        return CategoryStyle(Icons.cookie_rounded, c.lilac, violet);
      case ItemCategory.household:
        return CategoryStyle(Icons.cleaning_services_rounded, c.mint, green);
      case ItemCategory.other:
        return CategoryStyle(Icons.shopping_basket_rounded, c.lilac, violet);
    }
  }
}

/// The pastel square with the category icon.
class CategoryThumb extends StatelessWidget {
  const CategoryThumb({super.key, required this.category, this.size = 56});

  final ItemCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(context, category);
    return PastelTile(
      color: style.tile,
      size: size,
      radius: size * 0.36,
      child: Icon(style.icon, color: style.ink, size: size * 0.46),
    );
  }
}
