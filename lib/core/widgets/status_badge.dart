import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Badge de statut compact et réutilisable.
///
/// Consomme un `toneCode` symbolique : `neutral` | `accent` | `success`
/// | `error` | `warning` | `gold`. La couleur réelle est résolue depuis la
/// palette du thème (dark / light) pour rester cohérent partout.
class StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final String toneCode;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.toneCode,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final color = _resolveColor(p, toneCode);
    final bg = color.withValues(alpha: 0.13);
    final border = color.withValues(alpha: 0.35);
    final hp = compact ? 7.0 : 9.0;
    final vp = compact ? 3.0 : 4.5;
    final fs = compact ? 10.0 : 11.0;
    final isz = compact ? 11.0 : 12.5;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hp, vertical: vp),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isz),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fs,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  static Color _resolveColor(AppPalette p, String tone) {
    switch (tone) {
      case 'accent':
        return p.accent;
      case 'success':
        return p.success;
      case 'error':
        return p.error;
      case 'warning':
        return p.warning;
      case 'gold':
        return p.gold;
      case 'neutral':
      default:
        return p.inkMuted;
    }
  }
}
