import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/database/hive_storage.dart';
import '../core/models/devis.dart';
import '../core/services/cover/cover_template.dart';
import '../core/theme/app_theme.dart';

/// Données utilisateur superposées sur l’aperçu du picker (même zones que le PDF).
class CoverPreviewData {
  final String documentLabel;
  final String numero;
  final String clientNom;
  final String companyName;
  final String? titre;

  const CoverPreviewData({
    this.documentLabel = 'DEVIS',
    required this.numero,
    this.clientNom = '',
    this.companyName = '',
    this.titre,
  });

  factory CoverPreviewData.fromDevis(Devis devis) {
    var company = (devis.nomEntreprise ?? '').trim();
    if (company.isEmpty) {
      company = (HiveStorage.getCompanySettings()['nom'] ?? '').trim();
    }
    return CoverPreviewData(
      numero: devis.numero,
      clientNom: (devis.client?.nom ?? '').trim(),
      companyName: company,
      titre: (devis.titreDevis ?? '').trim().isEmpty
          ? null
          : devis.titreDevis!.trim(),
    );
  }
}

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
  final CoverPreviewData? previewData;

  const CoverPickerSheet({
    super.key,
    required this.initial,
    this.title = 'Choisissez un modèle',
    this.confirmLabel = 'Générer le PDF',
    this.previewData,
  });

  /// Affiche le picker. Retourne le `CoverTemplate` choisi, ou `null` si
  /// l'utilisateur a annulé.
  static Future<CoverTemplate?> show(
    BuildContext context, {
    CoverTemplate? initial,
    String? title,
    String? confirmLabel,
    CoverPreviewData? previewData,
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
                previewData: previewData,
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
                          previewData: widget.previewData,
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
  final CoverPreviewData? previewData;

  const _PreviewCard({
    required this.template,
    required this.isCurrent,
    required this.accent,
    required this.p,
    this.previewData,
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
                      if (asset != null)
                        Image.asset(
                          asset,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          cacheWidth: cachePx,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stackTrace) => ColoredBox(
                            color: p.surfaceHigh,
                            child: Icon(Icons.broken_image_outlined, color: p.inkMuted, size: 40),
                          ),
                        )
                      else if (template.isVectorCover)
                        _VectorCoverThumbnail(template: template)
                      else
                        ColoredBox(color: p.surfaceHigh),
                      if (previewData != null && asset != null)
                        _CoverPreviewOverlay(
                          template: template,
                          data: previewData!,
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

/// Superposition Flutter calée sur les mêmes ratios que `_CoverLayout` (1055×1491).
class _CoverPreviewOverlay extends StatelessWidget {
  final CoverTemplate template;
  final CoverPreviewData data;

  const _CoverPreviewOverlay({
    required this.template,
    required this.data,
  });

  static const _tw = CoverTemplateMeta.designWidth;
  static const _th = CoverTemplateMeta.designHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final scale = math.min(w / _tw, h / _th);
        final ox = (w - _tw * scale) / 2;
        final oy = (h - _th * scale) / 2;

        double x(double px) => ox + px * scale;
        double y(double py) => oy + py * scale;
        double fs(double pt) => math.max(6.0, pt * scale * (595 / _tw));

        final zones = _zonesFor(template);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (data.clientNom.isNotEmpty)
              Positioned(
                left: x(zones.clientLeft),
                top: y(zones.clientTop),
                width: zones.clientWidth * scale,
                child: Text(
                  data.clientNom.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fs(zones.clientSize),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF14213D),
                    height: 1.1,
                  ),
                ),
              ),
            if (zones.titleSize > 0)
              Positioned(
                left: x(zones.titleLeft),
                top: y(zones.titleTop),
                child: Text(
                  data.documentLabel,
                  style: TextStyle(
                    fontSize: fs(zones.titleSize),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: const Color(0xFF0E1B3D),
                    height: 1.0,
                  ),
                ),
              ),
            if (zones.numLeft > 0)
              Positioned(
                left: x(zones.numLeft),
                top: y(zones.numTop),
                child: Text(
                  'N° ${data.numero}',
                  style: TextStyle(
                    fontSize: fs(11),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF263238),
                  ),
                ),
              ),
            if (data.companyName.isNotEmpty && zones.companyWidth > 0)
              Positioned(
                left: x(zones.companyLeft),
                top: y(zones.companyTop),
                width: zones.companyWidth * scale,
                child: Text(
                  data.companyName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fs(9),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB7892F),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  _PreviewZones _zonesFor(CoverTemplate t) {
    switch (t) {
      case CoverTemplate.orientalOrange:
        return const _PreviewZones(
          titleLeft: 618,
          titleTop: 208,
          titleSize: 52,
          numLeft: 118,
          numTop: 192,
          clientLeft: 118,
          clientTop: 390,
          clientWidth: 420,
          clientSize: 18,
          companyLeft: 650,
          companyTop: 300,
          companyWidth: 340,
        );
      case CoverTemplate.corporateNavyGold:
        return const _PreviewZones(
          titleLeft: 52,
          titleTop: 48,
          titleSize: 32,
          numLeft: 852,
          numTop: 70,
          clientLeft: 156,
          clientTop: 340,
          clientWidth: 320,
          clientSize: 11,
          companyLeft: 820,
          companyTop: 940,
          companyWidth: 180,
        );
      case CoverTemplate.blackGoldLuxe:
        return const _PreviewZones(
          titleLeft: 868,
          titleTop: 52,
          titleSize: 0,
          numLeft: 868,
          numTop: 78,
          clientLeft: 146,
          clientTop: 522,
          clientWidth: 320,
          clientSize: 11,
          companyLeft: 0,
          companyTop: 0,
          companyWidth: 0,
        );
      case CoverTemplate.navyArabesque:
        return const _PreviewZones(
          titleLeft: 65,
          titleTop: 238,
          titleSize: 36,
          numLeft: 65,
          numTop: 318,
          clientLeft: 148,
          clientTop: 598,
          clientWidth: 300,
          clientSize: 11,
          companyLeft: 885,
          companyTop: 78,
          companyWidth: 110,
        );
      default:
        return const _PreviewZones(
          titleLeft: 55,
          titleTop: 235,
          titleSize: 36,
          numLeft: 55,
          numTop: 315,
          clientLeft: 148,
          clientTop: 490,
          clientWidth: 300,
          clientSize: 11,
          companyLeft: 885,
          companyTop: 78,
          companyWidth: 110,
        );
    }
  }
}

class _PreviewZones {
  final double titleLeft;
  final double titleTop;
  final double titleSize;
  final double numLeft;
  final double numTop;
  final double clientLeft;
  final double clientTop;
  final double clientWidth;
  final double clientSize;
  final double companyLeft;
  final double companyTop;
  final double companyWidth;

  const _PreviewZones({
    required this.titleLeft,
    required this.titleTop,
    required this.titleSize,
    required this.numLeft,
    required this.numTop,
    required this.clientLeft,
    required this.clientTop,
    required this.clientWidth,
    required this.clientSize,
    required this.companyLeft,
    required this.companyTop,
    required this.companyWidth,
  });
}

/// Miniature des couvertures vectorielles NG (Studio / Prestige).
class _VectorCoverThumbnail extends StatelessWidget {
  final CoverTemplate template;

  const _VectorCoverThumbnail({required this.template});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VectorCoverPainter(template),
      size: Size.infinite,
    );
  }
}

