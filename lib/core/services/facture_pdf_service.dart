import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../database/hive_storage.dart';
import '../models/devis_unit.dart';
import '../models/facture.dart';
import '../models/facture_status.dart';
import '../models/payment.dart';
import '../models/section_devis.dart';
import '../utils/app_currency.dart';
import 'pdf_contract_page.dart';

/// Génération du PDF **Facture** — design pro, sobre, distinct du devis.
///
/// Différences clés visuelles :
///   - en-tête "FACTURE" (au lieu de "DEVIS") avec accent **or** discret ;
///   - bloc paiement complet (échéance, modalités, encaissements, restant) ;
///   - tampon "PAYÉ" en diagonale lorsque entièrement soldée.
class FacturePdfService {
  // Palette
  static const PdfColor _navy = PdfColor.fromInt(0xFF001B4E);
  static const PdfColor _ink = PdfColor.fromInt(0xFF263238);
  static const PdfColor _inkMuted = PdfColor.fromInt(0xFF546E7A);
  static const PdfColor _rule = PdfColor.fromInt(0xFFCFD8DC);
  static const PdfColor _ruleSoft = PdfColor.fromInt(0xFFE6E9EE);
  static const PdfColor _panel = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor _gold = PdfColor.fromInt(0xFFB7892F);
  static const PdfColor _goldSoft = PdfColor.fromInt(0xFFFBF1D8);
  static const PdfColor _success = PdfColor.fromInt(0xFF12A26F);
  static const PdfColor _warn = PdfColor.fromInt(0xFFC97A1A);
  static const PdfColor _errorColor = PdfColor.fromInt(0xFFE03853);

  // ========================================================================
  // API PUBLIQUE
  // ========================================================================

  static Future<void> preview(Facture f) async {
    final doc = await buildDocument(f);
    final bytes = await doc.save();
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  static Future<void> share(Facture f) async {
    final doc = await buildDocument(f);
    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final safeNum = f.numero.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    final file = File('${dir.path}/Facture_$safeNum.pdf');
    await file.writeAsBytes(bytes);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Facture_$safeNum.pdf',
    );
  }

