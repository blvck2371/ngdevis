import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../database/hive_storage.dart';
import '../models/devis.dart';
import '../models/devis_unit.dart';
import '../models/section_devis.dart';
import '../utils/app_currency.dart';
import 'cover/cover_renderer.dart';
import 'cover/cover_template.dart';

/// Génération du PDF du devis, calquée sur le modèle DEVIS ESTIMATIFS (NG, titre, NB, sections, totaux).
class PdfService {
  static const PdfColor red = PdfColor.fromInt(0xFFC62828);
  static const PdfColor lightGray = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor darkGray = PdfColor.fromInt(0xFF424242);

  /// Palette « document pro » (neutres + accent rouge sobre)
  static const PdfColor _ink = PdfColor.fromInt(0xFF263238);
  static const PdfColor _inkMuted = PdfColor.fromInt(0xFF546E7A);
  static const PdfColor _rule = PdfColor.fromInt(0xFFCFD8DC);
  static const PdfColor _pageBackground = PdfColor.fromInt(0xFFF2F4F6);
  static const PdfColor _watermarkColor = PdfColor.fromInt(0xFF9E9E9E);
  static const double _watermarkOpacity = 0.04;

  /// Page de couverture : maquette pixel-perfect (Stack + positions fixes, A4 plein).
  static final PdfPageFormat _coverPageFormat = PdfPageFormat.a4.copyWith(
    marginLeft: 0,
    marginRight: 0,
    marginTop: 0,
    marginBottom: 0,
  );

  static const double _cvM = 40; // marge page (inset fixe)
  static const double _cvHeaderY = 34;
  static const double _cvTitleY = 118;
  static const double _cvClientY =
      412; // bloc client bas (grand vide au centre)
  static const double _cvFooterBottom = 0;

  /// Couleurs strictes mockup.
  static const PdfColor _brandNavy = PdfColor.fromInt(0xFF001B4E);
  static const PdfColor _brandRed = PdfColor.fromInt(0xFFE30613);
  static const PdfColor _coverGrey = PdfColor.fromInt(0xFF757575);
  static const PdfColor _coverPanelGrey = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor _coverRuleSoft = PdfColor.fromInt(0xFFBDBDBD);

  /// Texte « informations client » : contraste renforcé sur la couverture.
  static const PdfColor _coverClientInk = PdfColor.fromInt(0xFF1A1A1A);
  static const PdfColor _coverClientLabel = PdfColor.fromInt(0xFF00142E);

  static final RegExp _coverDtuPattern = RegExp(
    r'DTU\s*60\.1',
    caseSensitive: false,
  );

