import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../database/hive_storage.dart';
import '../../models/devis.dart';
import 'cover_template.dart';

/// Données nécessaires pour rendre n'importe quelle couverture.
/// Découplé du modèle [Devis] pour pouvoir un jour le réutiliser avec
/// une `Facture` (mêmes champs sémantiques).
class CoverData {
  final String documentLabel; // ex: "DEVIS" / "FACTURE"
  final String numero;
  final DateTime date;
  final String? titre;

  // Bloc client
  final String clientNom;
  final String clientSociete;
  final String clientAdresse;
  final String clientTel;
  final String clientEmail;

  // Bloc société
  final String companyName;
  final String companyTel;
  final String companyAdresse;
  final String companyEmail;
  final String companyWebsite;
  final String companySlogan;

  const CoverData({
    required this.documentLabel,
    required this.numero,
    required this.date,
    this.titre,
    this.clientNom = '',
    this.clientSociete = '',
    this.clientAdresse = '',
    this.clientTel = '',
    this.clientEmail = '',
    this.companyName = '',
    this.companyTel = '',
    this.companyAdresse = '',
    this.companyEmail = '',
    this.companyWebsite = '',
    this.companySlogan = '',
  });

  /// Fabrique pratique depuis un [Devis] (lit aussi les paramètres société Hive
  /// quand le devis n'a pas la valeur).
  factory CoverData.fromDevis(Devis devis) {
    String company = (devis.nomEntreprise ?? '').trim();
    if (company.isEmpty) {
      company = (HiveStorage.getCompanySettings()['nom'] ?? '').trim();
    }
    String tel = (devis.telEntreprise ?? '').trim();
    if (tel.isEmpty) {
      tel = (HiveStorage.getCompanySettings()['telephone'] ?? '').trim();
    }
    String adresse = (devis.adresseEntreprise ?? '').trim();
    if (adresse.isEmpty) {
      adresse = (HiveStorage.getCompanySettings()['adresse'] ?? '').trim();
    }
    final settings = HiveStorage.getCompanySettings();
    return CoverData(
      documentLabel: 'DEVIS',
      numero: devis.numero,
      date: devis.date,
      titre: (devis.titreDevis ?? '').trim().isEmpty
          ? null
          : devis.titreDevis!.trim(),
      clientNom: (devis.client?.nom ?? '').trim(),
      clientSociete: (devis.client?.societe ?? '').trim(),
      clientAdresse: (devis.client?.adresse ?? '').trim(),
      clientTel: (devis.client?.telephone ?? '').trim(),
      clientEmail: (devis.client?.email ?? '').trim(),
      companyName: company,
      companyTel: tel,
      companyAdresse: adresse,
      companyEmail: (settings['email'] ?? '').trim(),
      companyWebsite:
          ((settings['site'] ?? '').toString().trim().isNotEmpty
                  ? settings['site']
                  : settings['siteweb'] ?? '')
              .toString()
              .trim(),
      companySlogan: (settings['slogan'] ?? '').toString().trim(),
    );
  }
}

/// Chargeur d'images PNG des templates (mémoïsé pour ne pas relire l'asset
/// plusieurs fois lors du même rendu).
class CoverImageLoader {
  static final Map<String, pw.MemoryImage?> _cache = {};

  static Future<pw.MemoryImage?> load(String assetPath) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath];
    try {
      final data = await rootBundle.load(assetPath);
      final img = pw.MemoryImage(data.buffer.asUint8List());
      _cache[assetPath] = img;
      return img;
    } catch (_) {
      _cache[assetPath] = null;
      return null;
    }
  }
}

