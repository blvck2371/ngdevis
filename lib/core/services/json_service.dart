import 'dart:convert';
import 'dart:io' show File;
import 'package:file_picker/file_picker.dart';
import '../models/designation.dart';
import '../models/devis.dart';

/// Import / export JSON des catégories et désignations.
/// Format : { "categories": ["Plomberie", ...], "designations": [{ "id", "nom", "prixUnitaire", "categorie" }, ...] }
///
/// Import d’un **devis** seul : voir [pickDevisJsonFile] / [parseDevisFromJsonString].
class JsonService {
  static const utf8Bom = '\uFEFF';

  /// Charge un fichier JSON et retourne (catégories, désignations).
  static Future<({List<String> categories, List<Designation> designations})?> importFromFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    String? content;
    final bytes = file.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      content = utf8.decode(bytes);
    } else {
      final path = file.path;
      if (path != null && path.isNotEmpty) {
        content = await File(path).readAsString();
      }
    }
    if (content == null) return null;
    if (content.startsWith(utf8Bom)) {
      content = content.substring(utf8Bom.length);
    }
    try {
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

  /// Boîte de dialogue : **null** = annulation ou fichier illisible sans chemin ni octets.
  static Future<Devis?> pickDevisJsonFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    String? content;
    final bytes = file.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      content = utf8.decode(bytes);
    } else {
      final path = file.path;
      if (path != null && path.isNotEmpty) {
        content = await File(path).readAsString();
      }
    }
    if (content == null) return null;
    if (content.startsWith(utf8Bom)) {
      content = content.substring(utf8Bom.length);
    }
    return parseDevisFromJsonString(content);
  }

  /// Décode un export **devis seul** ([Devis.toJson]), ou la clé `devis`
  /// d’une sauvegarde ([BackupService]) : objet unique ou premier élément d’une liste.
  static Devis parseDevisFromJsonString(String content) {
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      throw const FormatException('Le fichier doit contenir un objet JSON');
    }
    final map = Map<String, dynamic>.from(decoded);
    Map<String, dynamic> root;
    if (_mapLooksLikeDevisRoot(map)) {
      root = map;
    } else if (map['devis'] is Map) {
      root = Map<String, dynamic>.from(map['devis'] as Map);
    } else if (map['devis'] is List) {
      final list = map['devis'] as List<dynamic>;
      if (list.isEmpty) {
        throw const FormatException('Liste "devis" vide dans le JSON');
      }
      final first = list.first;
      if (first is! Map) {
        throw const FormatException('Entrée "devis" invalide');
      }
      root = Map<String, dynamic>.from(first);
    } else {
      throw FormatException(
        'JSON non reconnu : attendu un devis (champs numero, date, sections, …) '
        'ou une sauvegarde avec une clé "devis".',
      );
    }
    return Devis.fromJson(root);
  }

  static bool _mapLooksLikeDevisRoot(Map<String, dynamic> m) {
    return m.containsKey('numero') &&
        m.containsKey('date') &&
        m.containsKey('id') &&
        m['sections'] is List;
  }
}
