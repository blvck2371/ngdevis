import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../utils/app_routes.dart';

/// Navigation racine de l'application : 4 onglets + 1 bouton central
/// "Créer un devis" toujours visible.
enum AppTab { home, devis, catalog, settings }

/// Barre de navigation persistante.
///
/// **Surface solide** (pas de BackdropFilter) : sur Android avec un contenu
/// animé derrière (mesh gradient, etc.), un blur permanent provoque des ANR.
/// On reste premium grâce à l'opacité haute et une ombre douce.
class AppBottomNav extends StatelessWidget {
  final AppTab active;

  const AppBottomNav({super.key, required this.active});

  void _go(String route) {
    if (Get.currentRoute == route) return;
    HapticFeedback.selectionClick();
    // offAllNamed -> pile remise à zéro à chaque switch (plus d'accumulation).
    Get.offAllNamed(route);
  }

  void _create(BuildContext context) {
    HapticFeedback.mediumImpact();
    _NewDocumentSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 6, 14, 10 + bottomInset),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF111219).withValues(alpha: 0.96)
              : Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: p.outlineSoft, width: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Accueil',
                active: active == AppTab.home,
                onTap: () => _go(AppRoutes.dashboard),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Documents',
                active: active == AppTab.devis,
                onTap: () => _go(AppRoutes.history),
              ),
            ),
            _CenterCreateButton(onTap: () => _create(context)),
            Expanded(
              child: _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Catalogue',
                active: active == AppTab.catalog,
                onTap: () => _go(AppRoutes.designations),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.tune_rounded,
                label: 'Réglages',
                active: active == AppTab.settings,
                onTap: () => _go(AppRoutes.settings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final color = active ? p.accent : p.inkMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dot indicateur d'actif
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? p.accent : Colors.transparent,
                  boxShadow: active
                      ? [BoxShadow(color: p.accent.withValues(alpha: 0.55), blurRadius: 8)]
                      : null,
                ),
              ),
              AnimatedScale(
                scale: active ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterCreateButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CenterCreateButton({required this.onTap});

  @override
  State<_CenterCreateButton> createState() => _CenterCreateButtonState();
}

class _CenterCreateButtonState extends State<_CenterCreateButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: AnimatedScale(
          scale: _down ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.accent, p.accentDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: p.accent.withValues(alpha: _down ? 0.25 : 0.45),
                  blurRadius: _down ? 14 : 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BOTTOM SHEET — "Nouveau document"
// ============================================================================

/// Feuille de choix qui s'ouvre depuis le bouton "+" central.
/// Propose explicitement Devis ou Facture (clarifie l'intention de l'utilisateur).
class _NewDocumentSheet extends StatelessWidget {
  const _NewDocumentSheet();

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _NewDocumentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Text(
            'Que voulez-vous créer ?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choisissez le type de document que vous voulez préparer maintenant.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: 18),
          _DocChoiceCard(
            icon: Icons.description_rounded,
            title: 'Nouveau devis',
            subtitle: 'Proposer un prix avant travaux. Conversion en facture en 1 clic après acceptation.',
            tint: p.accent,
            primary: true,
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              Get.toNamed(
                AppRoutes.chooseCategory,
                arguments: {'asInvoice': false},
              );
            },
          ),
          const SizedBox(height: 10),
          _DocChoiceCard(
            icon: Icons.receipt_long_rounded,
            title: 'Nouvelle facture',
            subtitle: 'Facturer directement (vente, prestation déjà réalisée). Échéance + suivi paiement intégrés.',
            tint: p.gold,
            primary: false,
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              Get.toNamed(
                AppRoutes.chooseCategory,
                arguments: {'asInvoice': true},
              );
            },
          ),
          const SizedBox(height: 14),
          // Bouton secondaire : conversion d'un devis existant.
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.selectionClick();
                Get.offAllNamed(AppRoutes.history);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: p.surfaceLow,
                  border: Border.all(color: p.outlineSoft, width: 0.6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: p.inkMuted, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Convertir un devis existant',
                        style: TextStyle(color: p.ink, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.inkMuted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final bool primary;
  final VoidCallback onTap;

  const _DocChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: primary
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tint.withValues(alpha: 0.16),
                      tint.withValues(alpha: 0.04),
                    ],
                  )
                : null,
            color: primary ? null : p.surface,
            border: Border.all(
              color: tint.withValues(alpha: primary ? 0.42 : 0.22),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: tint, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: p.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: p.inkMuted, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