  static Future<pw.Document> buildDocument(Facture f) async {
    final doc = pw.Document();
    final logo = await _loadLogo(f);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 36),
          buildBackground: f.status == FactureStatus.payee
              ? (ctx) => _paidStampBackground()
              : null,
        ),
        header: (ctx) => _header(f, logo),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 12),
          _identityBlock(f),
          pw.SizedBox(height: 18),
          _sectionsAndItems(f),
          pw.SizedBox(height: 14),
          _totalsBlock(f),
          pw.SizedBox(height: 18),
          _paymentBlock(f),
          if (f.payments.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _paymentHistory(f),
          ],
        ],
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
        ),
        build: (context) => _buildContractWidgets(f),
      ),
    );
    return doc;
  }

  static List<pw.Widget> _buildContractWidgets(Facture f) {
    final client = f.client;
    final settings = HiveStorage.getCompanySettings();
    final adresseEntreprise = (f.adresseEntreprise ?? '').trim().isNotEmpty
        ? f.adresseEntreprise!.trim()
        : (settings['adresse'] ?? '').toString().trim();
    return PdfContractPage.buildWidgets(
      documentLabel: 'FACTURE',
      numero: f.numero,
      date: f.date,
      companyName: _companyName(f),
      companyAdresse: adresseEntreprise,
      companyTel: _companyTel(f),
      clientNom: (client?.nom ?? '').trim(),
      clientSociete: (client?.societe ?? '').trim(),
      clientAdresse: (client?.adresse ?? '').trim(),
      clientTel: (client?.telephone ?? '').trim(),
      objet: f.titreFacture,
      totalLabel: _money(f.total),
      validUntil: f.dueDate,
    );
  }

  // ========================================================================
  // HEADER
  // ========================================================================

  static pw.Widget _header(Facture f, pw.ImageProvider? logo) {
    final companyName = _companyName(f);
    final tag = _companyTag();
    final emailCo = _companySetting('email');
    final telCo = _companyTel(f);

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 14),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 1)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // BRAND
          if (logo != null)
            pw.Container(
              height: 54,
              margin: const pw.EdgeInsets.only(right: 12),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyName.toUpperCase(),
                  style: _font(18, bold: true, color: _navy, letterSpacing: 0.2),
                ),
                if (tag.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    tag.toUpperCase(),
                    style: _font(7.4, color: _inkMuted, letterSpacing: 1),
                  ),
                ],
                pw.SizedBox(height: 6),
                pw.Wrap(
                  spacing: 14,
                  runSpacing: 2,
                  children: [
                    if (telCo.isNotEmpty) _miniInfo('Tel.', telCo),
                    if (emailCo.isNotEmpty) _miniInfo('Email', emailCo),
                  ],
                ),
              ],
            ),
          ),
          // RÉFÉRENCE FACTURE
          pw.Container(
            width: 168,
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: pw.BoxDecoration(
              color: _panel,
              border: pw.Border.all(color: _rule, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'FACTURE',
                      style: _font(9, bold: true, color: _navy, letterSpacing: 1.4),
                    ),
                    pw.SizedBox(width: 6),
                    _statusPillPdf(f.status),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  f.numero,
                  style: _font(16, bold: true, color: _navy, letterSpacing: 0.3),
                ),
                pw.SizedBox(height: 4),
                pw.Container(width: 36, height: 2, color: _gold),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Émise le ${_dateFr(f.date)}',
                  style: _font(8.4, color: _inkMuted),
                ),
                if (f.dueDate != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Échéance : ${_dateFr(f.dueDate!)}',
                    style: _font(8.4, color: f.isOverdue ? _errorColor : _inkMuted, bold: f.isOverdue),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _miniInfo(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label  ',
            style: _font(7.8, bold: true, color: _navy, letterSpacing: 0.5),
          ),
          pw.TextSpan(text: value, style: _font(8.6, color: _ink)),
        ],
      ),
    );
  }

  // ========================================================================
  // IDENTITÉ FACTURÉE
  // ========================================================================

  static pw.Widget _identityBlock(Facture f) {
    final client = f.client;
    final lines = <String>[
      if (client?.societe.trim().isNotEmpty ?? false) client!.societe.trim(),
      if (client?.adresse.trim().isNotEmpty ?? false) client!.adresse.trim(),
      if (client?.telephone.trim().isNotEmpty ?? false) 'Tél. ${client!.telephone.trim()}',
      if (client?.email.trim().isNotEmpty ?? false) client!.email.trim(),
    ];
    final nom = (client?.nom.trim() ?? '').isEmpty ? '-' : client!.nom.trim();

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _ruleSoft, width: 0.8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FACTURÉ À',
                  style: _font(8, bold: true, color: _navy, letterSpacing: 1.4),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  nom.toUpperCase(),
                  style: _font(15, bold: true, color: _ink, letterSpacing: 0.2),
                ),
                if (lines.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    lines.join('\n'),
                    style: _font(10, color: _inkMuted, height: 1.45),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          // Détails facture (modalités, n°, etc.)
          pw.Container(
            width: 200,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _panel,
              border: pw.Border.all(color: _ruleSoft, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _kv('N° facture', f.numero),
                _kv('Date', _dateFr(f.date)),
                if (f.dueDate != null) _kv('Échéance', _dateFr(f.dueDate!)),
                if (f.devisSourceId != null) _kv('Issue du devis', 'Oui'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _kv(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              k,
              style: _font(7.8, bold: true, color: _navy, letterSpacing: 0.5),
            ),
          ),
          pw.Expanded(
            child: pw.Text(v, style: _font(9, color: _ink)),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // SECTIONS + ITEMS
  // ========================================================================

  static pw.Widget _sectionsAndItems(Facture f) {
    if (f.sections.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          color: _panel,
          border: pw.Border.all(color: _ruleSoft, width: 0.8),
        ),
        child: pw.Text(
          'Aucun article facturé.',
          style: _font(10, color: _inkMuted),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (final s in f.sections) ...[
          _sectionTable(s),
          pw.SizedBox(height: 10),
        ],
      ],
    );
  }

  static pw.Widget _sectionTable(SectionDevis section) {
    final headerStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Titre section
        if (section.titre.trim().isNotEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: _navy,
            child: pw.Text(
              section.titre.toUpperCase(),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ),
        // Header
        pw.Container(
          color: _navy,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 6, child: pw.Text('Désignation', style: headerStyle)),
              pw.Expanded(flex: 2, child: pw.Text('Qté', style: headerStyle, textAlign: pw.TextAlign.right)),
              pw.Expanded(flex: 2, child: pw.Text('Unité', style: headerStyle, textAlign: pw.TextAlign.center)),
              pw.Expanded(flex: 3, child: pw.Text('PU', style: headerStyle, textAlign: pw.TextAlign.right)),
              pw.Expanded(flex: 3, child: pw.Text('Total', style: headerStyle, textAlign: pw.TextAlign.right)),
            ],
          ),
        ),
        // Rows
        for (var i = 0; i < section.items.length; i++)
          pw.Container(
            color: i % 2 == 0 ? PdfColors.white : _panel,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 6,
                  child: pw.Text(section.items[i].designation, style: _font(9.4, color: _ink)),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    DevisUnit.formatQuantity(
                      section.items[i].unit,
                      section.items[i].quantite,
                    ),
                    style: _font(9.4, color: _ink),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    section.items[i].unit.symbole,
                    style: _font(9, color: _inkMuted),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    _money(section.items[i].prixUnitaire),
                    style: _font(9.4, color: _ink),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    _money(section.items[i].total),
                    style: _font(9.4, color: _ink, bold: true),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        // Main d'œuvre
        if (section.mainOeuvre > 0)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _goldSoft,
              border: pw.Border.all(color: _rule, width: 0.5),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    section.mainOeuvrePercent > 0
                        ? 'Main d\'œuvre (${section.mainOeuvrePercent.toStringAsFixed(0)} %)'
                        : 'Main d\'œuvre',
                    style: _font(9, bold: true, color: _navy),
                  ),
                ),
                pw.Text(
                  _money(section.mainOeuvre),
                  style: _font(9, bold: true, color: _navy),
                ),
              ],
            ),
          ),
        // Sous-total section
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _rule, width: 1)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Sous-total ', style: _font(9, color: _inkMuted)),
              pw.Text(
                _money(section.totalSection),
                style: _font(10, bold: true, color: _navy),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========================================================================
  // TOTAUX
  // ========================================================================

  static pw.Widget _totalsBlock(Facture f) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _navy,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MONTANT TOTAL À RÉGLER',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Toutes taxes comprises',
                  style: pw.TextStyle(
                    color: PdfColors.white.shade(0.3),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            _money(f.total),
            style: pw.TextStyle(
              color: _goldSoft,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // BLOC PAIEMENT
  // ========================================================================

  static pw.Widget _paymentBlock(Facture f) {
    final paid = f.totalPaid;
    final remaining = f.remaining;
    final ratio = f.paidRatio;
    final isPaid = f.status == FactureStatus.payee;
    final terms = f.paymentTerms.trim();

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _ruleSoft, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            children: [
              pw.Text(
                'PAIEMENT',
                style: _font(9, bold: true, color: _navy, letterSpacing: 1.4),
              ),
              pw.Spacer(),
              _statusPillPdf(f.status),
            ],
          ),
          pw.SizedBox(height: 8),
          // Barre de progression
          pw.Stack(
            children: [
              pw.Container(
                height: 8,
                decoration: pw.BoxDecoration(
                  color: _panel,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
              ),
              pw.Container(
                height: 8,
                width: 480 * ratio,
                decoration: pw.BoxDecoration(
                  color: isPaid ? _success : _gold,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _paymentStat('Total facture', _money(f.total), _ink),
              _paymentStat('Encaissé', _money(paid), _success),
              _paymentStat(
                isPaid ? 'Soldée' : 'Restant dû',
                _money(remaining),
                isPaid ? _success : _gold,
              ),
            ],
          ),
          if (terms.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _goldSoft,
                border: pw.Border.all(color: _gold, width: 0.4),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Modalités  ',
                    style: _font(8.4, bold: true, color: _navy, letterSpacing: 0.8),
                  ),
                  pw.Expanded(
                    child: pw.Text(terms, style: _font(9.2, color: _ink, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _paymentStat(String label, String value, PdfColor valueColor) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label.toUpperCase(),
              style: _font(7.6, bold: true, color: _inkMuted, letterSpacing: 1)),
          pw.SizedBox(height: 2),
          pw.Text(value,
              style: _font(13, bold: true, color: valueColor, letterSpacing: -0.2)),
        ],
      ),
    );
  }

  // ========================================================================
  // HISTORIQUE DES PAIEMENTS
  // ========================================================================

  static pw.Widget _paymentHistory(Facture f) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _ruleSoft, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'ENCAISSEMENTS',
            style: _font(9, bold: true, color: _navy, letterSpacing: 1.4),
          ),
          pw.SizedBox(height: 8),
          // Header
          pw.Container(
            color: _panel,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 3, child: pw.Text('Date', style: _font(8, bold: true, color: _navy))),
                pw.Expanded(flex: 3, child: pw.Text('Mode', style: _font(8, bold: true, color: _navy))),
                pw.Expanded(flex: 4, child: pw.Text('Référence', style: _font(8, bold: true, color: _navy))),
                pw.Expanded(flex: 3, child: pw.Text('Montant', style: _font(8, bold: true, color: _navy), textAlign: pw.TextAlign.right)),
              ],
            ),
          ),
          for (final p in f.payments)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: _ruleSoft, width: 0.5)),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text(_dateFr(p.date), style: _font(8.6, color: _ink))),
                  pw.Expanded(flex: 3, child: pw.Text(p.method.label, style: _font(8.6, color: _ink))),
                  pw.Expanded(flex: 4, child: pw.Text(p.reference.isEmpty ? '-' : p.reference, style: _font(8.6, color: _inkMuted))),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      _money(p.amount),
                      style: _font(9, bold: true, color: _success),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ========================================================================
  // BADGE STATUT
  // ========================================================================

  static pw.Widget _statusPillPdf(FactureStatus s) {
    PdfColor bg;
    PdfColor fg;
    switch (s) {
      case FactureStatus.payee:
        bg = _success;
        fg = PdfColors.white;
        break;
      case FactureStatus.enRetard:
        bg = _errorColor;
        fg = PdfColors.white;
        break;
      case FactureStatus.partiellementPayee:
        bg = _warn;
        fg = PdfColors.white;
        break;
      case FactureStatus.envoyee:
        bg = _navy;
        fg = PdfColors.white;
        break;
      case FactureStatus.annulee:
        bg = _inkMuted;
        fg = PdfColors.white;
        break;
      case FactureStatus.brouillon:
        bg = _panel;
        fg = _inkMuted;
        break;
    }
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        s.label.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 7.4,
          color: fg,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ========================================================================
  // TAMPON PAYÉ (background)
  // ========================================================================

  static pw.Widget _paidStampBackground() {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Center(
        child: pw.Transform.rotate(
          angle: -math.pi / 6,
          child: pw.Opacity(
            opacity: 0.08,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _success, width: 6),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                'PAYÉ',
                style: pw.TextStyle(
                  fontSize: 130,
                  fontWeight: pw.FontWeight.bold,
                  color: _success,
                  letterSpacing: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // FOOTER
  // ========================================================================

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _rule, width: 0.6)),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'Document généré par NG Devis',
            style: _font(7.4, color: _inkMuted, letterSpacing: 0.4),
          ),
          pw.Spacer(),
          pw.Text(
            'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: _font(7.4, color: _inkMuted, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // UTILITAIRES
  // ========================================================================

  static pw.TextStyle _font(
    double size, {
    bool bold = false,
    PdfColor? color,
    double? letterSpacing,
    double height = 1.2,
  }) {
    return pw.TextStyle(
      fontSize: size,
      font: bold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static String _dateFr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _money(double v) {
    final s = v.toStringAsFixed(0);
    String digits;
    if (s.length <= 3) {
      digits = s;
    } else {
      final buf = StringBuffer();
      var i = s.length % 3;
      if (i == 0) i = 3;
      buf.write(s.substring(0, i));
      for (; i < s.length; i += 3) {
        buf.write(' ${s.substring(i, i + 3)}');
      }
      digits = buf.toString();
    }
    return '$digits $kCurrencyPdfLabel';
  }

  // ========================================================================
  // CHARGEMENT LOGO + INFOS ENTREPRISE
  // ========================================================================

  static String _companyName(Facture f) {
    final fromFacture = (f.nomEntreprise ?? '').trim();
    if (fromFacture.isNotEmpty) return fromFacture;
    final fromSettings = HiveStorage.getCompanySettings();
    final n = (fromSettings['nom'] ?? '').trim();
    return n.isEmpty ? 'NG Devis' : n;
  }

  static String _companyTel(Facture f) {
    final fromFacture = (f.telEntreprise ?? '').trim();
    if (fromFacture.isNotEmpty) return fromFacture;
    final fromSettings = HiveStorage.getCompanySettings();
    final tel = (fromSettings['telephone'] ?? fromSettings['tel'] ?? '').trim();
    return tel;
  }

  static String _companyTag() {
    final s = HiveStorage.getCompanySettings();
    final tag = (s['slogan'] ?? '').trim();
    return tag;
  }

  static String _companySetting(String key) {
    final s = HiveStorage.getCompanySettings();
    return (s[key] ?? '').trim();
  }

  static Future<pw.ImageProvider?> _loadLogo(Facture f) async {
    try {
      final path = (f.logoPath ?? '').trim();
      if (path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return pw.MemoryImage(bytes);
        }
      }
      final settings = HiveStorage.getCompanySettings();
      final settingsLogo =
          (settings['logoPath'] ?? settings['logo'] ?? '').trim();
      if (settingsLogo.isNotEmpty) {
        final file = File(settingsLogo);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return pw.MemoryImage(bytes);
        }
      }
      // Fallback : asset par défaut
      try {
        final data = await rootBundle.load('assets/logo.png');
        return pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}
