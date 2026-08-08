import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cover_field_slot.dart';
import 'cover_layout.dart';
import 'cover_data.dart';
import 'cover_layout_engine.dart';

/// **Oriental Orange** — coordonnées individuelles (PNG 1055×1491 px).
abstract final class OrientalOrangeLayout {
  static const gold = PdfColor.fromInt(0xFFC9A227);
  static const ink = PdfColor.fromInt(0xFF1A1510);
  static const muted = PdfColor.fromInt(0xFF4A4036);

  static const logo = CoverLogoConfig(
    left: 618,
    top: 78,
    width: 400,
    maxHeight: 210,
  );

  static const companyName = CoverFieldSlot(
    left: 630,
    top: 288,
    width: 376,
    fontPt: 11,
    bold: true,
    uppercase: true,
    color: ink,
    textAlign: pw.TextAlign.center,
    letterSpacing: 1.1,
    lineHeight: 1.12,
    maxLines: 2,
  );

  static const documentLabel = CoverFieldSlot(
    left: 618,
    top: 208,
    width: 400,
    fontPt: 72,
    bold: true,
    color: ink,
    textAlign: pw.TextAlign.right,
    letterSpacing: 4.5,
    lineHeight: 1.0,
  );

  static const numero = CoverFieldSlot(
    left: 118,
    top: 192,
    width: 340,
    fontPt: 13,
    bold: true,
    color: ink,
    letterSpacing: 1.0,
  );

  static const date = CoverFieldSlot(
    left: 118,
    top: 218,
    width: 340,
    fontPt: 11.5,
    color: muted,
    lineHeight: 1.1,
  );

  static const objetLabel = CoverFieldSlot(
    left: 118,
    top: 292,
    width: 500,
    fontPt: 9,
    bold: true,
    color: muted,
    letterSpacing: 2.0,
  );

  static const titreDevis = CoverFieldSlot(
    left: 118,
    top: 312,
    width: 500,
    fontPt: 12,
    italic: true,
    color: ink,
    maxLines: 4,
    lineHeight: 1.38,
  );

  static const clientNom = CoverFieldSlot(
    left: 118,
    top: 372,
    width: 760,
    fontPt: 22,
    bold: true,
    uppercase: true,
    color: ink,
    labelPrefix: 'Nom',
    labelColor: PdfColors.black,
    dottedUnderline: true,
    showPlaceholder: true,
    lineHeight: 1.1,
  );

  static const clientSociete = CoverFieldSlot(
    left: 118,
    top: 430,
    width: 760,
    fontPt: 20,
    color: ink,
    labelPrefix: 'Société',
    labelColor: PdfColors.black,
    dottedUnderline: true,
    showPlaceholder: true,
    lineHeight: 1.1,
  );

  static const clientAdresse = CoverFieldSlot(
    left: 118,
    top: 488,
    width: 760,
    fontPt: 18,
    color: ink,
    labelPrefix: 'Adresse',
    labelColor: PdfColors.black,
    dottedUnderline: true,
    showPlaceholder: true,
    lineHeight: 1.15,
  );

  static const clientTel = CoverFieldSlot(
    left: 118,
    top: 546,
    width: 760,
    fontPt: 20,
    color: ink,
    labelPrefix: 'Téléphone',
    labelColor: PdfColors.black,
    dottedUnderline: true,
    showPlaceholder: true,
    lineHeight: 1.14,
  );

  static const clientEmail = CoverFieldSlot(
    left: 118,
    top: 604,
    width: 760,
    fontPt: 18,
    color: ink,
    labelPrefix: 'E-mail',
    labelColor: PdfColors.black,
    dottedUnderline: true,
    showPlaceholder: true,
    lineHeight: 1.14,
  );

  static const noteNb = CoverFieldSlot(
    left: 118,
    top: 1255,
    width: 820,
    fontPt: 9,
    italic: true,
    color: muted,
    maxLines: 3,
  );

  static const companySlogan = CoverFieldSlot(
    left: 150,
    top: 1410,
    width: 755,
    fontPt: 10,
    italic: true,
    color: PdfColors.white,
    textAlign: pw.TextAlign.center,
    maxLines: 2,
    lineHeight: 1.15,
  );

  static PngCoverDefinition get definition => PngCoverDefinition(
        logo: logo,
        fields: [
          CoverField.companyName(companyName),
          CoverField.documentLabel(documentLabel),
          CoverField.numero(numero),
          CoverField.date(date),
          CoverField.clientNom(clientNom),
          CoverField.clientSociete(clientSociete),
          CoverField.clientAdresse(clientAdresse),
          CoverField.clientTel(clientTel),
          CoverField.clientEmail(clientEmail),
          CoverField.noteNb(noteNb),
          CoverField.companySlogan(companySlogan),
        ],
        extras: _extras,
      );

  static List<pw.Widget> _extras(
    CoverLayoutContext layout,
    CoverData data,
    pw.ImageProvider? logo,
  ) {
    final widgets = <pw.Widget>[
      layout.place(
        618,
        296,
        widthPx: 360,
        heightPx: 2.5,
        child: pw.Container(color: gold),
      ),
    ];

    if (data.titre != null && data.titre!.trim().isNotEmpty) {
      widgets.addAll([
        ...layout.placeSlot(objetLabel, 'OBJET'),
        ...layout.field(CoverField.titreDevis(titreDevis), data),
      ]);
    }

    return widgets;
  }
}
