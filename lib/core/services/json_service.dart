import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../models/designation.dart';

/// Import / export JSON des catégories et désignations.
/// Format : { "categories": ["Plomberie", ...], "designations": [{ "id", "nom", "prixUnitaire", "categorie" }, ...] }
class JsonService {
  /// Charge un fichier JSON et retourne (catégories, désignations).
  static Future<({List<String> categories, List<Designation> designations})?> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final bytes = result.files.single.bytes;
    if (bytes == null) return null;
    try {
      final content = utf8.decode(bytes);
      final map = jsonDecode(content) as Map<String, dynamic>?;
      if (map == null) return null;
      final categories = <String>[];
      if (map['categories'] is List) {
        for (final e in map['categories'] as List) {
          final s = e?.toString().trim();
          if (s != null && s.isNotEmpty) categories.add(s);
        }
      }
      final designations = <Designation>[];
      if (map['designations'] is List) {
        for (final e in map['designations'] as List) {
          if (e is! Map) continue;
          try {
            designations.add(Designation.fromJson(Map<String, dynamic>.from(e)));
          } catch (_) {}
        }
      }
      return (categories: categories, designations: designations);
    } catch (_) {
      return null;
    }
  }

  /// Exporte catégories et désignations en JSON (format lisible).
  static String exportToJson(List<String> categories, List<Designation> designations) {
    final map = <String, dynamic>{
      'categories': categories,
      'designations': designations.map((d) => d.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
