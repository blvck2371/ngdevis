import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cover_field_slot.dart';
import 'cover_layout.dart';
import 'cover_layout_engine.dart';

/// **Navy Geometric** — coordonnées individuelles (PNG 1055×1491 px).
abstract final class NavyGeometricLayout {
  static const navy = PdfColor.fromInt(0xFF0F2A6A);
  static const gold = PdfColor.fromInt(0xFFB7892F);
  static const ink = PdfColor.fromInt(0xFF13183A);
  static const muted = PdfColor.fromInt(0xFF5F6B82);

  static const logo = CoverLogoConfig(
    left: 872,
    top: 58,
    width: 138,
    maxHeight: 36,
  );

  static const refDocumentLabel = CoverFieldSlot(
    left: 862,
    top: 98,
    width: 158,
    fontPt: 9,
    bold: true,
    color: muted,
    textAlign: pw.TextAlign.center,
    letterSpacing: 2.2,
  );

  static const refNumero = CoverFieldSlot(
    left: 862,
    top: 114,
    width: 158,
    fontPt: 11,
    bold: true,
    color: navy,
    textAlign: pw.TextAlign.center,
  );

  static const refDate = CoverFieldSlot(
    left: 862,
    top: 130,
    width: 158,
    fontPt: 9.5,
    color: muted,
    textAlign: pw.TextAlign.center,
  );

  static const documentLabel = CoverFieldSlot(
    left: 52,
    top: 182,
    width: 400,
    fontPt: 32,
    bold: true,
    color: navy,
    letterSpacing: 6,
  );

  static const titreDevis = CoverFieldSlot(
    left: 52,
    top: 268,
    width: 280,
    fontPt: 12,
    italic: true,
    color: navy,
    maxLines: 3,
    lineHeight: 1.4,
  );

  static const clientNom = CoverFieldSlot(
    left: 52,
    top: 418,
    width: 400,
    fontPt: 11.5,
    bold: true,
    uppercase: true,
    color: ink,
  );

  static const clientSociete = CoverFieldSlot(
    left: 52,
    top: 443,
    width: 400,
    fontPt: 10.5,
    color: muted,
  );

  static const clientAdresse = CoverFieldSlot(
    left: 52,
    top: 468,
    width: 400,
    fontPt: 10.5,
    color: muted,
  );

  static const clientTel = CoverFieldSlot(
    left: 52,
    top: 493,
    width: 400,
    fontPt: 10.5,
    color: muted,
  );

  static const clientEmail = CoverFieldSlot(
    left: 52,
    top: 518,
    width: 400,
    fontPt: 10.5,
    color: muted,
  );

  static const companyTel = CoverFieldSlot(
    left: 78,
    top: 1448,
    width: 400,
    fontPt: 10,
    bold: true,
    color: navy,
  );

  static const noteNb = CoverFieldSlot(
    left: 52,
    top: 1341,
    width: 680,
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
          CoverField.titreDevis(titreDevis),
          CoverField.clientNom(clientNom),
          CoverField.clientSociete(clientSociete),
          CoverField.clientAdresse(clientAdresse),
          CoverField.clientTel(clientTel),
          CoverField.clientEmail(clientEmail),
          CoverField.companyTel(companyTel),
          CoverField.noteNb(noteNb),
        ],
      );
}
