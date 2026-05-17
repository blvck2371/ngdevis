import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// État vide premium : illustration animée (cercle pulsé + icône),
/// titre, description, action optionnelle.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppColors.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulsedIcon(icon: icon, color: p.accent),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: p.inkMuted, height: 1.5),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              if (action != null) ...[
                const SizedBox(height: 24),
                action!.animate().fadeIn(duration: 400.ms, delay: 320.ms).slideY(begin: 0.2, end: 0),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _PulsedIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anneau pulsé extérieur
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.08),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 0.92, end: 1.10, duration: 1800.ms, curve: Curves.easeInOut)
              .then()
              .scaleXY(begin: 1.10, end: 0.92, duration: 1800.ms, curve: Curves.easeInOut),
          // Halo intérieur
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
          ),
          // Disque central
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.75)],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scaleXY(begin: 0.6, end: 1.0, duration: 700.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }
}
