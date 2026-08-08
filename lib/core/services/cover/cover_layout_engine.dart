import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cover_data.dart';
import 'cover_field_slot.dart';
import 'cover_layout.dart';

String formatDateFr(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Styles texte PDF partagés par tous les templates.
class CoverTextStyle {
  static pw.TextStyle of({
    required double size,
    PdfColor color = PdfColors.black,
    bool bold = false,
    bool italic = false,
    double? letterSpacing,
    double? height,
  }) {
    return pw.TextStyle(
      fontSize: size,
      color: color,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

/// Mise à l'échelle **contain** d'un gabarit designer vers la page PDF.
class CoverLayoutEngine implements CoverLayoutContext {
  final double pageW;
  final double pageH;
  final double designW;
  final double designH;
  final double scale;
  final double ox;
  final double oy;

  CoverLayoutEngine(
    this.pageW,
    this.pageH, {
    this.designW = 1055,
    this.designH = 1491,
  })  : scale = math.min(pageW / designW, pageH / designH),
        ox = (pageW - designW * math.min(pageW / designW, pageH / designH)) / 2,
        oy = (pageH - designH * math.min(pageW / designW, pageH / designH)) / 2;

  factory CoverLayoutEngine.png(double pageW, double pageH) =>
      CoverLayoutEngine(pageW, pageH);

  factory CoverLayoutEngine.vector(double pageW, double pageH) =>
      CoverLayoutEngine(pageW, pageH, designW: pageW, designH: pageH);

  double x(double px) => ox + px * scale;
  double y(double py) => oy + py * scale;
  @override
  double dim(double px) => px * scale;

  @override
  double pt(double designPt) =>
      math.max(7.0, designPt * scale * (595 / designW));

  pw.Widget background(pw.MemoryImage? bg) {
    if (bg == null) return pw.Container(color: PdfColors.white);
    return pw.Positioned(
      left: ox,
      top: oy,
      child: pw.SizedBox(
        width: designW * scale,
        height: designH * scale,
        child: pw.Image(bg, fit: pw.BoxFit.fill),
      ),
    );
  }

  @override
  pw.Positioned place(
    double leftPx,
    double topPx, {
    double? widthPx,
    double? heightPx,
    required pw.Widget child,
  }) {
    pw.Widget wrapped = child;
    if (widthPx != null || heightPx != null) {
      wrapped = pw.SizedBox(
        width: widthPx != null ? dim(widthPx) : null,
        height: heightPx != null ? dim(heightPx) : null,
        child: child,
      );
    }
    return pw.Positioned(
      left: x(leftPx),
      top: y(topPx),
      child: wrapped,
    );
  }

  pw.Positioned placeBottom(
    double leftPx,
    double bottomPx, {
    double? widthPx,
    required pw.Widget child,
  }) {
    pw.Widget wrapped = child;
    if (widthPx != null) {
      wrapped = pw.SizedBox(width: dim(widthPx), child: child);
    }
    return pw.Positioned(
      left: x(leftPx),
      bottom: dim(bottomPx),
      child: wrapped,
    );
  }

  pw.Widget mask(CoverMaskRect rect) {
    return place(
      rect.left,
      rect.top,
      widthPx: rect.width,
      heightPx: rect.height,
      child: pw.Container(color: rect.color),
    );
  }

  @override
  pw.Widget? logo(CoverLogoConfig config, pw.ImageProvider? image) {
    if (image == null) return null;
    return place(
      config.left,
      config.top,
      widthPx: config.width,
      heightPx: config.maxHeight,
      child: pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
    );
  }

  @override
  List<pw.Widget> field(CoverFieldBinding binding, CoverData data) {
    var text = binding.value(data)?.trim() ?? '';
    if (text.isEmpty) {
      if (binding.skipIfEmpty || !binding.slot.showPlaceholder) {
        return const [];
      }
      text = '-';
    } else if (binding.format != null) {
      text = binding.format!(text);
    }
    return placeSlot(binding.slot, text);
  }

  @override
  List<pw.Widget> placeSlot(CoverFieldSlot slot, String text) {
    if (slot.uppercase) text = text.toUpperCase();

    if (slot.labelPrefix != null) {
      return [_labeledField(slot, text)];
    }

    final out = <pw.Widget>[];
    if (slot.maskColor != null) {
      out.add(
        place(
          slot.left,
          slot.top,
          widthPx: slot.width,
          heightPx: slot.maskHeight,
          child: pw.Container(color: slot.maskColor),
        ),
      );
    }
    out.add(
      place(
        slot.left,
        slot.top,
        widthPx: slot.width,
        child: pw.Text(
          text,
          maxLines: slot.maxLines,
          textAlign: slot.textAlign,
          overflow: pw.TextOverflow.clip,
          style: CoverTextStyle.of(
            size: pt(slot.fontPt),
            color: slot.color,
            bold: slot.bold,
            italic: slot.italic,
            letterSpacing: slot.letterSpacing,
            height: slot.lineHeight,
          ),
        ),
      ),
    );
    return out;
  }

  pw.Widget _labeledField(CoverFieldSlot slot, String value) {
    final valueFontPt = pt(slot.fontPt);
    final labelPt = valueFontPt * 0.9;
    final dotPt = math.max(4.0, valueFontPt * 0.34);
    final dotted = String.fromCharCodes(List.generate(280, (_) => 0x00B7));
    const lineCol = PdfColor.fromInt(0xFF6E6E6E);

    return place(
      slot.left,
      slot.top,
      widthPx: slot.width,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.RichText(
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            softWrap: false,
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '${slot.labelPrefix} : ',
                  style: pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: labelPt,
                    color: slot.labelColor ?? PdfColors.black,
                    height: 1.05,
                  ),
                ),
                pw.TextSpan(
                  text: value,
                  style: pw.TextStyle(
                    font: slot.bold
                        ? pw.Font.helveticaBold()
                        : pw.Font.helvetica(),
                    fontSize: valueFontPt,
                    color: slot.color,
                    height: slot.lineHeight,
                  ),
                ),
              ],
            ),
          ),
          if (slot.dottedUnderline) ...[
            pw.SizedBox(height: dim(4)),
            pw.Text(
              dotted,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: dotPt,
                letterSpacing: 2,
                color: lineCol,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rendu générique des couvertures PNG à partir d'une [PngCoverDefinition].
class PngCoverBuilder {
  static pw.Widget build({
    required PngCoverDefinition definition,
    required CoverData data,
    required double w,
    required double h,
    pw.ImageProvider? logo,
    pw.MemoryImage? bg,
  }) {
    final layout = CoverLayoutEngine.png(w, h);
    final children = <pw.Widget>[
      layout.background(bg),
      for (final mask in definition.masks) layout.mask(mask),
      if (definition.logo?.mask != null) layout.mask(definition.logo!.mask!),
      if (definition.logo != null) ...[
        if (layout.logo(definition.logo!, logo) case final widget?) widget,
      ],
      for (final binding in definition.fields) ...layout.field(binding, data),
      if (definition.extras != null) ...definition.extras!(layout, data, logo),
    ];
    return pw.SizedBox(
      width: w,
      height: h,
      child: pw.Stack(children: children),
    );
  }
}

/// Rendu générique des couvertures vectorielles.
class VectorCoverBuilder {
  static pw.Widget build({
    required VectorCoverDefinition definition,
    required CoverData data,
    required double w,
    required double h,
    pw.ImageProvider? logo,
    PdfColor? backgroundColor,
  }) {
    final layout = CoverLayoutEngine.vector(w, h);
    final children = <pw.Widget>[
      if (backgroundColor != null)
        pw.Container(width: w, height: h, color: backgroundColor),
      ...definition.buildDecorations(layout, data, logo),
      for (final binding in definition.fields) ...layout.field(binding, data),
    ];
    return pw.Container(
      width: w,
      height: h,
      child: pw.Stack(children: children),
    );
  }
}

/// Raccourcis pour créer des [CoverFieldBinding] lisibles dans les layouts.
abstract final class CoverField {
  static CoverFieldBinding documentLabel(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => d.documentLabel,
      );

  static CoverFieldBinding numero(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => d.numero,
        format: (n) => 'N° $n',
      );

  static CoverFieldBinding date(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => formatDateFr(d.date),
      );

  static CoverFieldBinding titreDevis(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => d.titre,
      );

  static CoverFieldBinding noteNb(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => d.noteNb,
        format: (n) => 'NB : $n',
      );

  static CoverFieldBinding clientNom(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => d.clientNom,
        skipIfEmpty: !slot.showPlaceholder,
      );

  static CoverFieldBinding clientSociete(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => d.clientSociete,
        skipIfEmpty: !slot.showPlaceholder,
      );

  static CoverFieldBinding clientAdresse(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => d.clientAdresse,
        skipIfEmpty: !slot.showPlaceholder,
      );

  static CoverFieldBinding clientTel(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => d.clientTel,
        skipIfEmpty: !slot.showPlaceholder,
      );

  static CoverFieldBinding clientEmail(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => d.clientEmail,
        skipIfEmpty: !slot.showPlaceholder,
      );

  static CoverFieldBinding companyName(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => d.companyName,
      );

  static CoverFieldBinding companySlogan(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => d.companySlogan,
      );

  static CoverFieldBinding companyTel(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => d.companyTel,
      );

  static CoverFieldBinding companyEmail(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => d.companyEmail,
      );

  static CoverFieldBinding companyWebsite(CoverFieldSlot slot) => CoverFieldBinding(
        slot: slot,
        value: (d) => d.companyWebsite,
      );

  static CoverFieldBinding raw(
    CoverFieldSlot slot,
    String? Function(CoverData data) value, {
    String Function(String text)? format,
    bool skipIfEmpty = true,
  }) =>
      CoverFieldBinding(
        slot: slot,
        value: value,
        format: format,
        skipIfEmpty: skipIfEmpty,
      );
}
