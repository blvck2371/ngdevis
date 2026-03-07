import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../models/designation.dart';

/// Import / export CSV des désignations.
/// Format : nom,prixUnitaire,categorie
class CsvService {
  static const utf8Bom = '\uFEFF';

  /// Importe un fichier CSV et retourne la liste des désignations.
  /// Colonnes attendues : nom, prixUnitaire, categorie (ou prix_unitaire selon cas).
  static Future<List<Designation>> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return [];
    final bytes = result.files.single.bytes;
    if (bytes == null) return [];
    String content = utf8.decode(bytes);
    if (content.startsWith(utf8Bom)) content = content.substring(utf8Bom.length);
    return parseCsvContent(content);
  }

  static List<Designation> parseCsvContent(String content) {
    const idPrefix = 'csv_';
    final rows = const CsvToListConverter().convert(content);
    if (rows.isEmpty) return [];
    final header = (rows.first as List<dynamic>).map((e) => (e ?? '').toString().trim().toLowerCase()).toList();
    final nomIdx = _indexOf(header, ['nom', 'designation']);
    final puIdx = _indexOf(header, ['prixunitaire', 'prix_unitaire', 'pu', 'prix']);
    final catIdx = _indexOf(header, ['categorie', 'category', 'section']);
    if (nomIdx < 0 || puIdx < 0) return [];

    final list = <Designation>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i] as List<dynamic>;
      if (row.length <= nomIdx || row.length <= puIdx) continue;
      final nom = (row[nomIdx] ?? '').toString().trim();
      if (nom.isEmpty) continue;
      final pu = _parseDouble((row[puIdx] ?? '').toString());
      final categorie = catIdx >= 0 && row.length > catIdx
          ? (row[catIdx] ?? '').toString().trim()
          : '';
      list.add(Designation(
        id: '${idPrefix}${DateTime.now().millisecondsSinceEpoch}_$i',
        nom: nom,
        prixUnitaire: pu,
        categorie: categorie.isEmpty ? '' : categorie,
      ));
    }
    return list;
  }

  static int _indexOf(List<String> header, List<String> names) {
    for (var i = 0; i < header.length; i++) {
      final h = header[i].replaceAll(' ', '');
      if (names.any((n) => h.contains(n) || n.contains(h))) return i;
    }
    return -1;
  }

  static double _parseDouble(String s) {
    s = s.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(s) ?? 0;
  }

  /// Exporte la liste des désignations en CSV (UTF-8 avec BOM pour Excel).
  static String exportToCsv(List<Designation> list) {
    const header = ['nom', 'prixUnitaire', 'categorie'];
    final rows = [
      header,
      ...list.map((d) => [d.nom, d.prixUnitaire.toString(), d.categorie]),
    ];
    return utf8Bom + const ListToCsvConverter().convert(rows);
  }
}
