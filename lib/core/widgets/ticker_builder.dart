import 'dart:async';

import 'package:flutter/material.dart';

/// Rebuilds every [every], so "2 min ago" labels stay correct.
class TickerBuilder extends StatefulWidget {
  const TickerBuilder({super.key, required this.builder, this.every = const Duration(seconds: 30)});

  final WidgetBuilder builder;
  final Duration every;

  @override
  State<TickerBuilder> createState() => _TickerBuilderState();
}

class _TickerBuilderState extends State<TickerBuilder> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.every, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// Fades and slides its child in the first time it is built.
/// New rows in a list get it, old rows don't animate again.
class AppearIn extends StatelessWidget {
  const AppearIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
      ),
      child: child,
    );
  }
}
