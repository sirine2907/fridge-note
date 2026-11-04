import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum PillStyle { primary, soft, outline }

/// Pill-shaped button with an icon and an uppercase label.
/// The default is the full-width violet 56 px button.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = PillStyle.primary,
    this.height = 56,
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final PillStyle style;
  final double height;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final small = height < 48;
    final enabled = onPressed != null && !loading;

    Color background;
    Color foreground;
    var side = BorderSide.none;
    switch (style) {
      case PillStyle.primary:
        background = c.primary;
        foreground = Colors.white;
      case PillStyle.soft:
        background = c.primarySoft;
        foreground = c.primary;
      case PillStyle.outline:
        background = Colors.transparent;
        foreground = c.ink;
        side = BorderSide(color: c.border);
    }
    if (!enabled && !loading && style == PillStyle.primary) {
      background = background.withValues(alpha: 0.45);
    }

    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: foreground,
          fontSize: small ? 12 : 14,
          letterSpacing: small ? 0.8 : 1.4,
        );

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: foreground),
          )
        else if (icon != null)
          Icon(icon, color: foreground, size: small ? 16 : 20),
        if (loading || icon != null) SizedBox(width: small ? 6 : 10),
        Flexible(
          child: Text(
            label.toUpperCase(),
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: Material(
        color: background,
        shape: StadiumBorder(side: side),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: small ? 14 : 24),
            child: content,
          ),
        ),
      ),
    );
  }
}