  /// Construit le document PDF du devis avec la **couverture choisie**.
  /// Par défaut on garde le modèle historique (classique) pour
  /// rétrocompatibilité.
  static Future<pw.Document> buildDocument(
    Devis devis, {
    CoverTemplate template = CoverTemplate.classic,
  }) async {
    final doc = pw.Document();
    final logoImage = await _loadLogoForDevis(devis);
    final coverArt = await _loadCoverArt();
    final coverData = CoverData.fromDevis(devis);

    // Pré-build la couverture non-classique (loading asset async) pour
    // pouvoir la retourner depuis le builder synchrone de `pw.Page`.
    pw.Widget? preBuiltCover;
    if (template != CoverTemplate.classic) {
      preBuiltCover = await CoverRenderer.buildForFormat(
        template: template,
        pageFormat: _coverPageFormat,
        data: coverData,
        logo: logoImage,
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: _coverPageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          if (template == CoverTemplate.classic || preBuiltCover == null) {
            return _buildCoverPage(context, devis, logoImage, coverArt);
          }
          return preBuiltCover;
        },
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          buildBackground: (context) => _buildWatermarkLayer(context),
        ),
        build: (context) => [
          _buildInnerHeader(devis, logoImage),
          ..._buildAllSections(devis),
          _buildTotalGeneral(devis),
        ],
      ),
    );
    return doc;
  }

  /// Filigrane « NGDEVIS » en diagonale sur chaque page (arrière-plan, faible opacité).
  static pw.Widget _buildWatermarkLayer(pw.Context context) {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.Container(color: _pageBackground),
          ),
          pw.Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: pw.Container(
              height: 128,
              color: PdfColors.white,
            ),
          ),
          pw.Center(
            child: pw.Transform.rotate(
              angle: -math.pi / 4.5,
              child: pw.Opacity(
                opacity: _watermarkOpacity,
                child: pw.Text(
                  'NGDEVIS',
                  style: pw.TextStyle(
                    fontSize: 100,
                    fontWeight: pw.FontWeight.bold,
                    color: _watermarkColor,
                    letterSpacing: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Couverture A4 : Stack + coordonnées fixes (mockup).
  static pw.Widget _buildCoverPage(
    pw.Context context,
    Devis devis,
    pw.ImageProvider? logoImage,
    pw.ImageProvider? coverArt,
  ) {
    final fmt = context.page.pageFormat;
    final pageW = fmt.width;
    final pageH = fmt.height;
    final contentW = pageW - 2 * _cvM;
    const footerReserve = 126.0;

    final companyName = _headerCompanyName(devis, hasLogo: logoImage != null);
    final displayCompany = companyName.isEmpty ? 'NG Devis' : companyName;
    final tel = _headerTel(devis);
    final adresse = _headerAdresse(devis);
    final slogan = _headerSlogan();
    final emailCo = _companySetting('email');
    final siteCo = _companySetting('site').isNotEmpty
        ? _companySetting('site')
        : _companySetting('siteweb');

    return pw.SizedBox(
      width: pageW,
      height: pageH,
      child: pw.Stack(
        children: [
          if (coverArt != null)
            pw.Positioned(
              left: pageW * 0.50,
              top: 0,
              right: 0,
              bottom: 0,
              child: pw.Image(
                coverArt,
                fit: pw.BoxFit.cover,
                alignment: pw.Alignment.centerRight,
              ),
            ),
          pw.Positioned(
            right: -14,
            bottom: footerReserve,
            child: pw.Transform.rotate(
              angle: -0.11,
              child: pw.Container(width: 142, height: 86, color: _brandNavy),
            ),
          ),
          pw.Positioned(
            right: -5,
            bottom: footerReserve + 9,
            child: pw.Transform.rotate(
              angle: -0.095,
              child: pw.Container(width: 98, height: 27, color: _brandRed),
            ),
          ),
          pw.Positioned(
            left: -3,
            top: -2,
            child: pw.Transform.rotate(
              angle: -0.42,
              child: pw.Container(width: 38, height: 13, color: _brandNavy),
            ),
          ),
          pw.Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: pw.Center(
              child: pw.Opacity(
                opacity: 0.16,
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'N',
                        style: _cvFont(
                          28,
                          bold: true,
                          color: _brandNavy,
                          letterSpacing: 1.6,
                          height: 1.0,
                        ),
                      ),
                      pw.TextSpan(
                        text: 'G',
                        style: _cvFont(
                          28,
                          bold: true,
                          color: _brandRed,
                          letterSpacing: 1.6,
                          height: 1.0,
                        ),
                      ),
                      pw.TextSpan(
                        text: ' DEVIS',
                        style: _cvFont(
                          28,
                          bold: true,
                          color: _brandNavy,
                          letterSpacing: 1.6,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          pw.Positioned(
            left: _cvM,
            right: _cvM,
            bottom: _cvFooterBottom,
            child: _coverFooter(
              displayCompany: displayCompany,
              adresse: adresse,
              tel: tel,
              email: emailCo,
              site: siteCo,
              slogan: slogan,
              contentWidth: contentW,
            ),
          ),
          pw.Positioned(
            left: _cvM,
            top: _cvClientY,
            child: pw.SizedBox(width: 276, child: _coverClientSection(devis)),
          ),
          pw.Positioned(
            left: _cvM,
            top: _cvTitleY,
            child: pw.SizedBox(width: 312, child: _coverTitleSection(devis)),
          ),
          pw.Positioned(
            left: _cvM,
            top: _cvHeaderY,
            child: _coverBrandHeaderFixed(logoImage, displayCompany, slogan),
          ),
          pw.Positioned(
            right: _cvM,
            top: _cvHeaderY,
            child: _coverReferenceBox(devis),
          ),
        ],
      ),
    );
  }

  static pw.TextStyle _cvFont(
    double size, {
    bool bold = false,
    PdfColor? color,
    double? letterSpacing,
    double height = 1.15,
  }) {
    return pw.TextStyle(
      fontSize: size,
      font: bold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static pw.Widget _coverBrandHeaderFixed(
    pw.ImageProvider? logo,
    String companyName,
    String sloganLine,
  ) {
    final trimmedName = companyName.trim();
    final hasLongName = trimmedName.length > 5;
    final displayName = trimmedName.isEmpty ? 'Nom de la societe' : trimmedName;
    final shortNameUpper = displayName.toUpperCase();
    final tag = sloganLine.trim().isNotEmpty
        ? sloganLine.trim().toUpperCase()
        : 'VOTRE PARTENAIRE DE CONFIANCE';
    if (logo == null) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            shortNameUpper,
            style: _cvFont(
              28,
              bold: true,
              color: _brandNavy,
              letterSpacing: 0.2,
              height: 1,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            tag,
            style: _cvFont(
              7.6,
              color: _coverGrey,
              letterSpacing: 1.02,
              height: 1.1,
            ),
          ),
        ],
      );
    }

    if (hasLongName) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            height: 58,
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            displayName,
            style: _cvFont(
              18,
              bold: true,
              color: _brandNavy,
              letterSpacing: 0.1,
              height: 1.05,
            ),
            maxLines: 2,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            tag,
            style: _cvFont(
              7.6,
              color: _coverGrey,
              letterSpacing: 1.02,
              height: 1.1,
            ),
          ),
        ],
      );
    }

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 58,
          margin: const pw.EdgeInsets.only(right: 12),
          child: pw.Image(logo, fit: pw.BoxFit.contain),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              shortNameUpper,
              style: _cvFont(
                28,
                bold: true,
                color: _brandNavy,
                letterSpacing: 0.2,
                height: 1,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              tag,
              style: _cvFont(
                7.6,
                color: _coverGrey,
                letterSpacing: 1.02,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _coverReferenceBox(Devis devis) {
    return pw.Container(
      width: 124,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _coverPanelGrey,
        border: pw.Border.all(color: _rule, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'DEVIS ESTIMATIF',
            textAlign: pw.TextAlign.center,
            style: _cvFont(
              8,
              bold: true,
              color: _coverGrey,
              letterSpacing: 1.12,
              height: 1.1,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'N° ${devis.numero}',
            textAlign: pw.TextAlign.center,
            style: _cvFont(
              18,
              bold: true,
              color: _brandNavy,
              letterSpacing: 0.25,
              height: 1.05,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'DATE : ${_formatDateFr(devis.date)}',
            textAlign: pw.TextAlign.center,
            style: _cvFont(10, color: _brandNavy, height: 1.1),
          ),
        ],
      ),
    );
  }

  static String _coverClientValue(String? raw) {
    final t = raw?.trim() ?? '';
    return t.isEmpty ? '—' : t;
  }

  static pw.Widget _coverNoteRichText(String noteRaw) {
    final n = noteRaw.trim();
    if (n.isEmpty) return pw.SizedBox();
    final m = _coverDtuPattern.firstMatch(n);
    if (m != null) {
      final before = n.substring(0, m.start).trimRight();
      final dtuPart = m.group(0)!;
      final after = n.substring(m.end);
      return pw.RichText(
        text: pw.TextSpan(
          style: _cvFont(10.2, color: _coverGrey, height: 1.35),
          children: [
            if (before.isNotEmpty) pw.TextSpan(text: before),
            if (before.isNotEmpty)
              pw.TextSpan(
                text: ' ',
                style: _cvFont(10.2, color: _coverGrey, height: 1.35),
              ),
            pw.TextSpan(
              text: dtuPart,
              style: _cvFont(10.2, bold: true, color: _brandNavy, height: 1.35),
            ),
            if (after.isNotEmpty)
              pw.TextSpan(
                text: after,
                style: _cvFont(10.2, color: _coverGrey, height: 1.35),
              ),
          ],
        ),
      );
    }
    return pw.Text(n, style: _cvFont(10.2, color: _coverGrey, height: 1.35));
  }

  static pw.Widget _coverClientIcon(String letter) {
    return pw.Container(
      width: 15,
      height: 15,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: _brandNavy,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      child: pw.Text(
        letter,
        style: _cvFont(7.8, bold: true, color: PdfColors.white, height: 1),
      ),
    );
  }

  static pw.Widget _coverClientFieldRowFixed({
    required String? value,
    required String label,
    required String iconLetter,
    required double totalW,
    bool uppercaseValue = false,
  }) {
    const iconW = 15.0;
    const gap = 8.0;
    const labelW = 86.0;
    final valueW = totalW - iconW - gap - labelW;
    var display = _coverClientValue(value);
    if (uppercaseValue && display != '—') {
      display = display.toUpperCase();
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 11),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: _coverClientIcon(iconLetter),
          ),
          pw.SizedBox(width: gap),
          pw.SizedBox(
            width: labelW,
            child: pw.Text(
              label,
              style: _cvFont(
                8.5,
                bold: true,
                color: _coverClientLabel,
                height: 1.12,
              ),
            ),
          ),
          pw.SizedBox(
            width: valueW,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  display,
                  style: _cvFont(
                    10,
                    bold: uppercaseValue,
                    color: _coverClientInk,
                    height: 1.12,
                  ),
                  maxLines: 4,
                ),
                pw.SizedBox(height: 3),
                pw.Container(
                  height: 0.8,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: _coverRuleSoft, width: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _coverTitleSection(Devis devis) {
    final noteRaw = (devis.noteNb != null && devis.noteNb!.trim().isNotEmpty)
        ? devis.noteNb!.trim()
        : 'Nous travaillons selon la norme DTU 60.1';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DEVIS',
          style: _cvFont(
            54,
            bold: true,
            color: _brandNavy,
            letterSpacing: 1.2,
            height: 1,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Container(width: 54, height: 3.6, color: _brandRed),
        pw.SizedBox(height: 11),
        _coverNoteRichText(noteRaw),
        if (devis.titreDevis != null &&
            devis.titreDevis!.trim().isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text(
            devis.titreDevis!.trim(),
            style: _cvFont(10.5, bold: true, color: _brandNavy, height: 1.15),
          ),
        ],
      ],
    );
  }

  static pw.Widget _coverClientSection(Devis devis) {
    final cl = devis.client;
    const totalW = 276.0;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'INFORMATIONS DU CLIENT',
              style: _cvFont(
                8.5,
                bold: true,
                color: _brandRed,
                letterSpacing: 0.85,
                height: 1,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.Container(height: 1.35, color: _brandRed)),
          ],
        ),
        pw.SizedBox(height: 12),
        _coverClientFieldRowFixed(
          iconLetter: 'N',
          label: 'Nom du client',
          value: cl?.nom,
          totalW: totalW,
          uppercaseValue: true,
        ),
        _coverClientFieldRowFixed(
          iconLetter: 'S',
          label: 'Société',
          value: cl?.societe,
          totalW: totalW,
        ),
        _coverClientFieldRowFixed(
          iconLetter: 'A',
          label: 'Adresse',
          value: cl?.adresse,
          totalW: totalW,
        ),
        _coverClientFieldRowFixed(
          iconLetter: 'T',
          label: 'Téléphone',
          value: cl?.telephone,
          totalW: totalW,
        ),
        _coverClientFieldRowFixed(
          iconLetter: '@',
          label: 'Email',
          value: cl?.email,
          totalW: totalW,
        ),
      ],
    );
  }

  static pw.Widget _coverFooterContactLine(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        text,
        style: _cvFont(8.2, color: _coverGrey, height: 1.2),
        maxLines: 3,
      ),
    );
  }

  static pw.Widget _coverFooter({
    required String displayCompany,
    required String adresse,
    required String tel,
    required String email,
    required String site,
    required String slogan,
    required double contentWidth,
  }) {
    final about = slogan.trim().isNotEmpty
        ? slogan.trim()
        : 'NG Devis est une entreprise spécialisée dans les travaux de bâtiment et de génie civil. Nous vous accompagnons avec professionnalisme et qualité.';

    final footerName = displayCompany.toUpperCase();

    const gap = 8.0;
    const divW = 0.65;
    final inner = contentWidth - 3 * gap - 2 * divW;
    final col1 = inner * 5 / 14;
    final col2 = inner * 5 / 14;
    final col3 = inner * 4 / 14;

    return pw.Column(
      children: [
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _rule, width: 0.75)),
          ),
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: col1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      footerName,
                      style: _cvFont(
                        10,
                        bold: true,
                        color: _brandRed,
                        letterSpacing: 0.55,
                        height: 1.1,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    if (adresse.trim().isNotEmpty)
                      _coverFooterContactLine(adresse.trim()),
                    if (tel.trim().isNotEmpty)
                      _coverFooterContactLine(tel.trim()),
                    if (email.trim().isNotEmpty)
                      _coverFooterContactLine(email.trim()),
                    if (site.trim().isNotEmpty)
                      _coverFooterContactLine(site.trim()),
                  ],
                ),
              ),
              pw.SizedBox(width: gap),
              pw.Container(width: divW, height: 88, color: _rule),
              pw.SizedBox(width: gap),
              pw.SizedBox(
                width: col2,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 1),
                      child: _coverClientIcon('i'),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'À PROPOS DE NOUS',
                            style: _cvFont(
                              8.5,
                              bold: true,
                              color: _brandNavy,
                              letterSpacing: 0.5,
                              height: 1.08,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            about,
                            style: _cvFont(
                              8.2,
                              color: _coverGrey,
                              height: 1.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: gap),
              pw.Container(width: divW, height: 88, color: _rule),
              pw.SizedBox(width: gap),
              pw.SizedBox(
                width: col3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SIGNATURE & CACHET',
                      style: _cvFont(
                        8.3,
                        bold: true,
                        color: _brandNavy,
                        letterSpacing: 0.4,
                        height: 1.05,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      height: 52,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _rule, width: 1),
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Stack(
          children: [
            pw.Container(height: 5, color: _brandNavy),
            pw.Positioned(
              right: 0,
              bottom: 0,
              child: pw.Transform.rotate(
                angle: -math.pi / 4,
                origin: const PdfPoint(6, 6),
                child: pw.Container(width: 14, height: 14, color: _brandRed),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _companySetting(String key) {
    final v = HiveStorage.getCompanySettings()[key];
    return v?.trim() ?? '';
  }

  static Future<pw.ImageProvider?> _loadCoverArt() async {
    try {
      final data = await rootBundle.load(
        'assets/e175b1a5-7eef-4403-a781-493ba464ba89.png',
      );
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _formatDateFr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// En-tête pages de détail : bande sobre + rappel référence (sans refaire le bloc client).
  static pw.Widget _buildInnerHeader(Devis devis, pw.ImageProvider? logoImage) {
    final companyName = _headerCompanyName(devis, hasLogo: logoImage != null);
    final tel = _headerTel(devis);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 1)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Container(
                  height: 36,
                  margin: const pw.EdgeInsets.only(right: 12),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (companyName.isNotEmpty)
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                    if (tel.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        tel,
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: _inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'N° ${devis.numero}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _formatDateFr(devis.date),
                    style: const pw.TextStyle(fontSize: 8.5, color: _inkMuted),
                  ),
                ],
              ),
            ],
          ),
          if (devis.titreDevis != null &&
              devis.titreDevis!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              devis.titreDevis!.trim(),
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ],
          if (devis.noteNb != null && devis.noteNb!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'NB — ${devis.noteNb!.trim()}',
              style: const pw.TextStyle(fontSize: 8.5, color: _inkMuted),
            ),
          ],
        ],
      ),
    );
  }

  static List<pw.Widget> _buildAllSections(Devis devis) {
    final widgets = <pw.Widget>[];
    for (final section in devis.sections) {
      final titreSection = section.titre.toUpperCase();
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(
            titreSection,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
      widgets.add(_table(section));
      widgets.add(pw.SizedBox(height: 4));
      widgets.add(_totalMateriel(section));
      widgets.add(_mainOeuvre(section));
      widgets.add(_totalSection(section, titreSection));
      widgets.add(pw.SizedBox(height: 14));
    }
    return widgets;
  }

  static pw.Widget _table(SectionDevis section) {
    return pw.Table(
      border: pw.TableBorder(
        left: const pw.BorderSide(color: darkGray, width: 0.8),
        top: const pw.BorderSide(color: darkGray, width: 0.8),
        right: const pw.BorderSide(color: darkGray, width: 0.8),
        bottom: const pw.BorderSide(color: darkGray, width: 0.8),
        horizontalInside: const pw.BorderSide(color: darkGray, width: 0.5),
        verticalInside: const pw.BorderSide(color: darkGray, width: 0.5),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3.6),
        1: const pw.FlexColumnWidth(1.3),
        2: const pw.FlexColumnWidth(1.1),
        3: const pw.FlexColumnWidth(1.1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: lightGray),
          children: [
            _cell('DÉSIGNATION', bold: true, alignLeft: true),
            _cell('QTE', bold: true, alignRight: true),
            _cell('PU', bold: true, alignRight: true),
            _cell('PT', bold: true, alignRight: true),
          ],
        ),
        ...section.items.map(
          (item) => pw.TableRow(
            children: [
              _cell(item.designation, alignLeft: true),
              _cell(
                DevisUnit.formatQuantity(item.unit, item.quantite),
                alignRight: true,
              ),
              _cell(_formatPrice(item.prixUnitaire), alignRight: true),
              _cell(_formatPrice(item.total), alignRight: true),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _totalMateriel(SectionDevis section) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'TOTAL MATERIELLE ${_formatPrice(section.totalMateriel)}',
        style: pw.TextStyle(
          fontSize: 10,
          color: red,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _mainOeuvre(SectionDevis section) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        "MAIN D'OEUVRE${section.mainOeuvre > 0 ? ' ${_formatPrice(section.mainOeuvre)}' : ''}",
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static pw.Widget _totalSection(SectionDevis section, String titreSection) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'TOTAL $titreSection ${_formatPrice(section.totalSection)}',
        style: pw.TextStyle(
          fontSize: 10,
          color: red,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// Somme des totaux de section (sans la main d'œuvre manuelle globale).
  static double _subtotalSections(Devis devis) =>
      devis.sections.fold(0.0, (sum, s) => sum + s.totalSection);

  static pw.Widget _buildTotalGeneral(Devis devis) {
    final sub = _subtotalSections(devis);
    final showManual = devis.useManualMainOeuvre;
    final manual = devis.manualMainOeuvre < 0 ? 0.0 : devis.manualMainOeuvre;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            if (showManual) ...[
              pw.Text(
                'SOUS-TOTAL ${_formatPrice(sub)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                "MAIN D'OEUVRE MANUELLE ${_formatPrice(manual)}",
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 8),
            ],
            pw.Text(
              'TOTAL GÉNÉRAL ${_formatPrice(devis.total)}',
              style: pw.TextStyle(
                fontSize: 12,
                color: red,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    bool alignLeft = false,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Align(
        alignment: alignRight
            ? pw.Alignment.centerRight
            : (alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  static String _formatPrice(double value) {
    final s = value.toStringAsFixed(0);
    if (s.length <= 3) return '$s $kCurrencyLabel';
    final buf = StringBuffer();
    var i = s.length % 3;
    if (i == 0) i = 3;
    buf.write(s.substring(0, i));
    for (; i < s.length; i += 3) {
      buf.write(' ${s.substring(i, i + 3)}');
    }
    return '${buf.toString()} $kCurrencyLabel';
  }

  /// Nom affiché sous le logo (ou seul si pas de logo). Pas de texte de secours sous le logo seul.
  static String _headerCompanyName(Devis devis, {required bool hasLogo}) {
    final fromDevis = devis.nomEntreprise?.trim();
    if (fromDevis != null && fromDevis.isNotEmpty) return fromDevis;
    final hive = HiveStorage.getCompanySettings()['nom']?.trim();
    if (hive != null && hive.isNotEmpty) return hive;
    if (!hasLogo) return 'NG Devis';
    return '';
  }

  static String _headerSlogan() {
    return HiveStorage.getCompanySettings()['slogan']?.trim() ?? '';
  }

  static String _headerTel(Devis devis) {
    final t = devis.telEntreprise?.trim();
    if (t != null && t.isNotEmpty) return t;
    return HiveStorage.getCompanySettings()['telephone']?.trim() ?? '';
  }

  static String _headerAdresse(Devis devis) {
    final a = devis.adresseEntreprise?.trim();
    if (a != null && a.isNotEmpty) return a;
    return HiveStorage.getCompanySettings()['adresse']?.trim() ?? '';
  }

  static Future<pw.ImageProvider?> _loadLogoForDevis(Devis devis) async {
    final tried = <String>{};
    Future<pw.ImageProvider?> one(String? path) async {
      if (path == null || path.isEmpty) return null;
      if (tried.contains(path)) return null;
      tried.add(path);
      return _loadLogo(path);
    }

    final fromDevis = await one(devis.logoPath);
    if (fromDevis != null) return fromDevis;
    return one(HiveStorage.getCompanySettings()['logoPath']);
  }

  static Future<pw.ImageProvider?> _loadLogo(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return pw.MemoryImage(bytes);
      }
    } catch (_) {}
    return null;
  }

  /// Aperçu PDF (dialog).
  static Future<void> preview(
    Devis devis, {
    CoverTemplate template = CoverTemplate.classic,
  }) async {
    try {
      final doc = await buildDocument(devis, template: template);
      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF: ${e.toString()}');
    }
  }

  /// Export PDF vers fichier.
  static Future<File?> saveToFile(
    Devis devis, {
    String? name,
    CoverTemplate template = CoverTemplate.classic,
  }) async {
    final doc = await buildDocument(devis, template: template);
    final dir = await getApplicationDocumentsDirectory();
    final fileName = name ?? 'devis_${devis.numero}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  /// Partage PDF (share_plus).
  static Future<void> share(
    Devis devis, {
    CoverTemplate template = CoverTemplate.classic,
  }) async {
    final file = await saveToFile(devis, template: template);
    if (file != null && await file.exists()) {
      await Printing.sharePdf(
        bytes: await file.readAsBytes(),
        filename: file.path.split('/').last,
      );
    }
  }
}
