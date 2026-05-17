import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Bouton CTA premium — gradient violet → indigo, ombre douce, scale au press,
/// retour haptique léger. C'est le bouton « hero » de l'onboarding et des
/// écrans de succès.
class MagneticButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool expand;
  final EdgeInsetsGeometry padding;
  final double height;
  final List<Color>? gradient;

  const MagneticButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.expand = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 26),
    this.height = 56,
    this.gradient,
  });

  @override
  State<MagneticButton> createState() => _MagneticButtonState();
}

class _MagneticButtonState extends State<MagneticButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppColors.of(context);
    final gradient = widget.gradient ?? [p.accent, p.accentDeep];
    final enabled = widget.onPressed != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: widget.height,
          width: widget.expand ? double.infinity : null,
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? gradient
                  : gradient.map((c) => c.withValues(alpha: 0.35)).toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: _down ? 0.15 : 0.32),
                      blurRadius: _down ? 12 : 22,
                      offset: Offset(0, _down ? 4 : 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
