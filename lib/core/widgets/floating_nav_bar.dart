import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NavBarItem {
  const NavBarItem({required this.icon, required this.label, this.badge = 0});

  final IconData icon;
  final String label;

  /// Small red count bubble. Hidden when 0.
  final int badge;
}

/// Floating pill-shaped bottom bar. The active icon sits in a light violet circle.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavButton(
                  item: items[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active, required this.onTap});

  final NavBarItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: item.label,
      child: Semantics(
        button: true,
        selected: active,
        label: item.label,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: active ? 50 : 0,
                  height: active ? 50 : 0,
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(item.icon, size: 24, color: active ? c.primary : c.muted),
                if (item.badge > 0)
                  Positioned(
                    top: 6,
                    right: 4,
                    child: _CountBadge(count: item.badge),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Container(
        key: ValueKey(count),
        constraints: const BoxConstraints(minWidth: 18),
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: context.colors.card, width: 1.5),
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontSize: 10,
                height: 1,
              ),
        ),
      ),
    );
  }
}
