import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'round_back_button.dart';

/// Back button on the left, title in the middle, optional action on the right.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.action,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          RoundBackButton(onPressed: onBack),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: text.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(width: 44, height: 44, child: action),
        ],
      ),
    );
  }
}

/// Small grey caption above a group, e.g. "LIVE ACTIVITY".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Thin progress bar that slides smoothly to a new value.
class SmoothProgressBar extends StatelessWidget {
  const SmoothProgressBar({super.key, required this.value, this.height = 8});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: c.primarySoft,
            borderRadius: BorderRadius.circular(height),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: animated,
            child: Container(
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        );
      },
    );
  }
}
