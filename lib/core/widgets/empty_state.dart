import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Illustration plus one short line of text, shown when a screen has no data.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.action, this.size = 170});

  final String message;
  final Widget? action;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FridgeIllustration(size: size),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: context.colors.muted),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A small purple fridge with a face and a sticky note, drawn in code.
class FridgeIllustration extends StatelessWidget {
  const FridgeIllustration({super.key, this.size = 170});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _FridgePainter(dark: dark)),
    );
  }
}

class _FridgePainter extends CustomPainter {
  _FridgePainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    // Everything is drawn on a 200 x 200 grid and scaled to the real size.
    final s = size.width / 200;
    canvas.save();
    canvas.scale(s);

    _shadow(canvas);
    _body(canvas);
    _note(canvas);
    _face(canvas);
    _sparkle(canvas, const Offset(38, 46), 9);
    _sparkle(canvas, const Offset(166, 84), 6);
    _sparkle(canvas, const Offset(160, 150), 8);

    canvas.restore();
  }

  void _shadow(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.violet.withValues(alpha: dark ? 0.35 : 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(104, 184), width: 124, height: 16),
      paint,
    );
  }

  void _body(Canvas canvas) {
    // Back side, shifted to the right, gives the 3D depth.
    final side = RRect.fromRectAndRadius(
      const Rect.fromLTWH(62, 30, 92, 148),
      const Radius.circular(26),
    );
    canvas.drawRRect(side, Paint()..color = const Color(0xFF4A36C4));

    // Front of the fridge.
    const frontRect = Rect.fromLTWH(50, 26, 92, 148);
    final front = RRect.fromRectAndRadius(frontRect, const Radius.circular(26));
    canvas.drawRRect(
      front,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB3A6FF), Color(0xFF7360F2), Color(0xFF5E4BE0)],
          stops: [0, 0.55, 1],
        ).createShader(frontRect),
    );

    // Gap between the two doors.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(50, 78, 92, 4), const Radius.circular(2)),
      Paint()..color = const Color(0xFF4F3CCB).withValues(alpha: 0.75),
    );

    // Handles.
    final handle = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(60, 46, 7, 22), const Radius.circular(4)),
      handle,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(60, 92, 7, 30), const Radius.circular(4)),
      handle,
    );

    // Glossy highlight on the top-left edge.
    final gloss = Path()
      ..moveTo(78, 33)
      ..quadraticBezierTo(56, 34, 55, 58)
      ..lineTo(55, 70)
      ..quadraticBezierTo(57, 44, 80, 37)
      ..close();
    canvas.drawPath(gloss, Paint()..color = Colors.white.withValues(alpha: 0.45));

    // Little feet.
    final feet = Paint()..color = const Color(0xFF3E2DAA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(64, 170, 16, 10), const Radius.circular(4)),
      feet,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(118, 170, 16, 10), const Radius.circular(4)),
      feet,
    );
  }

  void _note(Canvas canvas) {
    canvas.save();
    canvas.translate(112, 52);
    canvas.rotate(-8 * math.pi / 180);

    const rect = Rect.fromLTWH(-16, -16, 32, 32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(1.5, 2)), const Radius.circular(4)),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = AppColors.yellow,
    );
    final line = Paint()
      ..color = const Color(0xFFC9B820)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-9, -4), const Offset(9, -4), line);
    canvas.drawLine(const Offset(-9, 3), const Offset(6, 3), line);
    canvas.drawLine(const Offset(-9, 10), const Offset(2, 10), line);

    // Tape on top.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -20, 14, 7), const Radius.circular(2)),
      Paint()..color = AppColors.lilac.withValues(alpha: 0.9),
    );
    canvas.restore();
  }

  void _face(Canvas canvas) {
    final eye = Paint()..color = const Color(0xFF231A5C);
    canvas.drawOval(Rect.fromCenter(center: const Offset(88, 116), width: 9, height: 11), eye);
    canvas.drawOval(Rect.fromCenter(center: const Offset(116, 116), width: 9, height: 11), eye);

    final glint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(89.5, 113.5), 1.8, glint);
    canvas.drawCircle(const Offset(117.5, 113.5), 1.8, glint);

    final blush = Paint()..color = const Color(0xFFFF8FB8).withValues(alpha: 0.6);
    canvas.drawOval(Rect.fromCenter(center: const Offset(78, 128), width: 12, height: 7), blush);
    canvas.drawOval(Rect.fromCenter(center: const Offset(126, 128), width: 12, height: 7), blush);

    final smile = Paint()
      ..color = const Color(0xFF231A5C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(102, 124), width: 16, height: 12),
      0.15 * math.pi,
      0.7 * math.pi,
      false,
      smile,
    );
  }

  void _sparkle(Canvas canvas, Offset c, double r) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFA796FF));
  }

  @override
  bool shouldRepaint(_FridgePainter oldDelegate) => oldDelegate.dark != dark;
}