class _VectorCoverPainter extends CustomPainter {
  final CoverTemplate template;

  _VectorCoverPainter(this.template);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (template == CoverTemplate.studioSlate) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFF5F7FA));
      canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.012, h), Paint()..color = const Color(0xFF00897B));
      canvas.drawRect(
        Rect.fromLTWH(w * 0.62, h * 0.05, w * 0.32, h * 0.12),
        Paint()..color = const Color(0xFF263238),
      );
      canvas.drawRect(
        Rect.fromLTWH(w * 0.08, h * 0.22, w * 0.84, h * 0.28),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, h * 0.92, w, h * 0.08),
        Paint()..color = const Color(0xFF263238),
      );
      return;
    }
    if (template == CoverTemplate.prestigeEmerald) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);
      final path = Path()
        ..moveTo(-w * 0.05, 0)
        ..lineTo(w * 1.05, 0)
        ..lineTo(w * 0.95, h * 0.28)
        ..lineTo(-w * 0.05, h * 0.18)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFF0B4F4A));
      canvas.drawRect(
        Rect.fromLTWH(w * 0.68, h * 0.05, w * 0.26, h * 0.14),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawRect(
        Rect.fromLTWH(w * 0.08, h * 0.32, w * 0.84, h * 0.26),
        Paint()
          ..color = const Color(0xFFC9A961)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, h * 0.92, w, h * 0.08),
        Paint()..color = const Color(0xFF15695F),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VectorCoverPainter oldDelegate) =>
      oldDelegate.template != template;
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
