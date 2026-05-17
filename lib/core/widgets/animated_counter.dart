import 'package:flutter/material.dart';

/// Compteur animé : interpole entre la valeur précédente et la nouvelle valeur
/// avec une courbe ease-out (parfait pour les chiffres premium du dashboard).
class AnimatedCounter extends StatelessWidget {
  final double value;
  final Duration duration;
  final Curve curve;
  final String Function(double) formatter;
  final TextStyle? style;
  final TextAlign? textAlign;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.formatter,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, v, _) {
        return Text(
          formatter(v),
          style: style,
          textAlign: textAlign,
        );
      },
    );
  }
}
