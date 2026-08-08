import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cover_field_slot.dart';
import 'cover_layout.dart';
import 'cover_layout_engine.dart';

/// **Navy Arabesque** — coordonnées individuelles (PNG 1055×1491 px).
abstract final class NavyArabesqueLayout {
  static const navy = PdfColor.fromInt(0xFF142654);
  static const gold = PdfColor.fromInt(0xFFB7892F);
  static const ink = PdfColor.fromInt(0xFF14213D);
  static const muted = PdfColor.fromInt(0xFF5B6A8A);

  static const logo = CoverLogoConfig(
    left: 878,
    top: 58,
    width: 138,
    maxHeight: 36,
  );

  static const refDocumentLabel = CoverFieldSlot(
    left: 868,
    top: 98,
    width: 158,
    fontPt: 9,
    bold: true,
    color: muted,
    textAlign: pw.TextAlign.center,
    letterSpacing: 2.2,
  );

  static const refNumero = CoverFieldSlot(
    left: 868,
    top: 114,
    width: 158,
    fontPt: 11,
    bold: true,
    color: navy,
    textAlign: pw.TextAlign.center,
  );

  static const refDate = CoverFieldSlot(
    left: 868,
    top: 130,
    width: 158,
    fontPt: 9.5,
    color: muted,
    textAlign: pw.TextAlign.center,
  );

  static const documentLabel = CoverFieldSlot(
    left: 62,
    top: 188,
    width: 400,
    fontPt: 32,
    bold: true,
    color: navy,
    letterSpacing: 6,
  );

  static const titreDevis = CoverFieldSlot(
    left: 62,
    top: 274,
    width: 280,
    fontPt: 12,
    italic: true,
    color: navy,
    maxLines: 3,
    lineHeight: 1.4,
  );

  static const clientNom = CoverFieldSlot(
    left: 152,
    top: 574,
    width: 380,
    fontPt: 11,
    bold: true,
    uppercase: true,
    color: ink,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  static const clientSociete = CoverFieldSlot(
    left: 152,
    top: 624,
    width: 380,
    fontPt: 10,
    color: muted,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  static const clientAdresse = CoverFieldSlot(
    left: 152,
    top: 674,
    width: 380,
    fontPt: 10,
    color: muted,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  static const clientTel = CoverFieldSlot(
    left: 152,
    top: 724,
    width: 380,
    fontPt: 10,
    color: muted,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  static const clientEmail = CoverFieldSlot(
    left: 152,
    top: 774,
    width: 380,
    fontPt: 10,
    color: muted,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  static const noteNb = CoverFieldSlot(
    left: 62,
    top: 1305,
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
          CoverField.noteNb(noteNb),
        ],
      );
}
