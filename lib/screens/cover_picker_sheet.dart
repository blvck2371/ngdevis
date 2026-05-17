import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/database/hive_storage.dart';
import '../core/services/cover/cover_template.dart';
import '../core/theme/app_theme.dart';

/// Feuille de sélection du **modèle de couverture** pour le PDF.
///
/// L'utilisateur voit un carousel des templates disponibles, peut en
/// "feuilleter" avec un large aperçu A4. Une fois choisi, le template est :
///   1. retourné à l'appelant via `showPicker`,
///   2. persisté pour pré-sélection la prochaine fois.
class CoverPickerSheet extends StatefulWidget {
  final CoverTemplate initial;
  final String title;
  final String confirmLabel;

  const CoverPickerSheet({
    super.key,
    required this.initial,
    this.title = 'Choisissez un modèle',
    this.confirmLabel = 'Générer le PDF',
  });

  /// Affiche le picker. Retourne le `CoverTemplate` choisi, ou `null` si
  /// l'utilisateur a annulé.
  static Future<CoverTemplate?> show(
    BuildContext context, {
    CoverTemplate? initial,
    String? title,
    String? confirmLabel,
  }) {
    final start = initial ?? loadLastTemplate();
    return showModalBottomSheet<CoverTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      useSafeArea: true,
      // Pas de DraggableScrollableSheet ici : il récupère les gestes verticaux et
      // entre en conflit avec le swipe horizontal du PageView (freeze / jumps).
      builder: (ctx) {
        final h = MediaQuery.sizeOf(ctx).height;
        return Padding(
          padding: EdgeInsets.only(top: h * 0.04),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: h * 0.88,
              child: CoverPickerSheet(
                initial: start,
                title: title ?? 'Choisissez un modèle',
                confirmLabel: confirmLabel ?? 'Générer le PDF',
              ),
            ),
          ),
        );
      },
    );
  }

  /// Lit le dernier template choisi par l'utilisateur (Hive).
  static CoverTemplate loadLastTemplate() {
    return coverTemplateFromId(HiveStorage.getCoverTemplateId());
  }

  /// Persiste le template choisi (pour pré-sélection).
  static Future<void> saveLastTemplate(CoverTemplate t) =>
      HiveStorage.setCoverTemplateId(t.name);

  @override
  State<CoverPickerSheet> createState() => _CoverPickerSheetState();
}

class _CoverPickerSheetState extends State<CoverPickerSheet> {
  late CoverTemplate _current;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _pageCtrl = PageController(
      initialPage: CoverTemplate.values.indexOf(_current),
      viewportFraction: 0.78,
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int idx) {
    HapticFeedback.selectionClick();
    setState(() => _current = CoverTemplate.values[idx]);
  }

  void _confirm() async {
    HapticFeedback.lightImpact();
    await CoverPickerSheet.saveLastTemplate(_current);
    if (!mounted) return;
    Navigator.of(context).pop(_current);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final templates = CoverTemplate.values;
    final accent = Color(_current.accentColor);

    return Container(
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: p.outlineSoft, width: 0.6)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            _GrabHandle(color: p.outlineSoft),
            _Header(
              title: widget.title,
              subtitle: 'Chaque modèle est unique. Faites glisser pour explorer.',
              p: p,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: templates.length,
                onPageChanged: _onPageChanged,
                // Clamping évite le « bounce » iOS qui peut rivaliser avec le modal.
                physics: const ClampingScrollPhysics(),
                itemBuilder: (ctx, i) {
                  final t = templates[i];
                  final isCurrent = t == _current;
                  return RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedScale(
                        scale: isCurrent ? 1.0 : 0.94,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: _PreviewCard(
                          template: t,
                          isCurrent: isCurrent,
                          accent: Color(t.accentColor),
                          p: p,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _PageIndicators(
              count: templates.length,
              current: templates.indexOf(_current),
              accent: accent,
              p: p,
            ),
            const SizedBox(height: 8),
            _Footer(
              template: _current,
              accent: accent,
              confirmLabel: widget.confirmLabel,
              p: p,
              onConfirm: _confirm,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Sub-widgets
// ============================================================================

class _GrabHandle extends StatelessWidget {
  final Color color;
  const _GrabHandle({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 10, bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final AppPalette p;
  const _Header({required this.title, required this.subtitle, required this.p});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: p.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: p.inkMuted, fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final CoverTemplate template;
  final bool isCurrent;
  final Color accent;
  final AppPalette p;

  const _PreviewCard({
    required this.template,
    required this.isCurrent,
    required this.accent,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    final asset = template.thumbnailAsset;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final maxSide = (MediaQuery.sizeOf(context).shortestSide * dpr * 1.2).round();
    final cachePx = math.min(1400, math.max(480, maxSide));

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: p.surface,
                border: Border.all(
                  color: isCurrent ? accent : p.outlineSoft,
                  width: isCurrent ? 2 : 0.6,
                ),
                boxShadow: [
                  if (isCurrent)
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 595 / 842, // A4
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        asset,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        cacheWidth: cachePx,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (context, error, stackTrace) => ColoredBox(
                          color: p.surfaceHigh,
                          child: Icon(Icons.broken_image_outlined, color: p.inkMuted, size: 40),
                        ),
                      ),
                      // Léger voile en bas → meilleure lisibilité du label
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.55),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: accent.withValues(alpha: 0.65), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                template.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  final int count;
  final int current;
  final Color accent;
  final AppPalette p;

  const _PageIndicators({
    required this.count,
    required this.current,
    required this.accent,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final on = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: on ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: on ? accent : p.outlineSoft,
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final CoverTemplate template;
  final Color accent;
  final String confirmLabel;
  final AppPalette p;
  final VoidCallback onConfirm;

  const _Footer({
    required this.template,
    required this.accent,
    required this.confirmLabel,
    required this.p,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              template.description,
              key: ValueKey(template),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: p.inkMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onConfirm,
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withValues(alpha: 0.78)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.4),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      confirmLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
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
