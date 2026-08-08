import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cover_data.dart';
import 'cover_field_slot.dart';
import 'cover_layout.dart';
import 'cover_layout_engine.dart';

/// **Studio Slate** — couverture vectorielle (points PDF A4).
abstract final class StudioSlateLayout {
  static const slate = PdfColor.fromInt(0xFF263238);
  static const slateMuted = PdfColor.fromInt(0xFF546E7A);
  static const teal = PdfColor.fromInt(0xFF00897B);

  static const logo = CoverLogoConfig(left: 40, top: 36, width: 80, maxHeight: 52);

  static const companyName = CoverFieldSlot(
    left: 136,
    top: 36,
    width: 300,
    fontPt: 14,
    bold: true,
    uppercase: true,
    color: slate,
    letterSpacing: 1.2,
  );

  static const companyTel = CoverFieldSlot(
    left: 136,
    top: 56,
    width: 300,
    fontPt: 9,
    color: slateMuted,
  );

  static const documentLabel = CoverFieldSlot(
    left: 420,
    top: 46,
    width: 135,
    fontPt: 20,
    bold: true,
    color: PdfColors.white,
    textAlign: pw.TextAlign.right,
    letterSpacing: 3,
  );

  static const numero = CoverFieldSlot(
    left: 420,
    top: 72,
    width: 135,
    fontPt: 10,
    color: PdfColors.white,
    textAlign: pw.TextAlign.right,
  );

  static const date = CoverFieldSlot(
    left: 420,
    top: 86,
    width: 135,
    fontPt: 9,
    color: PdfColor.fromInt(0xFFB0BEC5),
    textAlign: pw.TextAlign.right,
  );

  static const clientNom = CoverFieldSlot(
    left: 130,
    top: 166,
    width: 400,
    fontPt: 12,
    bold: true,
    uppercase: true,
    color: slate,
    showPlaceholder: true,
  );

  static const clientSociete = CoverFieldSlot(
    left: 130,
    top: 183,
    width: 400,
    fontPt: 10.5,
    color: slate,
    showPlaceholder: true,
  );

  static const clientAdresse = CoverFieldSlot(
    left: 130,
    top: 200,
    width: 400,
    fontPt: 10.5,
    color: slate,
    showPlaceholder: true,
  );

  static const clientTel = CoverFieldSlot(
    left: 130,
    top: 217,
    width: 400,
    fontPt: 10.5,
    color: slate,
    showPlaceholder: true,
  );

  static const clientEmail = CoverFieldSlot(
    left: 130,
    top: 234,
    width: 400,
    fontPt: 10.5,
    color: slate,
    showPlaceholder: true,
  );

  static const titreDevis = CoverFieldSlot(
    left: 40,
    top: 340,
    width: 515,
    fontPt: 11,
    italic: true,
    color: slate,
    maxLines: 3,
    lineHeight: 1.4,
  );

  static const noteNb = CoverFieldSlot(
    left: 40,
    top: 722,
    width: 515,
    fontPt: 8.5,
    italic: true,
    color: slateMuted,
    maxLines: 2,
  );

  static const footerContacts = CoverFieldSlot(
    left: 40,
    top: 774,
    width: 280,
    fontPt: 8.5,
    color: PdfColors.white,
  );

  static const footerAdresse = CoverFieldSlot(
    left: 320,
    top: 774,
    width: 235,
    fontPt: 8.5,
    color: PdfColor.fromInt(0xFFB0BEC5),
    textAlign: pw.TextAlign.right,
  );

  static VectorCoverDefinition get definition => VectorCoverDefinition(
        buildDecorations: _decorations,
        fields: [
          CoverField.companyName(companyName),
          CoverField.companyTel(companyTel),
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
          CoverField.raw(
            footerContacts,
            (d) => [
              if (d.companyEmail.isNotEmpty) d.companyEmail,
              if (d.companyWebsite.isNotEmpty) d.companyWebsite,
            ].join('  ·  '),
          ),
          CoverField.raw(footerAdresse, (d) => d.companyAdresse),
        ],
      );

  static List<pw.Widget> _decorations(
    CoverLayoutContext layout,
    CoverData data,
    pw.ImageProvider? logo,
  ) {
    return [
      pw.Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        child: pw.Container(width: 6, color: teal),
      ),
      pw.Positioned(
        left: 40,
        top: 108,
        right: 40,
        child: pw.Container(height: 1, color: PdfColor.fromInt(0xFFCFD8DC)),
      ),
      pw.Positioned(
        left: 40,
        top: 128,
        right: 40,
        child: pw.Container(
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CLIENT',
                style: CoverTextStyle.of(
                  size: 8,
                  color: teal,
                  bold: true,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 10),
            ],
          ),
        ),
      ),
      pw.Positioned(
        left: 400,
        top: 36,
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: pw.BoxDecoration(
            color: slate,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.SizedBox(width: 120, height: 56),
        ),
      ),
      if (logo != null)
        pw.Positioned(
          left: 40,
          top: 36,
          child: pw.Container(
            height: 52,
            margin: const pw.EdgeInsets.only(right: 14),
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
        ),
      pw.Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: pw.Container(
          height: 56,
          color: slate,
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        ),
      ),
    ];
  }
}