/// Renderer principal : sélectionne le bon builder selon le template choisi.
///
/// API "pré-built" : on charge les assets en amont (async) puis on renvoie un
/// `pw.Widget` que le builder synchrone de `pw.Page` peut retourner tel quel.
class CoverRenderer {
  /// Pré-charge l'image PNG du template (si applicable) et renvoie le widget
  /// couverture prêt à l'emploi pour une page de dimensions [pageFormat].
  static Future<pw.Widget> buildForFormat({
    required CoverTemplate template,
    required PdfPageFormat pageFormat,
    required CoverData data,
    pw.ImageProvider? logo,
  }) async {
    if (template == CoverTemplate.classic) {
      // Le classique est dessiné via `PdfService._buildCoverPage` (vectoriel,
      // dépend du `pw.Context` réel). Ce renderer n'a rien à fabriquer ici.
      return pw.Container(color: PdfColors.white);
    }

    final assetPath = template.assetPath!;
    final bg = await CoverImageLoader.load(assetPath);
    final w = pageFormat.width;
    final h = pageFormat.height;

    switch (template) {
      case CoverTemplate.orientalOrange:
        return _OrientalOrange.build(w, h, data, logo, bg);
      case CoverTemplate.corporateNavyGold:
        return _CorporateNavyGold.build(w, h, data, logo, bg);
      case CoverTemplate.blackGoldLuxe:
        return _BlackGoldLuxe.build(w, h, data, logo, bg);
      case CoverTemplate.navyGeometric:
        return _NavyGeometric.build(w, h, data, logo, bg);
      case CoverTemplate.navyArabesque:
        return _NavyArabesque.build(w, h, data, logo, bg);
      case CoverTemplate.minimalistGold:
        return _MinimalistGold.build(w, h, data, logo, bg);
      case CoverTemplate.classic:
        return pw.Container();
    }
  }
}

// ============================================================================
// Helpers communs
// ============================================================================

