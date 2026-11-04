import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Round avatar with the first letter of the name.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({
    super.key,
    required this.name,
    required this.color,
    this.size = 32,
    this.ring = false,
  });

  final String name;
  final Color color;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final base = Theme.of(context).textTheme.labelLarge;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: ring ? Border.all(color: context.colors.card, width: 2) : null,
      ),
      child: Text(
        letter,
        style: base?.copyWith(
          color: Colors.white,
          fontSize: size * 0.42,
          letterSpacing: 0,
          height: 1,
        ),
      ),
    );
  }
}

/// A few avatars overlapping each other.
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.people, this.size = 30});

  /// Pairs of (name, color).
  final List<(String, Color)> people;
  final double size;

  @override
  Widget build(BuildContext context) {
    final shown = people.take(4).toList();
    final step = size * 0.68;
    return SizedBox(
      height: size,
      width: shown.isEmpty ? 0 : size + (shown.length - 1) * step,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: InitialAvatar(
                name: shown[i].$1,
                color: shown[i].$2,
                size: size,
                ring: true,
              ),
            ),
        ],
      ),
    );
  }
}
