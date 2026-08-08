import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cover_data.dart';
import 'cover_field_slot.dart';
import 'cover_layout.dart';
import 'cover_layout_engine.dart';

/// **Prestige Emerald** — couverture vectorielle (points PDF A4).
abstract final class PrestigeEmeraldLayout {
  static const emerald = PdfColor.fromInt(0xFF0B4F4A);
  static const emeraldLight = PdfColor.fromInt(0xFF15695F);
  static const gold = PdfColor.fromInt(0xFFC9A961);
  static const ink = PdfColor.fromInt(0xFF1A2E2A);
  static const muted = PdfColor.fromInt(0xFF5A6B66);

  static const companyName = CoverFieldSlot(
    left: 98,
    top: 42,
    width: 320,
    fontPt: 13,
    bold: true,
    uppercase: true,
    color: PdfColors.white,
    letterSpacing: 1.4,
  );

  static const companySlogan = CoverFieldSlot(
    left: 98,
    top: 60,
    width: 320,
    fontPt: 8,
    color: PdfColor.fromInt(0xFFB2DFDB),
  );

  static const documentLabel = CoverFieldSlot(
    left: 403,
    top: 48,
    width: 120,
    fontPt: 9,
    bold: true,
    color: emerald,
    textAlign: pw.TextAlign.center,
    letterSpacing: 2.5,
  );

  static const numero = CoverFieldSlot(
    left: 403,
    top: 66,
    width: 120,
    fontPt: 11,
    bold: true,
    color: ink,
    textAlign: pw.TextAlign.center,
  );

  static const date = CoverFieldSlot(
    left: 403,
    top: 82,
    width: 120,
    fontPt: 9.5,
    color: muted,
    textAlign: pw.TextAlign.center,
  );

  static const clientNom = CoverFieldSlot(
    left: 132,
    top: 244,
    width: 400,
    fontPt: 12,
    bold: true,
    uppercase: true,
    color: ink,
    showPlaceholder: true,
  );

  static const clientSociete = CoverFieldSlot(
    left: 132,
    top: 261,
    width: 400,
    fontPt: 10.5,
    color: muted,
    showPlaceholder: true,
  );

  static const clientAdresse = CoverFieldSlot(
    left: 132,
    top: 278,
    width: 400,
    fontPt: 10.5,
    color: muted,
    showPlaceholder: true,
  );

  static const clientTel = CoverFieldSlot(
    left: 132,
    top: 295,
    width: 400,
    fontPt: 10.5,
    color: muted,
    showPlaceholder: true,
  );

  static const clientEmail = CoverFieldSlot(
    left: 132,
    top: 312,
    width: 400,
    fontPt: 10.5,
    color: muted,
    showPlaceholder: true,
  );

  static const titreDevis = CoverFieldSlot(
    left: 52,
    top: 432,
    width: 511,
    fontPt: 11,
    italic: true,
    color: emeraldLight,
    maxLines: 3,
    lineHeight: 1.35,
  );

  static const noteNb = CoverFieldSlot(
    left: 40,
    top: 732,
    width: 515,
    fontPt: 8.5,
    italic: true,
    color: muted,
    maxLines: 2,
  );

  static const footerTel = CoverFieldSlot(
    left: 40,
    top: 780,
    width: 160,
    fontPt: 9,
    bold: true,
    color: PdfColors.white,
  );

  static const footerEmail = CoverFieldSlot(
    left: 217,
    top: 780,
    width: 160,
    fontPt: 9,
    color: PdfColor.fromInt(0xFFB2DFDB),
    textAlign: pw.TextAlign.center,
  );

  static const footerWebsite = CoverFieldSlot(
    left: 395,
    top: 780,
    width: 160,
    fontPt: 9,
    color: gold,
    textAlign: pw.TextAlign.right,
  );

  static VectorCoverDefinition get definition => VectorCoverDefinition(
        buildDecorations: _decorations,
        fields: [
          CoverField.companyName(companyName),
          CoverField.companySlogan(companySlogan),
          CoverField.documentLabel(documentLabel),
          CoverField.numero(numero),
          CoverField.date(date),
          CoverField.clientNom(clientNom),
          CoverField.clientSociete(clientSociete),
          CoverField.clientAdresse(clientAdresse),
          CoverField.clientTel(clientTel),
          CoverField.clientEmail(clientEmail),
          CoverField.titreDevis(titreDevis),
          CoverField.noteNb(noteNb),
          CoverField.companyTel(footerTel),
          CoverField.companyEmail(footerEmail),
          CoverField.companyWebsite(footerWebsite),
        ],
      );

  static List<pw.Widget> _decorations(
    CoverLayoutContext layout,
    CoverData data,
    pw.ImageProvider? logo,
  ) {
    return [
      pw.Positioned(
        left: -40,
        top: -60,
        child: pw.Transform.rotate(
          angle: -0.08,
          child: pw.Container(
            width: layout.pageW + 80,
            height: 200,
            color: emerald,
          ),
        ),
      ),
      pw.Positioned(
        left: 40,
        top: 28,
        child: pw.Container(width: 48, height: 3, color: gold),
      ),
      if (logo != null)
        pw.Positioned(
          left: 40,
          top: 42,
          child: pw.Container(
            height: 46,
            margin: const pw.EdgeInsets.only(right: 12),
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
        ),
      pw.Positioned(
        right: 36,
        top: 36,
        child: pw.Container(
          width: 148,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: gold, width: 1.4),
          ),
          child: pw.SizedBox(height: 52),
        ),
      ),
      pw.Positioned(
        left: 40,
        top: 200,
        right: 40,
        child: pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: gold, width: 3),
              top: const pw.BorderSide(color: PdfColor.fromInt(0xFFE8ECEB)),
              right: const pw.BorderSide(color: PdfColor.fromInt(0xFFE8ECEB)),
              bottom: const pw.BorderSide(color: PdfColor.fromInt(0xFFE8ECEB)),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DESTINATAIRE',
                style: CoverTextStyle.of(
                  size: 8,
                  color: gold,
                  bold: true,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 12),
            ],
          ),
        ),
      ),
      if (data.titre != null && data.titre!.trim().isNotEmpty)
        pw.Positioned(
          left: 40,
          top: 420,
          right: 40,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            color: PdfColor.fromInt(0xFFF4F8F7),
            child: pw.SizedBox(height: 40),
          ),
        ),
      pw.Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: pw.Container(
          height: 52,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(colors: [emerald, emeraldLight]),
          ),
        ),
      ),
    ];
  }
}
