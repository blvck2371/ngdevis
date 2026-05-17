import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fond d'écran premium animé — trois « blobs » de couleurs (gradient mesh)
/// qui flottent doucement sur un fond sombre/clair. Sert d'arrière-plan
/// pour le splash, l'onboarding et le hero du dashboard.
///
/// Très léger : un seul [AnimationController] qui s'autoreverse, pas de Lottie,
/// pas d'image, pas de blur — juste des [RadialGradient] additionnés.
class MeshGradientBackground extends StatefulWidget {
  /// Intensité (0..1) — opacité globale des blobs. 0.55 par défaut (subtil).
  final double intensity;
  final Widget? child;

  const MeshGradientBackground({
    super.key,
    this.intensity = 0.55,
    this.child,
  });

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context).meshBlobs;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          painter: _MeshPainter(
            t: _ctrl.value,
            blobs: colors,
            background: bg,
            intensity: widget.intensity,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double t;
  final List<Color> blobs;
  final Color background;
  final double intensity;

  _MeshPainter({
    required this.t,
    required this.blobs,
    required this.background,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fond uni d'abord.
    final bgPaint = Paint()..color = background;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final tau = math.pi * 2;
    final positions = [
      Offset(
        size.width * (0.18 + 0.10 * math.sin(t * tau)),
        size.height * (0.22 + 0.08 * math.cos(t * tau * 0.9)),
      ),
      Offset(
        size.width * (0.82 + 0.08 * math.sin(t * tau * 1.3 + 1.7)),
        size.height * (0.30 + 0.10 * math.cos(t * tau * 1.1 + 0.9)),
      ),
      Offset(
        size.width * (0.50 + 0.12 * math.sin(t * tau * 0.7 + 2.4)),
        size.height * (0.82 + 0.05 * math.cos(t * tau * 0.6 + 3.1)),
      ),
    ];

    final radius = math.max(size.width, size.height) * 0.85;
    for (var i = 0; i < blobs.length && i < positions.length; i++) {
      final paint = Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            blobs[i].withValues(alpha: intensity * 0.65),
            blobs[i].withValues(alpha: 0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: positions[i], radius: radius));
      canvas.drawCircle(positions[i], radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) =>
      old.t != t || old.intensity != intensity || old.background != background;
}
