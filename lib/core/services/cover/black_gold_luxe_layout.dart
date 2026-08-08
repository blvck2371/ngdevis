import 'package:pdf/pdf.dart';

import 'cover_field_slot.dart';
import 'cover_layout.dart';
import 'cover_layout_engine.dart';

/// **Black & Gold Luxe** — FICHIER ACTIF pour le PDF.
///
/// Modifiez `left`, `top`, `width`, `fontPt` ci-dessous puis faites un
/// **Hot Restart** (pas un simple Hot Reload) pour voir le changement.
///
/// Repères PNG (1055×1491 px, coin haut-gauche) :
/// - Cadre or haut-droite → logo / DEVIS / N° / date
/// - Icônes centre-gauche → nom, société, adresse, téléphone
/// - Bas de page → note NB
abstract final class BlackGoldLuxeLayout {
  static const ink = PdfColor.fromInt(0xFF1A1A1A);
  static const muted = PdfColor.fromInt(0xFF5A5A5A);

  static const refMask = CoverMaskRect(
    left: 868,
    top: 52,
    width: 162,
    height: 100,
    color: PdfColors.white,
  );

  static const logo = CoverLogoConfig(
    left: 878,
    top: 58,
    width: 142,
    maxHeight: 36,
  );

  static const documentLabel = CoverFieldSlot(
    left: 878,
    top: 96,
    width: 142,
    fontPt: 7.5,
    bold: true,
    color: muted,
  );

  static const numero = CoverFieldSlot(
    left: 878,
    top: 108,
    width: 142,
    fontPt: 9.5,
    bold: true,
    color: ink,
  );

  static const date = CoverFieldSlot(
    left: 878,
    top: 122,
    width: 142,
    fontPt: 8.5,
    color: muted,
  );

  /// 👤 Nom client — aligné sur la 1re icône (ligne or)
  static const clientNom = CoverFieldSlot(
    left: 150,
    top: 518,
    width: 400,
    fontPt: 11.5,
    bold: true,
    uppercase: true,
    color: ink,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  /// 🏢 Société
  static const clientSociete = CoverFieldSlot(
    left: 150,
    top: 570,
    width: 400,
    fontPt: 10.5,
    color: ink,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  /// 📍 Adresse
  static const clientAdresse = CoverFieldSlot(
    left: 150,
    top: 622,
    width: 400,
    fontPt: 10.5,
    color: ink,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  /// 📞 Téléphone
  static const clientTel = CoverFieldSlot(
    left: 150,
    top: 674,
    width: 400,
    fontPt: 10.5,
    color: ink,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  /// ✉️ E-mail
  static const clientEmail = CoverFieldSlot(
    left: 150,
    top: 726,
    width: 400,
    fontPt: 10,
    color: muted,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  static const titreDevis = CoverFieldSlot(
    left: 52,
    top: 460,
    width: 440,
    fontPt: 11,
    italic: true,
    color: muted,
    maxLines: 3,
  );

  static const noteNb = CoverFieldSlot(
    left: 52,
    top: 1380,
    width: 700,
    fontPt: 9,
    italic: true,
    color: muted,
    maxLines: 3,
  );

  static PngCoverDefinition get definition => PngCoverDefinition(
        masks: const [refMask],
        logo: logo,
        fields: [
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
        ],
      );
}
