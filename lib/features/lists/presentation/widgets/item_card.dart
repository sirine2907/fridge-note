import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar.dart';
import '../../domain/entities/list_item.dart';
import 'category_style.dart';

/// One item on a list: thumbnail, name, amount, who added it, a quantity
/// dropdown and the check circle.
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onQuantityChanged,
  });

  final ListItem item;
  final VoidCallback onToggle;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final checked = item.checked;

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onToggle,
      child: Row(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: checked ? 0.45 : 1,
            child: CategoryThumb(category: item.category),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: checked ? 0.5 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StrikeText(item.name, struck: checked, style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    item.price > 0
                        ? '${amount(item.quantity, item.unit)} · ${money(item.total)}'
                        : amount(item.quantity, item.unit),
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      InitialAvatar(
                        name: item.addedBy.name,
                        color: Color(item.addedBy.color),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          checked && item.checkedBy != null
                              ? 'Got by ${item.checkedBy!.firstName}'
                              : 'Added by ${item.addedBy.firstName}',
                          style: text.labelSmall?.copyWith(color: c.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          QuantityDropdown(value: item.quantity, onChanged: onQuantityChanged),
          const SizedBox(width: 10),
          CheckCircle(checked: checked, onTap: onToggle, label: item.name),
        ],
      ),
    );
  }
}

/// Text with a line that draws itself across when [struck] turns true.
class StrikeText extends StatelessWidget {
  const StrikeText(this.text, {super.key, required this.struck, this.style});

  final String text;
  final bool struck;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final color = style?.color ?? context.colors.ink;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: struck ? 1 : 0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return CustomPaint(
          foregroundPainter: _StrikePainter(progress: progress, color: color),
          child: child,
        );
      },
      child: Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _StrikePainter extends CustomPainter {
  _StrikePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final y = size.height * 0.55;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width * progress, y),
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter old) => old.progress != progress || old.color != color;
}

/// Round check button. Fills with violet and pops a little when checked.
class CheckCircle extends StatelessWidget {
  const CheckCircle({super.key, required this.checked, required this.onTap, required this.label});

  final bool checked;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      checked: checked,
      label: checked ? 'Uncheck $label' : 'Check off $label',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: checked ? 1 : 0.92,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? c.primary : Colors.transparent,
              border: Border.all(color: checked ? c.primary : c.border, width: 2),
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: checked ? 1 : 0,
              child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small pill that opens a 1..12 picker.
class QuantityDropdown extends StatelessWidget {
  const QuantityDropdown({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final top = value > 12 ? value : 12;

    return Container(
      height: 32,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(16),
          dropdownColor: c.card,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: c.primary),
          style: text.labelLarge?.copyWith(color: c.primary, letterSpacing: 0),
          menuMaxHeight: 320,
          items: [
            for (var i = 1; i <= top; i++) DropdownMenuItem(value: i, child: Text('$i')),
          ],
          onChanged: (picked) {
            if (picked != null) onChanged(picked);
          },
        ),
      ),
    );
  }
}
