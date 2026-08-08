import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cover_field_slot.dart';
import 'cover_layout.dart';
import 'cover_layout_engine.dart';

/// **Minimalist Gold** — coordonnées individuelles (PNG 1055×1491 px).
abstract final class MinimalistGoldLayout {
  static const gold = PdfColor.fromInt(0xFFB7892F);
  static const ink = PdfColor.fromInt(0xFF15171C);
  static const muted = PdfColor.fromInt(0xFF5F636E);

  static const logo = CoverLogoConfig(
    left: 878,
    top: 60,
    width: 138,
    maxHeight: 36,
  );

  static const refDocumentLabel = CoverFieldSlot(
    left: 868,
    top: 100,
    width: 158,
    fontPt: 9,
    bold: true,
    color: muted,
    textAlign: pw.TextAlign.center,
    letterSpacing: 2.2,
  );

  static const refNumero = CoverFieldSlot(
    left: 868,
    top: 116,
    width: 158,
    fontPt: 11,
    bold: true,
    color: ink,
    textAlign: pw.TextAlign.center,
  );

  static const refDate = CoverFieldSlot(
    left: 868,
    top: 132,
    width: 158,
    fontPt: 9.5,
    color: muted,
    textAlign: pw.TextAlign.center,
  );

  static const documentLabel = CoverFieldSlot(
    left: 52,
    top: 188,
    width: 420,
    fontPt: 32,
    bold: true,
    color: ink,
    letterSpacing: 6,
  );

  static const numero = CoverFieldSlot(
    left: 52,
    top: 248,
    width: 420,
    fontPt: 12,
    bold: true,
    color: ink,
    letterSpacing: 1,
  );

  static const date = CoverFieldSlot(
    left: 52,
    top: 268,
    width: 420,
    fontPt: 10,
    color: muted,
  );

  static const titreDevis = CoverFieldSlot(
    left: 52,
    top: 300,
    width: 280,
    fontPt: 12,
    italic: true,
    color: ink,
    maxLines: 3,
    lineHeight: 1.4,
  );

  static const clientNom = CoverFieldSlot(
    left: 148,
    top: 488,
    width: 360,
    fontPt: 11.5,
    bold: true,
    uppercase: true,
    color: ink,
  );

  static const clientSociete = CoverFieldSlot(
    left: 148,
    top: 514,
    width: 360,
    fontPt: 10.5,
    color: muted,
  );

  static const clientAdresse = CoverFieldSlot(
    left: 148,
    top: 540,
    width: 360,
    fontPt: 10.5,
    color: muted,
  );

  static const clientTel = CoverFieldSlot(
    left: 148,
    top: 566,
    width: 360,
    fontPt: 10.5,
    color: muted,
  );

  static const clientEmail = CoverFieldSlot(
    left: 148,
    top: 592,
    width: 360,
    fontPt: 10.5,
    color: muted,
  );

  static const companyTel = CoverFieldSlot(
    left: 868,
    top: 1372,
    width: 160,
    fontPt: 9,
    color: muted,
    textAlign: pw.TextAlign.right,
  );

  static const companyEmail = CoverFieldSlot(
    left: 868,
    top: 1390,
    width: 160,
    fontPt: 9,
    color: muted,
    textAlign: pw.TextAlign.right,
  );

  static const companyWebsite = CoverFieldSlot(
    left: 868,
    top: 1408,
    width: 160,
    fontPt: 9,
    bold: true,
    color: gold,
    textAlign: pw.TextAlign.right,
  );

  static const noteNb = CoverFieldSlot(
    left: 60,
    top: 1297,
    width: 700,
    fontPt: 9,
    italic: true,
    color: muted,
    maxLines: 3,
  );

  static PngCoverDefinition get definition => PngCoverDefinition(
        logo: logo,
        fields: [
          CoverField.documentLabel(refDocumentLabel),
          CoverField.numero(refNumero),
          CoverField.date(refDate),
          CoverField.documentLabel(documentLabel),
          CoverField.numero(numero),
          CoverField.date(date),
          CoverField.titreDevis(titreDevis),
          CoverField.clientNom(clientNom),
          CoverField.clientSociete(clientSociete),
          CoverField.clientAdresse(clientAdresse),
          CoverField.clientTel(clientTel),
          CoverField.clientEmail(clientEmail),
          CoverField.companyTel(companyTel),
          CoverField.companyEmail(companyEmail),
          CoverField.companyWebsite(companyWebsite),
          CoverField.noteNb(noteNb),
        ],
      );
}
