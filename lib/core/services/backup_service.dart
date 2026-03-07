import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../database/hive_storage.dart';
import '../models/designation.dart';
import '../models/devis.dart';

/// Sauvegarde et restauration complètes : catégories, désignations, historique des devis, paramètres entreprise.
class BackupService {
  static const int backupVersion = 1;
  static const String backupFileName = 'ngdevis_sauvegarde';

  /// Exporte tout en un seul JSON (catégories, désignations, devis, entreprise, numéro devis).
  static Map<String, dynamic> exportAll() {
    final categories = HiveStorage.getCategories();
    final designations = HiveStorage.getDesignations();
    final devisList = HiveStorage.getDevisList();
    final company = HiveStorage.getCompanySettings();
    final lastDevisNumber = HiveStorage.getLastDevisNumber();

    return {
      'version': backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories,
      'designations': designations.map((d) => d.toJson()).toList(),
      'devis': devisList.map((d) => d.toJson()).toList(),
      'company': company,
      'lastDevisNumber': lastDevisNumber,
    };
  }

  /// Génère le JSON formaté pour export fichier.
  static String exportToJsonString() {
    final data = exportAll();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Enregistre la sauvegarde : dialogue "Enregistrer sous" (le plugin écrit le fichier à l'emplacement choisi).
  /// Sur Android, ne pas utiliser getDirectoryPath() car il renvoie une URI content:// qu'on ne peut pas écrire avec File().
  static Future<String?> saveToPhoneFolder() async {
    final jsonStr = exportToJsonString();
    final bytes = utf8.encode(jsonStr);
    final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final fileName = '${backupFileName}_$dateStr.json';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Enregistrer la sauvegarde - Choisir le dossier et le nom du fichier',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
    return savePath != null && savePath.isNotEmpty ? savePath : null;
  }

  /// Importe tout depuis un fichier JSON. Retourne un résumé ou lance une exception.
  static Future<BackupImportResult> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty || result.files.single.path == null) {
      return BackupImportResult(cancelled: true);
    }
    final path = result.files.single.path!;
    final content = await File(path).readAsString();
    final map = jsonDecode(content);
    if (map is! Map) throw FormatException('Fichier JSON invalide');
    final data = Map<String, dynamic>.from(map);

    final version = data['version'] as int? ?? 1;
    if (version > backupVersion) throw FormatException('Version de sauvegarde non supportée');

    int categoriesCount = 0;
    int designationsCount = 0;
    int devisCount = 0;

    if (data['categories'] is List) {
      final list = (data['categories'] as List).map((e) => e.toString()).toList();
      await HiveStorage.saveCategories(list);
      categoriesCount = list.length;
    }

    if (data['designations'] is List) {
      final list = <Designation>[];
      for (final e in data['designations'] as List) {
        if (e is! Map) continue;
        try {
          list.add(Designation.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
      await HiveStorage.saveDesignations(list);
      designationsCount = list.length;
    }

    if (data['devis'] is List) {
      final list = <Devis>[];
      for (final e in data['devis'] as List) {
        if (e is! Map) continue;
        try {
          list.add(Devis.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
      await HiveStorage.saveDevisList(list);
      devisCount = list.length;
    }

    if (data['company'] is Map) {
      final company = Map<String, String>.from(
        (data['company'] as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
      );
      await HiveStorage.saveCompanySettings(company);
    }

    if (data['lastDevisNumber'] is num) {
      await HiveStorage.setLastDevisNumber((data['lastDevisNumber'] as num).toInt());
    }

    return BackupImportResult(
      cancelled: false,
      categoriesCount: categoriesCount,
      designationsCount: designationsCount,
      devisCount: devisCount,
    );
  }
}

class BackupImportResult {
  final bool cancelled;
  final int categoriesCount;
  final int designationsCount;
  final int devisCount;

  BackupImportResult({
    this.cancelled = false,
    this.categoriesCount = 0,
    this.designationsCount = 0,
    this.devisCount = 0,
  });
}