class _T {
  /// Police pro (lazy hookup possible vers Google Fonts si besoin).
  static pw.TextStyle style({
    double size = 11,
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

String _formatDateFr(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Bloc client compact : nom (gros, gras), société, adresse, tél, email.
/// Aligné à gauche, chaque ligne sur une seule ligne (pas de wrap).
/// Utilisé sur les templates où il y a une "icon column" prête à recevoir.
pw.Widget _clientLines(
  CoverData data, {
  required PdfColor labelColor,
  required PdfColor inkColor,
  double size = 9,
  double gap = 13,
  double lineWidth = 200,
}) {
  final lines = <_ClientLine>[];
  if (data.clientNom.isNotEmpty) {
    lines.add(_ClientLine(value: data.clientNom.toUpperCase(), bold: true));
  }
  if (data.clientSociete.isNotEmpty) {
    lines.add(_ClientLine(value: data.clientSociete));
  }
  if (data.clientAdresse.isNotEmpty) {
    lines.add(_ClientLine(value: data.clientAdresse));
  }
  if (data.clientTel.isNotEmpty) {
    lines.add(_ClientLine(value: data.clientTel));
  }
  if (data.clientEmail.isNotEmpty) {
    lines.add(_ClientLine(value: data.clientEmail));
  }
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final l in lines)
        pw.Padding(
          padding: pw.EdgeInsets.only(bottom: gap),
          child: pw.SizedBox(
            width: lineWidth,
            child: pw.Text(
              l.value,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: _T.style(
                size: l.bold ? size + 1 : size,
                color: l.bold ? inkColor : labelColor,
                bold: l.bold,
              ),
            ),
          ),
        ),
    ],
  );
}

class _ClientLine {
  final String value;
  final bool bold;
  _ClientLine({required this.value, this.bold = false});
}

/// Texte centré "DEVIS" / "FACTURE" sous lequel se place le numéro + date.
/// Variant moderne : titre énorme, traits or de chaque côté.
pw.Widget _titleBlock({
  required String label,
  required String numero,
  required DateTime date,
  String? subtitle,
  required PdfColor titleColor,
  required PdfColor accent,
  required PdfColor mutedColor,
  double titleSize = 44,
  pw.CrossAxisAlignment align = pw.CrossAxisAlignment.start,
  pw.TextAlign textAlign = pw.TextAlign.left,
}) {
  return pw.Column(
    crossAxisAlignment: align,
    children: [
      // Surtitre
      pw.Text(
        label,
        textAlign: textAlign,
        style: _T.style(
          size: titleSize,
          color: titleColor,
          bold: true,
          letterSpacing: 6,
          height: 1.0,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Container(width: 42, height: 2, color: accent),
      pw.SizedBox(height: 14),
      pw.Text(
        'N° $numero',
        textAlign: textAlign,
        style: _T.style(
          size: 12,
          color: titleColor,
          bold: true,
          letterSpacing: 1,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        _formatDateFr(date),
        textAlign: textAlign,
        style: _T.style(size: 10, color: mutedColor, letterSpacing: 0.4),
      ),
      if (subtitle != null && subtitle.isNotEmpty) ...[
        pw.SizedBox(height: 18),
        pw.SizedBox(
          width: 280,
          child: pw.Text(
            subtitle,
            textAlign: textAlign,
            style: _T.style(
              size: 12,
              color: titleColor,
              italic: true,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: pw.TextOverflow.clip,
          ),
        ),
      ],
    ],
  );
}

/// Pose une carte logo + nom société dans un petit cadre (top-right des
/// templates qui réservent une zone).
pw.Widget _logoCard({
  required pw.ImageProvider? logo,
  required String name,
  required PdfColor textColor,
  required double width,
  required double height,
  PdfColor? bg,
}) {
  return pw.Container(
    width: width,
    height: height,
    padding: const pw.EdgeInsets.all(6),
    color: bg,
    child: pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null)
          pw.Container(
            constraints: pw.BoxConstraints(
              maxHeight: height * 0.55,
              maxWidth: width - 14,
            ),
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
        if (name.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            name,
            textAlign: pw.TextAlign.center,
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
            style: _T.style(
              size: 8,
              color: textColor,
              bold: true,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ],
    ),
  );
}

// ============================================================================
// 1. ORIENTAL ORANGE (f1bd15ce) — PNG 1055 × 1491 px
// ============================================================================
//
// Placement en coordonnées **pixels du fichier**, projetées avec la même
// mise à l’échelle que l’image (`contain`). Évite le décalage de `cover`.
// ============================================================================

class _OrientalOrange {
  static const double _tw = 1055;
  static const double _th = 1491;

  static const _gold = PdfColor.fromInt(0xFFC9A227);
  static const _ink = PdfColor.fromInt(0xFF1A1510);
  static const _muted = PdfColor.fromInt(0xFF4A4036);

  static pw.TextStyle _times(
    double pt, {
    PdfColor? color,
    double ls = 0,
    double height = 1.05,
  }) {
    return pw.TextStyle(
      fontStyle: pw.FontStyle.normal,
      font: pw.Font.helveticaBold(),
      fontSize: pt,
      color: color ?? _ink,
      letterSpacing: 2,
      height: height,
    );
  }

  static pw.TextStyle _helv(
    double pt, {
    bool bold = false,
    PdfColor? color,
    double ls = 0,
    double height = 1.15,
    bool italic = false,
  }) {
    return pw.TextStyle(
      font: bold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
      fontSize: pt,
      color: color ?? _ink,
      letterSpacing: ls,
      height: height,
      fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
    );
  }

  static double _textPt(double layoutScale, double targetPt) =>
      math.max(7.5, targetPt * layoutScale / (595 / _tw));

  /// Ligne cahier : « Libellé : valeur » sur **une seule** ligne, puis pointillés.
  static pw.Widget _orientalClientField({
    required double layoutScale,
    required String label,
    required String value,
    required bool valueBold,
    required double valueFontPt,
    required double lineHeight,
  }) {
    final dotted = String.fromCharCodes(List.generate(280, (_) => 0x00B7));
    final lineCol = PdfColor.fromInt(0xFF6E6E6E);
    const black = PdfColors.black;
    final labelPt = valueFontPt * 0.9;
    final dotPt = math.max(4.0, valueFontPt * 0.34);

    return pw.Column(
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
                text: '$label : ',
                style: pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  fontSize: labelPt,
                  color: black,
                  height: 1.05,
                ),
              ),
              pw.TextSpan(
                text: value,
                style: pw.TextStyle(
                  font: valueBold
                      ? pw.Font.helveticaBold()
                      : pw.Font.helvetica(),
                  fontSize: valueFontPt,
                  color: black,
                  height: lineHeight,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4 * layoutScale),
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
    );
  }

  static pw.Widget build(
    double w,
    double h,
    CoverData data,
    pw.ImageProvider? logo,
    pw.MemoryImage? bg,
  ) {
    final layoutScale = math.min(w / _tw, h / _th);
    final ox = (w - _tw * layoutScale) / 2;
    final oy = (h - _th * layoutScale) / 2;

    /// Zone utile plaque dorée **droite** (calée sur le PNG).
    /// DEVIS/FACTURE : ancré au **bord droit réel de la plaque** (coords page),
    /// sans Row/Expanded — le moteur pdf est ainsi stable quel que soit le texte.
    const plaqueW = 418.0;

    /// Zone logo plaque dorée (px gabarit 1055×1491). Plus grand = logo affiché plus grand (BoxFit.contain).
    const plaqueLogoSlotPx = 230.0;
    const plaqueLogoBelowGapPx = 10.0;

    const refWidth = 360.0;

    /// Objet — champ blanc central-gauche (largeur utile).
    const objWidth = 490.0;

    /// Bloc infos client (largeur utile).
    const cliWidth = 780.0;

    /// Espace vertical entre chaque ligne « cahier » client (px gabarit).
    const cliFieldGapPx = 12.0;

    final ptDisp = _textPt(layoutScale, 76);
    final ptRefBold = _textPt(layoutScale, 13);
    final ptRef = _textPt(layoutScale, 11.5);
    final ptObjLbl = _textPt(layoutScale, 9);
    final ptObj = _textPt(layoutScale, 12);

    pw.Widget plaqueDocBannerColumn() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          data.documentLabel,
          textAlign: pw.TextAlign.right,
          style: _times(ptDisp, ls: 5.5, height: 1.0),
        ),
        pw.SizedBox(height: 8 * layoutScale),
        pw.Container(
          width: 400 * layoutScale,
          height: 2.5 * layoutScale,
          color: _gold,
        ),
      ],
    );

    return pw.SizedBox(
      width: w,
      height: h,
      child: pw.Stack(
        children: [
          if (bg != null)
            pw.Positioned(
              left: ox,
              top: oy,
              child: pw.SizedBox(
                width: _tw * layoutScale,
                height: _th * layoutScale,
                child: pw.Image(bg, fit: pw.BoxFit.fill),
              ),
            ),
          pw.Positioned(
            left: 190,
            top: 20,
            child: pw.Row(
              children: [
                //reduction de l'opacité de l'image de fond
                pw.Opacity(
                  opacity: 0.1,
                  child: pw.Text(
                    'N',
                    style: pw.TextStyle(color: _ink, fontSize: 50),
                  ),
                ),
                pw.Opacity(
                  opacity: 0.1,
                  child: pw.Text(
                    'G',
                    style: pw.TextStyle(color: PdfColors.red, fontSize: 50),
                  ),
                ),
                pw.Opacity(
                  opacity: 0.1,
                  child: pw.Text(
                    'DEVIS',
                    style: pw.TextStyle(color: _ink, fontSize: 50),
                  ),
                ),
              ],
            ),
          ),
          pw.Positioned(
            left: 170,
            top: 80,
            child: pw.SizedBox(
              width: plaqueW * layoutScale,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logo != null)
                    pw.SizedBox(
                      width: plaqueW * layoutScale,
                      height: plaqueLogoSlotPx * layoutScale,
                      child: pw.Center(
                        child: pw.Image(logo, fit: pw.BoxFit.contain),
                      ),
                    ),
                  if (logo != null)
                    pw.SizedBox(height: plaqueLogoBelowGapPx * layoutScale),
                  if (data.companyName.trim().isNotEmpty)
                    pw.Padding(
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: 14 * layoutScale,
                      ),
                      /*  child: pw.Text(
                        data.companyName.trim().toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                        style: _helv(20, bold: true, ls: 1.25, height: 1.12),
                      ), */
                    ),
                ],
              ),
            ),
          ),
          //orientalisme
          pw.Positioned(
            //top: docBannerTop,
            top: 217.5,
            //right: docBannerRightFromStackEdge,
            left: 100,
            child: plaqueDocBannerColumn(),
          ),

          pw.Positioned(
            left: 430,
            top: 100.5,
            child: pw.SizedBox(
              width: refWidth * layoutScale,
              child: pw.Text(
                'N° ${data.numero}',
                style: _helv(ptRefBold, bold: true, ls: 1.1, height: 1.05),
              ),
            ),
          ),
          pw.Positioned(
            left: 450,
            top: 125.5,
            child: pw.SizedBox(
              width: refWidth * layoutScale,
              child: pw.Text(
                _formatDateFr(data.date),
                style: _helv(ptRef, color: _muted, height: 1.1),
              ),
            ),
          ),

          if (data.titre != null && data.titre!.trim().isNotEmpty)
            pw.Positioned(
              left: 60,
              top: 350,
              child: pw.SizedBox(
                width: objWidth * layoutScale,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'OBJET',
                      style: _helv(
                        ptObjLbl,
                        bold: true,
                        color: _muted,
                        ls: 2.2,
                        height: 1.0,
                      ),
                    ),
                    pw.SizedBox(height: 5 * layoutScale),
                    pw.Text(
                      data.titre!.trim(),
                      style: _helv(ptObj, italic: true, height: 1.38),
                      maxLines: 4,
                      overflow: pw.TextOverflow.clip,
                    ),
                  ],
                ),
              ),
            ),

          // Infos client — texte seul (sans icônes), une ligne par champ + pointillés.
          pw.Positioned(
            left: 60,
            top: 400,
            child: pw.SizedBox(
              width: cliWidth * layoutScale,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _orientalClientField(
                    layoutScale: layoutScale,
                    label: 'Nom',
                    value: data.clientNom.trim().isNotEmpty
                        ? data.clientNom.trim().toUpperCase()
                        : '—',
                    valueBold: true,
                    valueFontPt: 24,
                    lineHeight: 1.1,
                  ),
                  pw.SizedBox(height: cliFieldGapPx * layoutScale),
                  _orientalClientField(
                    layoutScale: layoutScale,
                    label: 'Société',
                    value: data.clientSociete.trim().isNotEmpty
                        ? data.clientSociete.trim()
                        : '—',
                    valueBold: false,
                    valueFontPt: 22,
                    lineHeight: 1.1,
                  ),
                  pw.SizedBox(height: cliFieldGapPx * layoutScale),
                  _orientalClientField(
                    layoutScale: layoutScale,
                    label: 'Adresse',
                    value: data.clientAdresse.trim().isNotEmpty
                        ? data.clientAdresse.trim()
                        : '—',
                    valueBold: false,
                    valueFontPt: 22 * 0.92,
                    lineHeight: 1.15,
                  ),
                  pw.SizedBox(height: cliFieldGapPx * layoutScale),
                  _orientalClientField(
                    layoutScale: layoutScale,
                    label: 'Téléphone',
                    value: data.clientTel.trim().isNotEmpty
                        ? data.clientTel.trim()
                        : '—',
                    valueBold: false,
                    valueFontPt: 22,
                    lineHeight: 1.14,
                  ),
                  pw.SizedBox(height: cliFieldGapPx * layoutScale),
                  _orientalClientField(
                    layoutScale: layoutScale,
                    label: 'E-mail',
                    value: data.clientEmail.trim().isNotEmpty
                        ? data.clientEmail.trim()
                        : '—',
                    valueBold: false,
                    valueFontPt: 22,
                    lineHeight: 1.14,
                  ),
                ],
              ),
            ),
          ),

          if (data.companySlogan.trim().isNotEmpty)
            pw.Positioned(
              left: ox + 150 * layoutScale,
              top: oy + (_th - 78) * layoutScale,
              child: pw.SizedBox(
                width: (_tw - 280) * layoutScale,
                child: pw.Text(
                  data.companySlogan.trim(),
                  textAlign: pw.TextAlign.center,
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                  style: _helv(
                    _textPt(layoutScale, 10),
                    color: PdfColors.white,
                    italic: true,
                    height: 1.15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. CORPORATE NAVY GOLD (ChatGPT image)
// ============================================================================
//
// Le template a déjà du texte échantillon ("VOTRE ENTREPRISE", contacts).
// Stratégie : on **masque** ces zones avec des rectangles blancs/navy puis on
// pose les vraies infos par-dessus.
// ============================================================================

class _CorporateNavyGold {
  static const _navy = PdfColor.fromInt(0xFF0E1B3D);
  static const _gold = PdfColor.fromInt(0xFFB7892F);
  static const _ink = PdfColor.fromInt(0xFF111111);
  static const _muted = PdfColor.fromInt(0xFF5C5C5C);

  static pw.Widget build(
    double w,
    double h,
    CoverData data,
    pw.ImageProvider? logo,
    pw.MemoryImage? bg,
  ) {
    return pw.SizedBox(
      width: w,
      height: h,
      child: pw.Stack(
        children: [
          if (bg != null)
            pw.Positioned.fill(child: pw.Image(bg, fit: pw.BoxFit.cover)),
          // Masque la zone "VOTRE ENTREPRISE / SLOGAN" (cadre navy bas-droite)
          pw.Positioned(
            right: 70,
            top: 565,
            child: pw.Container(width: 180, height: 90, color: _navy),
          ),
          // Identité société (sur le cadre navy masqué)
          pw.Positioned(
            right: 70,
            top: 570,
            child: pw.Container(
              width: 180,
              height: 84,
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logo != null)
                    pw.Container(
                      constraints: const pw.BoxConstraints(
                        maxHeight: 32,
                        maxWidth: 150,
                      ),
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    ),
                  if (data.companyName.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text(
                      data.companyName.toUpperCase(),
                      textAlign: pw.TextAlign.center,
                      maxLines: 2,
                      style: _T.style(
                        size: 10,
                        color: _gold,
                        bold: true,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                  if (data.companySlogan.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      data.companySlogan,
                      textAlign: pw.TextAlign.center,
                      maxLines: 1,
                      style: _T.style(
                        size: 7,
                        color: PdfColors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Cadre or top-right (vide) → on ne touche pas, sert d'élément de design.
          // Titre central (à gauche)
          pw.Positioned(
            left: 55,
            top: 220,
            child: _titleBlock(
              label: data.documentLabel,
              numero: data.numero,
              date: data.date,
              subtitle: data.titre,
              titleColor: _navy,
              accent: _gold,
              mutedColor: _muted,
            ),
          ),
          // Masque la bande footer "APPELEZ / ÉCRIVEZ / VISITEZ"
          pw.Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: pw.Container(height: 78, color: PdfColors.white),
          ),
          // Footer 3 colonnes (téléphone / email / site)
          pw.Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: pw.Container(
              height: 78,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 36,
                vertical: 14,
              ),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  begin: pw.Alignment.topCenter,
                  end: pw.Alignment.bottomCenter,
                  colors: [_navy, _navy],
                ),
                border: const pw.Border(
                  top: pw.BorderSide(color: _gold, width: 1.4),
                ),
              ),
              child: pw.Row(
                children: [
                  _footerItem(
                    'APPELEZ-NOUS',
                    data.companyTel.isEmpty ? '—' : data.companyTel,
                  ),
                  _footerSep(),
                  _footerItem(
                    'ÉCRIVEZ-NOUS',
                    data.companyEmail.isEmpty ? '—' : data.companyEmail,
                  ),
                  _footerSep(),
                  _footerItem(
                    'VISITEZ-NOUS',
                    data.companyWebsite.isEmpty
                        ? (data.companyAdresse.isEmpty
                              ? '—'
                              : data.companyAdresse)
                        : data.companyWebsite,
                  ),
                ],
              ),
            ),
          ),
          // Bloc client central (sur fond blanc — gauche, sous le titre)
          pw.Positioned(
            left: 55,
            top: 430,
            child: _clientLines(
              data,
              labelColor: _muted,
              inkColor: _ink,
              size: 9.5,
              gap: 5,
              lineWidth: 240,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footerItem(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            label,
            style: _T.style(
              size: 8,
              color: _gold,
              bold: true,
              letterSpacing: 1.6,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            maxLines: 2,
            textAlign: pw.TextAlign.center,
            style: _T.style(size: 9, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footerSep() {
    return pw.Container(
      width: 1,
      height: 30,
      color: _gold,
      margin: const pw.EdgeInsets.symmetric(horizontal: 18),
    );
  }
}

// ============================================================================
// 3. BLACK GOLD LUXE (c091b6e3)
// ============================================================================
//
// Zones libres :
// - Cadre or top-right (~ 420,55 — 530,165) → logo + société
// - Centre-haut large zone blanche → titre
// - Colonne icônes médian-gauche (~ 90,490 — 290,650) → 4 lignes client (pas
//   d'icône email -> on n'affiche que 4 lignes utiles + 1 fallback).
// ============================================================================

class _BlackGoldLuxe {
  static const _gold = PdfColor.fromInt(0xFFB7892F);
  static const _ink = PdfColor.fromInt(0xFF1A1A1A);
  static const _muted = PdfColor.fromInt(0xFF5A5A5A);

  static pw.Widget build(
    double w,
    double h,
    CoverData data,
    pw.ImageProvider? logo,
    pw.MemoryImage? bg,
  ) {
    return pw.SizedBox(
      width: w,
      height: h,
      child: pw.Stack(
        children: [
          if (bg != null)
            pw.Positioned.fill(child: pw.Image(bg, fit: pw.BoxFit.cover)),
          // Logo + société top-right (cadre or)
          pw.Positioned(
            right: 60,
            top: 70,
            child: _logoCard(
              logo: logo,
              name: data.companyName,
              textColor: _ink,
              width: 110,
              height: 95,
            ),
          ),
          // Titre central
          pw.Positioned(
            left: 60,
            top: 235,
            child: _titleBlock(
              label: data.documentLabel,
              numero: data.numero,
              date: data.date,
              subtitle: data.titre,
              titleColor: _ink,
              accent: _gold,
              mutedColor: _muted,
            ),
          ),
          // Bloc client (à côté des icônes médian-gauche)
          pw.Positioned(
            left: 130,
            top: 495,
            child: _clientLines(
              data,
              labelColor: _muted,
              inkColor: _ink,
              size: 9,
              gap: 16,
              lineWidth: 200,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. NAVY GEOMETRIC BUILDING (ac8f1c49)
// ============================================================================

class _NavyGeometric {
  static const _navy = PdfColor.fromInt(0xFF0F2A6A);
  static const _gold = PdfColor.fromInt(0xFFB7892F);
  static const _ink = PdfColor.fromInt(0xFF13183A);
  static const _muted = PdfColor.fromInt(0xFF5F6B82);

  static pw.Widget build(
    double w,
    double h,
    CoverData data,
    pw.ImageProvider? logo,
    pw.MemoryImage? bg,
  ) {
    return pw.SizedBox(
      width: w,
      height: h,
      child: pw.Stack(
        children: [
          if (bg != null)
            pw.Positioned.fill(child: pw.Image(bg, fit: pw.BoxFit.cover)),
          // Logo + société top-right (cadre or)
          pw.Positioned(
            right: 55,
            top: 65,
            child: _logoCard(
              logo: logo,
              name: data.companyName,
              textColor: _ink,
              width: 115,
              height: 95,
            ),
          ),
          // Titre principal — centre-gauche
          pw.Positioned(
            left: 55,
            top: 250,
            child: _titleBlock(
              label: data.documentLabel,
              numero: data.numero,
              date: data.date,
              subtitle: data.titre,
              titleColor: _navy,
              accent: _gold,
              mutedColor: _muted,
            ),
          ),
          // Bloc client : sous le titre, large
          pw.Positioned(
            left: 55,
            top: 470,
            child: _clientLines(
              data,
              labelColor: _muted,
              inkColor: _ink,
              size: 9.5,
              gap: 6,
              lineWidth: 240,
            ),
          ),
          // Footer compact (slogan + tel)
          if (data.companyTel.isNotEmpty)
            pw.Positioned(
              left: 55,
              bottom: 36,
              child: pw.Row(
                children: [
                  pw.Container(width: 18, height: 2, color: _gold),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    data.companyTel,
                    style: _T.style(size: 10, color: _navy, bold: true),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. NAVY ARABESQUE (267d2250)
// ============================================================================

class _NavyArabesque {
  static const _navy = PdfColor.fromInt(0xFF142654);
  static const _gold = PdfColor.fromInt(0xFFB7892F);
  static const _ink = PdfColor.fromInt(0xFF14213D);
  static const _muted = PdfColor.fromInt(0xFF5B6A8A);

  static pw.Widget build(
    double w,
    double h,
    CoverData data,
    pw.ImageProvider? logo,
    pw.MemoryImage? bg,
  ) {
    return pw.SizedBox(
      width: w,
      height: h,
      child: pw.Stack(
        children: [
          if (bg != null)
            pw.Positioned.fill(child: pw.Image(bg, fit: pw.BoxFit.cover)),
          // Logo + société top-right (cadre or, en haut du template)
          pw.Positioned(
            right: 60,
            top: 65,
            child: _logoCard(
              logo: logo,
              name: data.companyName,
              textColor: _ink,
              width: 110,
              height: 95,
            ),
          ),
          // Titre — centre légèrement à gauche
          pw.Positioned(
            left: 65,
            top: 245,
            child: _titleBlock(
              label: data.documentLabel,
              numero: data.numero,
              date: data.date,
              subtitle: data.titre,
              titleColor: _navy,
              accent: _gold,
              mutedColor: _muted,
            ),
          ),
          // Bloc client : aligné avec les icônes (colonne verticale gauche, bas)
          pw.Positioned(
            left: 115,
            top: 600,
            child: _clientLines(
              data,
              labelColor: _muted,
              inkColor: _ink,
              size: 9,
              gap: 13,
              lineWidth: 220,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. MINIMALIST BLACK & GOLD (0d1b09be)
// ============================================================================

class _MinimalistGold {
  static const _gold = PdfColor.fromInt(0xFFB7892F);
  static const _ink = PdfColor.fromInt(0xFF15171C);
  static const _muted = PdfColor.fromInt(0xFF5F636E);

  static pw.Widget build(
    double w,
    double h,
    CoverData data,
    pw.ImageProvider? logo,
    pw.MemoryImage? bg,
  ) {
    return pw.SizedBox(
      width: w,
      height: h,
      child: pw.Stack(
        children: [
          if (bg != null)
            pw.Positioned.fill(child: pw.Image(bg, fit: pw.BoxFit.cover)),
          // Logo + société top-right (cadre or fin)
          pw.Positioned(
            right: 60,
            top: 70,
            child: _logoCard(
              logo: logo,
              name: data.companyName,
              textColor: _ink,
              width: 115,
              height: 90,
            ),
          ),
          // Titre — milieu absolu
          pw.Positioned(
            left: 60,
            top: 280,
            child: _titleBlock(
              label: data.documentLabel,
              numero: data.numero,
              date: data.date,
              subtitle: data.titre,
              titleColor: _ink,
              accent: _gold,
              mutedColor: _muted,
            ),
          ),
          // Bloc client : sous le titre
          pw.Positioned(
            left: 60,
            top: 500,
            child: _clientLines(
              data,
              labelColor: _muted,
              inkColor: _ink,
              size: 9.5,
              gap: 6,
              lineWidth: 260,
            ),
          ),
          // Coordonnées société alignées à droite tout en bas
          pw.Positioned(
            right: 60,
            bottom: 70,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (data.companyTel.isNotEmpty)
                  pw.Text(
                    data.companyTel,
                    style: _T.style(size: 9, color: _muted),
                  ),
                if (data.companyEmail.isNotEmpty)
                  pw.Text(
                    data.companyEmail,
                    style: _T.style(size: 9, color: _muted),
                  ),
                if (data.companyWebsite.isNotEmpty)
                  pw.Text(
                    data.companyWebsite,
                    style: _T.style(size: 9, color: _gold, bold: true),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
