import 'dart:ui';
import 'package:flutter/material.dart';

/// Carte glassmorphism : flou d'arrière-plan + surface translucide + bord soft.
///
/// Utilisée dans le dashboard (hero stats, mini cards), l'onboarding (overlays),
/// et partout où l'on veut une carte « flottante » de qualité Apple/Stripe.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final double blur;
  final Color? tint;
  final double tintOpacity;
  final Border? border;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.blur = 18,
    this.tint,
    this.tintOpacity = 0.55,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveTint = tint ?? theme.colorScheme.surface;
    final radius = borderRadius is BorderRadius
        ? borderRadius as BorderRadius
        : const BorderRadius.all(Radius.circular(24));

    final glass = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: effectiveTint.withValues(alpha: tintOpacity),
            borderRadius: radius,
            border: border ??
                Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: isDark ? 0.06 : 0.04),
                  width: 0.8,
                ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap == null) return glass;
    return Stack(
      children: [
        glass,
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}
