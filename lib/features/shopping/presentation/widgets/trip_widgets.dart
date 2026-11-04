import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/ticker_builder.dart';
import '../../../lists/domain/entities/activity.dart';
import '../../../lists/domain/entities/shopping_list.dart';

/// Planned -> Shopping -> Done, with check circles joined by lines.
class TripStepper extends StatelessWidget {
  const TripStepper({super.key, required this.stage});

  final TripStage stage;

  static const _steps = [
    ('Planned', Icons.receipt_long_rounded),
    ('Shopping', Icons.shopping_cart_rounded),
    ('Done', Icons.celebration_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final current = stage.index;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          _Step(
            label: _steps[i].$1,
            icon: _steps[i].$2,
            done: i < current || stage == TripStage.done,
            active: i == current,
          ),
          if (i < _steps.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 21),
                child: _Line(filled: i < current),
              ),
            ),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.icon, required this.done, required this.active});

  final String label;
  final IconData icon;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    Color fill;
    Color border;
    Widget child;
    if (done) {
      fill = c.primary;
      border = c.primary;
      child = const Icon(Icons.check_rounded, color: Colors.white, size: 22);
    } else if (active) {
      fill = c.primarySoft;
      border = c.primary;
      child = Icon(icon, color: c.primary, size: 20);
    } else {
      fill = Colors.transparent;
      border = c.border;
      child = Icon(icon, color: c.muted, size: 20);
    }

    return SizedBox(
      width: 72,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: border, width: 2),
            ),
            child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: child),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: text.labelMedium?.copyWith(color: done || active ? c.ink : c.muted),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 3,
      decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
      alignment: Alignment.centerLeft,
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        widthFactor: filled ? 1 : 0,
        child: Container(
          decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
  }
}

/// One of the three pastel tiles: items left, store, last update.
class StatusTile extends StatelessWidget {
  const StatusTile({
    super.key,
    required this.color,
    required this.icon,
    required this.value,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      height: 128,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: c.card, shape: BoxShape.circle),
            child: Icon(icon, size: 17, color: c.ink),
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              value,
              key: ValueKey(value),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.15),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: text.bodySmall?.copyWith(color: c.ink.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

/// "Anis checked off Milk · 1 min ago"
class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.activity, this.highlight = false});

  final Activity activity;
  final bool highlight;

  IconData get _icon {
    switch (activity.kind) {
      case ActivityKind.checked:
        return Icons.check_circle_rounded;
      case ActivityKind.unchecked:
        return Icons.undo_rounded;
      case ActivityKind.added:
        return Icons.add_circle_rounded;
      case ActivityKind.removed:
        return Icons.remove_circle_rounded;
      case ActivityKind.quantity:
        return Icons.tune_rounded;
      case ActivityKind.tripStarted:
        return Icons.shopping_cart_rounded;
      case ActivityKind.tripFinished:
        return Icons.celebration_rounded;
      case ActivityKind.joined:
        return Icons.group_add_rounded;
      case ActivityKind.nudged:
        return Icons.waving_hand_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final actor = activity.actor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? c.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: highlight ? Colors.transparent : c.border),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              InitialAvatar(name: actor.name, color: Color(actor.color), size: 36),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: c.card, shape: BoxShape.circle),
                  child: Icon(_icon, size: 14, color: c.primary),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(activity.sentence, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
          const SizedBox(width: 8),
          TickerBuilder(builder: (_) => Text(timeAgo(activity.at), style: text.bodySmall)),
        ],
      ),
    );
  }
}

/// Little blinking dot next to "Live activity".
class LiveDot extends StatefulWidget {
  const LiveDot({super.key});

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.3, end: 1.0).animate(_controller),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        Text('LIVE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.red, letterSpacing: 1)),
      ],
    );
  }
}
