import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cover_data.dart';
import 'cover_field_slot.dart';
import 'cover_layout.dart';
import 'cover_layout_engine.dart';

/// **Corporate Navy Gold** — coordonnées individuelles (PNG 1055×1491 px).
abstract final class CorporateNavyGoldLayout {
  static const navy = PdfColor.fromInt(0xFF0E1B3D);
  static const gold = PdfColor.fromInt(0xFFB7892F);
  static const ink = PdfColor.fromInt(0xFF111111);
  static const muted = PdfColor.fromInt(0xFF5C5C5C);

  static const companyMask = CoverMaskRect(
    left: 768,
    top: 888,
    width: 265,
    height: 118,
    color: navy,
  );

  static const logo = CoverLogoConfig(
    left: 800,
    top: 900,
    width: 200,
    maxHeight: 28,
  );

  static const companyName = CoverFieldSlot(
    left: 778,
    top: 932,
    width: 245,
    fontPt: 9.5,
    bold: true,
    uppercase: true,
    color: gold,
    textAlign: pw.TextAlign.center,
    letterSpacing: 1.8,
    maxLines: 2,
  );

  static const companySlogan = CoverFieldSlot(
    left: 778,
    top: 962,
    width: 245,
    fontPt: 7,
    color: PdfColors.white,
    textAlign: pw.TextAlign.center,
    letterSpacing: 0.8,
  );

  static const documentLabel = CoverFieldSlot(
    left: 52,
    top: 48,
    width: 380,
    fontPt: 34,
    bold: true,
    color: navy,
    letterSpacing: 6,
  );

  static const numero = CoverFieldSlot(
    left: 52,
    top: 108,
    width: 380,
    fontPt: 12,
    bold: true,
    color: navy,
    letterSpacing: 1,
  );

  static const date = CoverFieldSlot(
    left: 52,
    top: 128,
    width: 380,
    fontPt: 10,
    color: muted,
    letterSpacing: 0.4,
  );

  static const titreDevis = CoverFieldSlot(
    left: 52,
    top: 160,
    width: 280,
    fontPt: 12,
    italic: true,
    color: navy,
    maxLines: 3,
    lineHeight: 1.4,
  );

  static const refLogo = CoverLogoConfig(
    left: 862,
    top: 54,
    width: 148,
    maxHeight: 36,
  );

  static const refDocumentLabel = CoverFieldSlot(
    left: 852,
    top: 96,
    width: 168,
    fontPt: 9,
    bold: true,
    color: muted,
    textAlign: pw.TextAlign.center,
    letterSpacing: 2.2,
  );

  static const refNumero = CoverFieldSlot(
    left: 852,
    top: 112,
    width: 168,
    fontPt: 11,
    bold: true,
    color: navy,
    textAlign: pw.TextAlign.center,
    letterSpacing: 0.6,
  );

  static const refDate = CoverFieldSlot(
    left: 852,
    top: 128,
    width: 168,
    fontPt: 9.5,
    color: muted,
    textAlign: pw.TextAlign.center,
  );

  static const clientNom = CoverFieldSlot(
    left: 156,
    top: 352,
    width: 360,
    fontPt: 11,
    bold: true,
    uppercase: true,
    color: ink,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  static const clientSociete = CoverFieldSlot(
    left: 156,
    top: 396,
    width: 360,
    fontPt: 10,
    color: muted,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  static const clientAdresse = CoverFieldSlot(
    left: 156,
    top: 440,
    width: 360,
    fontPt: 10,
    color: muted,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  static const clientTel = CoverFieldSlot(
    left: 156,
    top: 484,
    width: 360,
    fontPt: 10,
    color: muted,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  static const clientEmail = CoverFieldSlot(
    left: 156,
    top: 528,
    width: 360,
    fontPt: 10,
    color: muted,
    maskColor: PdfColors.white,
    maskHeight: 14,
    showPlaceholder: true,
  );

  static const noteNb = CoverFieldSlot(
    left: 52,
    top: 1321,
    width: 680,
    fontPt: 9,
    italic: true,
    color: muted,
    maxLines: 3,
  );

  static PngCoverDefinition get definition => PngCoverDefinition(
        masks: const [companyMask],
        logo: logo,
        fields: [
          CoverField.companyName(companyName),
          CoverField.companySlogan(companySlogan),
          CoverField.documentLabel(documentLabel),
          CoverField.titreDevis(titreDevis),
          CoverField.clientNom(clientNom),
          CoverField.clientSociete(clientSociete),
          CoverField.clientAdresse(clientAdresse),
          CoverField.clientTel(clientTel),
          CoverField.clientEmail(clientEmail),
          CoverField.noteNb(noteNb),
        ],
        extras: _extras,
      );

  static List<pw.Widget> _extras(
    CoverLayoutContext layout,
    CoverData data,
    pw.ImageProvider? logo,
  ) {
    final widgets = <pw.Widget>[];

    if (logo == null) {
      widgets.addAll([
        ...layout.field(CoverField.numero(numero), data),
        ...layout.field(CoverField.date(date), data),
      ]);
    } else {
      widgets.addAll([
        if (layout.logo(refLogo, logo) case final refLogoWidget?) refLogoWidget,
        ...layout.field(CoverField.documentLabel(refDocumentLabel), data),
        ...layout.field(CoverField.numero(refNumero), data),
        ...layout.field(CoverField.date(refDate), data),
      ]);
    }

    widgets.addAll([
      pw.Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: pw.Container(height: layout.dim(78), color: PdfColors.white),
      ),
      pw.Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: pw.Container(
          height: layout.dim(78),
          padding: pw.EdgeInsets.symmetric(
            horizontal: layout.dim(36),
            vertical: layout.dim(14),
          ),
          decoration: pw.BoxDecoration(
            color: navy,
            border: pw.Border(
              top: pw.BorderSide(color: gold, width: layout.dim(1.4)),
            ),
          ),
          child: pw.Row(
            children: [
              _footerItem(
                layout,
                'APPELEZ-NOUS',
                data.companyTel.isEmpty ? '-' : data.companyTel,
              ),
              _footerSep(layout),
              _footerItem(
                layout,
                'ÉCRIVEZ-NOUS',
                data.companyEmail.isEmpty ? '-' : data.companyEmail,
              ),
              _footerSep(layout),
              _footerItem(
                layout,
                'VISITEZ-NOUS',
                data.companyWebsite.isEmpty
                    ? (data.companyAdresse.isEmpty ? '-' : data.companyAdresse)
                    : data.companyWebsite,
              ),
            ],
          ),
        ),
      ),
    ]);

    return widgets;
  }

  static pw.Widget _footerItem(
    CoverLayoutContext layout,
    String label,
    String value,
  ) {
    return pw.Expanded(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            label,
            style: CoverTextStyle.of(
              size: layout.pt(8),
              color: gold,
              bold: true,
              letterSpacing: 1.6,
            ),
          ),
          pw.SizedBox(height: layout.dim(4)),
          pw.Text(
            value,
            maxLines: 2,
            textAlign: pw.TextAlign.center,
            style: CoverTextStyle.of(
              size: layout.pt(9),
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footerSep(CoverLayoutContext layout) {
    return pw.Container(
      width: layout.dim(1),
      height: layout.dim(30),
      color: gold,
      margin: pw.EdgeInsets.symmetric(horizontal: layout.dim(18)),
    );
  }
}
