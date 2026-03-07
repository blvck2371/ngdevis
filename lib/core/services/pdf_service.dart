import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/client.dart';
import '../models/devis.dart';
import '../models/section_devis.dart';

/// Génération du PDF du devis, calquée sur le modèle DEVIS ESTIMATIFS (NG, titre, NB, sections, totaux).
class PdfService {
  static const PdfColor red = PdfColor.fromInt(0xFFC62828);
  static const PdfColor lightGray = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor darkGray = PdfColor.fromInt(0xFF424242);

  /// Construit le document PDF du devis.
  static Future<pw.Document> buildDocument(Devis devis) async {
    final doc = pw.Document();
    final logoImage = await _loadLogo(devis.logoPath);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildHeader(devis, logoImage),
          ..._buildAllSections(devis),
          _buildTotalGeneral(devis),
        ],
      ),
    );
    return doc;
  }

  /// En-tête type modèle : marque centrée (NG / logo), slogan rouge, titre devis, NB, TEL.
  static pw.Widget _buildHeader(Devis devis, pw.ImageProvider? logoImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Center(
          child: logoImage != null
              ? pw.Container(
                  height: 50,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                )
              : pw.Text(
                  devis.nomEntreprise != null && devis.nomEntreprise!.isNotEmpty
                      ? devis.nomEntreprise!
                      : 'NG',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            'NEW DEGENERETION',
            style: pw.TextStyle(fontSize: 11, color: red),
          ),
        ),
        pw.SizedBox(height: 12),
        if (devis.titreDevis != null && devis.titreDevis!.isNotEmpty)
          pw.Center(
            child: pw.Text(
              devis.titreDevis!.toUpperCase(),
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
        pw.SizedBox(height: 8),
        if (devis.noteNb != null && devis.noteNb!.isNotEmpty)
          pw.Text(
            'NB : ${devis.noteNb}',
            style: pw.TextStyle(fontSize: 10, color: red),
          ),
        if (devis.telEntreprise != null && devis.telEntreprise!.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text('TEL : ${devis.telEntreprise}', style: const pw.TextStyle(fontSize: 10)),
          ),
        if (devis.adresseEntreprise != null && devis.adresseEntreprise!.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(devis.adresseEntreprise!, style: const pw.TextStyle(fontSize: 10)),
          ),
        pw.SizedBox(height: 8),
        if (devis.client != null) _buildClientBlock(devis.client!),
        if (devis.client != null) pw.SizedBox(height: 8),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _buildClientBlock(Client client) {
    final nom = client.nom.trim();
    final tel = client.telephone.trim();
    final adresse = client.adresse.trim();
    if (nom.isEmpty && tel.isEmpty && adresse.isEmpty) return pw.SizedBox.shrink();
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: darkGray, width: 0.5),
        color: lightGray,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('CLIENT', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          if (nom.isNotEmpty) pw.Text(nom, style: const pw.TextStyle(fontSize: 10)),
          if (tel.isNotEmpty) pw.Text('Tél : $tel', style: const pw.TextStyle(fontSize: 10)),
          if (adresse.isNotEmpty) pw.Text(adresse, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildAllSections(Devis devis) {
    final widgets = <pw.Widget>[];
    for (final section in devis.sections) {
      final titreSection = section.titre.toUpperCase();
      widgets.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          titreSection,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ));
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
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(0.9),
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
        ...section.items.map((item) => pw.TableRow(
              children: [
                _cell(item.designation, alignLeft: true),
                _cell(_formatQuantite(item.quantite), alignRight: true),
                _cell(_formatPrice(item.prixUnitaire), alignRight: true),
                _cell(_formatPrice(item.total), alignRight: true),
              ],
            )),
      ],
    );
  }

  static pw.Widget _totalMateriel(SectionDevis section) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'TOTAL MATERIELLE ${_formatPrice(section.totalMateriel)}',
        style: pw.TextStyle(fontSize: 10, color: red, fontWeight: pw.FontWeight.bold),
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
        style: pw.TextStyle(fontSize: 10, color: red, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildTotalGeneral(Devis devis) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'TOTAL GÉNÉRAL ${_formatPrice(devis.total)}',
          style: pw.TextStyle(fontSize: 12, color: red, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static pw.Widget _cell(String text, {bool bold = false, bool alignLeft = false, bool alignRight = false}) {
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

  static String _formatQuantite(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  static String _formatPrice(double value) {
    final s = value.toStringAsFixed(0);
    if (s.length <= 3) return '$s F';
    final buf = StringBuffer();
    var i = s.length % 3;
    if (i == 0) i = 3;
    buf.write(s.substring(0, i));
    for (; i < s.length; i += 3) {
      buf.write(' ${s.substring(i, i + 3)}');
    }
    return '${buf.toString()} F';
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
  static Future<void> preview(Devis devis) async {
    final doc = await buildDocument(devis);
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  /// Export PDF vers fichier.
  static Future<File?> saveToFile(Devis devis, {String? name}) async {
    final doc = await buildDocument(devis);
    final dir = await getApplicationDocumentsDirectory();
    final fileName = name ?? 'devis_${devis.numero}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  /// Partage PDF (share_plus).
  static Future<void> share(Devis devis) async {
    final file = await saveToFile(devis);
    if (file != null && await file.exists()) {
      await Printing.sharePdf(bytes: await file.readAsBytes(), filename: file.path.split('/').last);
    }
  }
}
