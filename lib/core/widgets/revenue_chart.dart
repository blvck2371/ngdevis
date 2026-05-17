import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_currency.dart';

/// Donnée mensuelle pour le graphique du dashboard.
class MonthlyRevenue {
  /// Label court en français — ex. "janv.", "févr.", "mars"…
  final String label;
  final double value;
  const MonthlyRevenue(this.label, this.value);
}

/// Style de rendu pour le graphique.
enum RevenueChartStyle {
  /// Courbe lissée style "trader" (Robinhood / TradingView).
  line,
  /// Histogramme à barres arrondies.
  bars,
  /// Camembert (donut) : part de chaque mois dans le revenu total.
  pie,
}

/// Graphique premium des revenus mensuels — 3 styles au choix.
///
/// Pour chaque style un painter custom (zéro dépendance externe) :
/// - line : Catmull-Rom → Bézier cubique, gradient sous la courbe, point
///   pulsé + flag de valeur en **or** sur le mois courant.
/// - bars : barres arrondies avec gradient, valeur en or au-dessus de la
///   barre courante.
/// - pie  : donut avec arcs proportionnels, hole central qui affiche la
///   valeur totale en or, légende compacte en haut.
class RevenueChart extends StatefulWidget {
  final List<MonthlyRevenue> data;
  final double height;
  final RevenueChartStyle style;

  /// Index du point à mettre en évidence (mois courant). -1 = aucun.
  final int currentIndex;

  /// Format de la valeur affichée dans le flag / au-dessus des barres.
  final String Function(double v)? valueFormatter;

  const RevenueChart({
    super.key,
    required this.data,
    this.height = 200,
    this.style = RevenueChartStyle.line,
    this.currentIndex = -1,
    this.valueFormatter,
  });

