import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// On wide screens (the web demo on a laptop) the app is shown as a phone-sized
/// white screen on the lavender page. On phones it just fills the screen.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  static const double _width = 400;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width < 600) return child;

    final c = context.colors;
    final height = math.min(860.0, media.size.height - 48);
    final size = Size(_width, height);

    return ColoredBox(
      color: c.page,
      child: Center(
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: c.screen,
            borderRadius: BorderRadius.circular(44),
            border: Border.all(color: c.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withValues(alpha: 0.12),
                blurRadius: 60,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery(
            data: media.copyWith(
              size: size,
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              viewPadding: const EdgeInsets.only(top: 12, bottom: 8),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
