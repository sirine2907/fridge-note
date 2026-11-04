import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/page_header.dart';
import '../../domain/entities/shopping_list.dart';

/// A shared list on the home screen.
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.list, required this.onTap, this.tint});

  final ShoppingList list;
  final VoidCallback onTap;

  /// Background of the icon tile, so cards next to each other differ.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final done = list.stage == TripStage.done;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PastelTile(
                color: tint ?? c.lilac,
                size: 52,
                radius: 18,
                child: Icon(
                  done ? Icons.celebration_rounded : Icons.shopping_basket_rounded,
                  color: c.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(list.name, style: text.titleLarge?.copyWith(fontSize: 18)),
                    if (list.store.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.storefront_rounded, size: 14, color: c.muted),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                list.store,
                                style: text.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.muted),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AvatarStack(
                people: [for (final m in list.members) (m.name, Color(m.color))],
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  list.itemCount == 0
                      ? 'No items yet'
                      : '${plural(list.itemCount, 'item')} · ${list.leftCount} left',
                  style: text.bodyMedium?.copyWith(color: c.muted),
                ),
              ),
              if (list.shopper != null && !done) _ShoppingNow(name: list.shopper!.firstName),
            ],
          ),
          const SizedBox(height: 14),
          SmoothProgressBar(value: list.progress),
        ],
      ),
    );
  }
}

class _ShoppingNow extends StatelessWidget {
  const _ShoppingNow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$name is shopping',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.ink),
      ),
    );
  }
}