  @override
  State<RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart>
    with TickerProviderStateMixin {
  late final AnimationController _drawCtrl;
  late final Animation<double> _drawT;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _drawCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _drawT = CurvedAnimation(parent: _drawCtrl, curve: Curves.easeOutCubic);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _drawCtrl.forward());
  }

  @override
  void didUpdateWidget(RevenueChart old) {
    super.didUpdateWidget(old);
    if (old.style != widget.style || old.data.length != widget.data.length) {
      _drawCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _drawCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final fmt = widget.valueFormatter ?? _defaultFormat;
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([_drawT, _pulseCtrl]),
        builder: (context, _) {
          return CustomPaint(
            painter: _switchPainter(p, fmt),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  CustomPainter _switchPainter(AppPalette p, String Function(double) fmt) {
    switch (widget.style) {
      case RevenueChartStyle.line:
        return _LinePainter(
          data: widget.data,
          progress: _drawT.value,
          pulse: _pulseCtrl.value,
          currentIndex: widget.currentIndex,
          accent: p.accent,
          accentDeep: p.accentDeep,
          gridColor: p.outlineSoft,
          labelColor: p.inkMuted,
          valueColor: p.gold,
          surfaceColor: p.surface,
          valueFormatter: fmt,
        );
      case RevenueChartStyle.bars:
        return _BarsPainter(
          data: widget.data,
          progress: _drawT.value,
          currentIndex: widget.currentIndex,
          accent: p.accent,
          accentDeep: p.accentDeep,
          gridColor: p.outlineSoft,
          labelColor: p.inkMuted,
          valueColor: p.gold,
          valueFormatter: fmt,
        );
      case RevenueChartStyle.pie:
        return _PiePainter(
          data: widget.data,
          progress: _drawT.value,
          currentIndex: widget.currentIndex,
          accent: p.accent,
          accentDeep: p.accentDeep,
          gold: p.gold,
          inkColor: p.ink,
          labelColor: p.inkMuted,
          surfaceColor: p.surface,
          outlineSoft: p.outlineSoft,
          valueFormatter: fmt,
        );
    }
  }

  static String _defaultFormat(double v) {
    final s = v.toStringAsFixed(0);
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    var i = s.length % 3;
    if (i == 0) i = 3;
    buf.write(s.substring(0, i));
    for (; i < s.length; i += 3) {
      buf.write(' ${s.substring(i, i + 3)}');
    }
    return buf.toString();
  }
}

// ============================================================================
// SHARED HELPERS
// ============================================================================

void _drawDashedHLine(Canvas canvas, double y, double w, Paint p) {
  const dash = 4.0;
  const gap = 5.0;
  var x = 0.0;
  while (x < w) {
    final end = math.min(x + dash, w);
    canvas.drawLine(Offset(x, y), Offset(end, y), p);
    x += dash + gap;
  }
}

TextPainter _txt(String s, Color color, {double size = 10.5, FontWeight weight = FontWeight.w500, double spacing = 0.2}) {
  return TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(color: color, fontSize: size, fontWeight: weight, letterSpacing: spacing),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
}

// ============================================================================
// LINE PAINTER — courbe lissée style trader
// ============================================================================

class _LinePainter extends CustomPainter {
  final List<MonthlyRevenue> data;
  final double progress;
  final double pulse;
  final int currentIndex;
  final Color accent;
  final Color accentDeep;
  final Color gridColor;
  final Color labelColor;
  final Color valueColor;
  final Color surfaceColor;
  final String Function(double) valueFormatter;

  _LinePainter({
    required this.data,
    required this.progress,
    required this.pulse,
    required this.currentIndex,
    required this.accent,
    required this.accentDeep,
    required this.gridColor,
    required this.labelColor,
    required this.valueColor,
    required this.surfaceColor,
    required this.valueFormatter,
  });

  static const _labelArea = 22.0;
  static const _topPad = 36.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final chartH = size.height - _labelArea - _topPad;
    final chartTop = _topPad;
    final chartBottom = chartTop + chartH;
    final n = data.length;
    final maxVal = data.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    final scale = maxVal <= 0 ? 1.0 : maxVal;

    // Grille
    final gridPaint = Paint()..color = gridColor.withValues(alpha: 0.5)..strokeWidth = 0.8;
    for (final frac in const [0.25, 0.5, 0.75]) {
      _drawDashedHLine(canvas, chartTop + chartH * frac, size.width, gridPaint);
    }
    canvas.drawLine(Offset(0, chartBottom), Offset(size.width, chartBottom), Paint()..color = gridColor..strokeWidth = 1);

    final stepX = n > 1 ? size.width / (n - 1) : size.width;
    final points = <Offset>[];
    for (var i = 0; i < n; i++) {
      points.add(Offset(i * stepX, chartBottom - (data[i].value / scale) * (chartH - 6)));
    }

    // Smooth path (Catmull-Rom → cubic Bézier)
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;
      const tension = 0.18;
      final c1 = Offset(p1.dx + (p2.dx - p0.dx) * tension, p1.dy + (p2.dy - p0.dy) * tension);
      final c2 = Offset(p2.dx - (p3.dx - p1.dx) * tension, p2.dy - (p3.dy - p1.dy) * tension);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    // Clip pour effet "ligne qui se trace"
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width * progress.clamp(0.0, 1.0), size.height));
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, chartBottom)
      ..lineTo(points.first.dx, chartBottom)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.35),
            accent.withValues(alpha: 0.06),
            accent.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromLTRB(0, chartTop, size.width, chartBottom)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [accent, accentDeep],
        ).createShader(Rect.fromLTRB(0, chartTop, size.width, chartBottom)),
    );
    canvas.restore();

    // Labels mois (intelligents — 6 max)
    final indices = <int>{0, n - 1};
    if (n >= 4) {
      final step = ((n - 1) / 5).round().clamp(1, n - 1);
      for (var i = step; i < n - 1; i += step) {
        indices.add(i);
      }
    } else {
      for (var i = 1; i < n - 1; i++) {
        indices.add(i);
      }
    }
    for (final i in indices) {
      final isCurrent = i == currentIndex;
      final tp = _txt(
        data[i].label,
        isCurrent ? accent : labelColor,
        weight: isCurrent ? FontWeight.w700 : FontWeight.w500,
      );
      final x = (points[i].dx - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(x, chartBottom + 6));
    }

    // Point courant + flag or
    if (currentIndex >= 0 && currentIndex < n &&
        progress > (currentIndex / (n - 1)).clamp(0.0, 1.0)) {
      _drawCurrentPoint(canvas, size, points[currentIndex], data[currentIndex].value);
    }
  }

  void _drawCurrentPoint(Canvas canvas, Size size, Offset point, double value) {
    canvas.drawCircle(point, 6 + 8 * pulse,
        Paint()..color = accent.withValues(alpha: (1 - pulse) * 0.45));
    canvas.drawCircle(point, 14,
        Paint()..shader = RadialGradient(colors: [accent.withValues(alpha: 0.35), Colors.transparent])
            .createShader(Rect.fromCircle(center: point, radius: 14)));
    canvas.drawCircle(point, 7, Paint()..color = surfaceColor);
    canvas.drawCircle(point, 7, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..color = accent);
    canvas.drawCircle(point, 3, Paint()..color = accent);

    final tp = _txt('${valueFormatter(value)} $kCurrencyLabel', valueColor, size: 12, weight: FontWeight.w800, spacing: -0.2);
    const padH = 9.0, padV = 5.0;
    final w = tp.width + padH * 2, h = tp.height + padV * 2 + 4;
    var x = (point.dx - w / 2).clamp(0.0, size.width - w);
    final y = point.dy - 18 - h;
    final rect = Rect.fromLTWH(x, y, w, h - 4);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(rrect.shift(const Offset(0, 4)),
        Paint()..color = Colors.black.withValues(alpha: 0.22)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawRRect(rrect, Paint()..shader = LinearGradient(colors: [valueColor.withValues(alpha: 0.20), valueColor.withValues(alpha: 0.10)]).createShader(rect));
    canvas.drawRRect(rrect, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = valueColor.withValues(alpha: 0.45));
    final tri = Path()..moveTo(point.dx - 5, y + h - 4)..lineTo(point.dx + 5, y + h - 4)..lineTo(point.dx, y + h + 2)..close();
    canvas.drawPath(tri, Paint()..color = valueColor.withValues(alpha: 0.20));
    tp.paint(canvas, Offset(x + padH, y + padV));
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.progress != progress || old.pulse != pulse || old.data != data || old.currentIndex != currentIndex;
}

// ============================================================================
// BARS PAINTER — histogramme premium
// ============================================================================

class _BarsPainter extends CustomPainter {
  final List<MonthlyRevenue> data;
  final double progress;
  final int currentIndex;
  final Color accent;
  final Color accentDeep;
  final Color gridColor;
  final Color labelColor;
  final Color valueColor;
  final String Function(double) valueFormatter;

  _BarsPainter({
    required this.data,
    required this.progress,
    required this.currentIndex,
    required this.accent,
    required this.accentDeep,
    required this.gridColor,
    required this.labelColor,
    required this.valueColor,
    required this.valueFormatter,
  });

  static const _labelArea = 22.0;
  static const _topPad = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final chartH = size.height - _labelArea - _topPad;
    final chartTop = _topPad;
    final chartBottom = chartTop + chartH;
    final n = data.length;
    final maxVal = data.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    final scale = maxVal <= 0 ? 1.0 : maxVal;

    // Grille
    final gridPaint = Paint()..color = gridColor.withValues(alpha: 0.5)..strokeWidth = 0.8;
    for (final frac in const [0.25, 0.5, 0.75]) {
      _drawDashedHLine(canvas, chartTop + chartH * frac, size.width, gridPaint);
    }
    canvas.drawLine(Offset(0, chartBottom), Offset(size.width, chartBottom),
        Paint()..color = gridColor..strokeWidth = 1);

    const gap = 6.0;
    final barW = ((size.width - gap * (n - 1)) / n).clamp(8.0, 40.0);

    for (var i = 0; i < n; i++) {
      final v = data[i].value;
      final t = (progress - i * 0.04).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(t);
      final h = (v / scale) * (chartH - 6) * eased;
      final x = i * (barW + gap);
      final y = chartBottom - h;
      final isCurrent = i == currentIndex;

      final colors = isCurrent
          ? [valueColor, valueColor.withValues(alpha: 0.55)]
          : [accent, accentDeep];

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barW, h),
        topLeft: Radius.circular(barW / 2.5),
        topRight: Radius.circular(barW / 2.5),
        bottomLeft: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ).createShader(Rect.fromLTWH(x, y, barW, h)),
      );

      // Valeur en or au-dessus de la barre courante
      if (isCurrent && v > 0) {
        final tp = _txt('${valueFormatter(v)} $kCurrencyLabel', valueColor, size: 11, weight: FontWeight.w800, spacing: -0.2);
        final tx = (x + barW / 2 - tp.width / 2).clamp(0.0, size.width - tp.width);
        final ty = (y - tp.height - 6).clamp(chartTop, chartBottom);
        tp.paint(canvas, Offset(tx, ty));
      }

      // Label mois
      final tpL = _txt(
        data[i].label,
        isCurrent ? valueColor : labelColor,
        weight: isCurrent ? FontWeight.w700 : FontWeight.w500,
        size: n > 9 ? 9 : 10.5,
      );
      final lx = (x + barW / 2 - tpL.width / 2).clamp(0.0, size.width - tpL.width);
      tpL.paint(canvas, Offset(lx, chartBottom + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) =>
      old.progress != progress || old.data != data || old.currentIndex != currentIndex;
}

