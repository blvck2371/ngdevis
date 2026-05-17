import 'package:flutter/material.dart';

/// Coche de succès animée : cercle qui apparaît en elastic puis trace ✓.
/// À utiliser dans les bottom sheets après une sauvegarde, un export, etc.
class SuccessCheck extends StatefulWidget {
  final double size;
  final Color color;
  final Duration delay;

  const SuccessCheck({
    super.key,
    this.size = 72,
    this.color = const Color(0xFF22D39A),
    this.delay = Duration.zero,
  });

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _circle;
  late final Animation<double> _check;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _circle = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack));
    _check = CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _CheckPainter(
              color: widget.color,
              circleProgress: _circle.value,
              checkProgress: _check.value,
            ),
          );
        },
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final Color color;
  final double circleProgress;
  final double checkProgress;

  _CheckPainter({
    required this.color,
    required this.circleProgress,
    required this.checkProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Disque rempli (apparition elastic)
    final fillPaint = Paint()..color = color.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius * circleProgress, fillPaint);

    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius * 0.92 * circleProgress, ringPaint);

    // Trace du check
    if (checkProgress > 0) {
      final p1 = Offset(size.width * 0.30, size.height * 0.53);
      final p2 = Offset(size.width * 0.45, size.height * 0.68);
      final p3 = Offset(size.width * 0.72, size.height * 0.38);

      final t = checkProgress.clamp(0.0, 1.0);
      final firstSeg = t.clamp(0.0, 0.4) / 0.4;
      final secondSeg = ((t - 0.4) / 0.6).clamp(0.0, 1.0);

      final path = Path()..moveTo(p1.dx, p1.dy);
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * firstSeg,
        p1.dy + (p2.dy - p1.dy) * firstSeg,
      );
      if (secondSeg > 0) {
        path.lineTo(p2.dx, p2.dy);
        path.lineTo(
          p2.dx + (p3.dx - p2.dx) * secondSeg,
          p2.dy + (p3.dy - p2.dy) * secondSeg,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.08
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) =>
      old.circleProgress != circleProgress ||
      old.checkProgress != checkProgress ||
      old.color != color;
}