// ============================================================================
// PIE PAINTER — donut avec gradient violet → or
// ============================================================================

class _PiePainter extends CustomPainter {
  final List<MonthlyRevenue> data;
  final double progress;
  final int currentIndex;
  final Color accent;
  final Color accentDeep;
  final Color gold;
  final Color inkColor;
  final Color labelColor;
  final Color surfaceColor;
  final Color outlineSoft;
  final String Function(double) valueFormatter;

  _PiePainter({
    required this.data,
    required this.progress,
    required this.currentIndex,
    required this.accent,
    required this.accentDeep,
    required this.gold,
    required this.inkColor,
    required this.labelColor,
    required this.surfaceColor,
    required this.outlineSoft,
    required this.valueFormatter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // On garde uniquement les mois avec une valeur > 0.
    final entries = <(int idx, MonthlyRevenue r)>[];
    for (var i = 0; i < data.length; i++) {
      if (data[i].value > 0) entries.add((i, data[i]));
    }
    final total = entries.fold<double>(0, (s, e) => s + e.$2.value);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(size.width, size.height) / 2 - 8;
    final inner = radius * 0.62;

    // Cas vide : donut gris avec message
    if (entries.isEmpty || total <= 0) {
      _paintEmptyDonut(canvas, size, Offset(cx, cy), radius, inner);
      return;
    }

    // Arc de fond complet (anneau gris pour la base)
    canvas.drawCircle(
      Offset(cx, cy),
      (radius + inner) / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - inner
        ..color = outlineSoft.withValues(alpha: 0.5),
    );

    // Tracé des arcs proportionnels
    var startAngle = -math.pi / 2; // 12h
    final sweepGap = 0.018; // petit espace entre slices
    final fullProgress = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));

    for (var i = 0; i < entries.length; i++) {
      final (idx, r) = entries[i];
      final fraction = r.value / total;
      final fullSweep = fraction * (math.pi * 2);
      final sweep = (fullSweep - sweepGap) * fullProgress;
      if (sweep <= 0) {
        startAngle += fullSweep;
        continue;
      }

      // Couleur : interpolation violet → or selon la position dans l'année
      final t = entries.length == 1 ? 0.5 : i / (entries.length - 1);
      final base = Color.lerp(accent, gold, t)!;
      final isCurrent = idx == currentIndex;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: (radius + inner) / 2),
        startAngle,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (radius - inner) * (isCurrent ? 1.18 : 1.0)
          ..strokeCap = StrokeCap.butt
          ..shader = SweepGradient(
            startAngle: startAngle,
            endAngle: startAngle + sweep,
            colors: [base, Color.lerp(base, Colors.white, 0.18)!],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius)),
      );

      startAngle += fullSweep;
    }

    // Centre : valeur du mois courant ou total
    final centerLabel = currentIndex >= 0 && currentIndex < data.length
        ? data[currentIndex].label
        : 'Année';
    final centerValue = currentIndex >= 0 && currentIndex < data.length && data[currentIndex].value > 0
        ? data[currentIndex].value
        : total;
    final isCurrentSlice = currentIndex >= 0 && currentIndex < data.length && data[currentIndex].value > 0;

    final tpLabel = _txt(
      centerLabel.toUpperCase(),
      labelColor,
      size: 10,
      weight: FontWeight.w700,
      spacing: 1.4,
    );
    tpLabel.paint(canvas, Offset(cx - tpLabel.width / 2, cy - 22));

    final tpValue = _txt(
      '${valueFormatter(centerValue)} $kCurrencyLabel',
      gold,
      size: 18,
      weight: FontWeight.w800,
      spacing: -0.4,
    );
    tpValue.paint(canvas, Offset(cx - tpValue.width / 2, cy - 4));

    if (isCurrentSlice) {
      final pct = (data[currentIndex].value / total * 100).toStringAsFixed(0);
      final tpPct = _txt('$pct % de l\'année', labelColor, size: 10, weight: FontWeight.w600);
      tpPct.paint(canvas, Offset(cx - tpPct.width / 2, cy + 18));
    } else {
      final tpSub = _txt('${entries.length} mois actifs', labelColor, size: 10, weight: FontWeight.w600);
      tpSub.paint(canvas, Offset(cx - tpSub.width / 2, cy + 18));
    }
  }

  void _paintEmptyDonut(Canvas canvas, Size size, Offset c, double radius, double inner) {
    canvas.drawCircle(
      c,
      (radius + inner) / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - inner
        ..color = outlineSoft.withValues(alpha: 0.6),
    );
    final tpL = _txt('Aucune donnée', labelColor, size: 12, weight: FontWeight.w600);
    tpL.paint(canvas, Offset(c.dx - tpL.width / 2, c.dy - tpL.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.progress != progress || old.data != data || old.currentIndex != currentIndex;
}
