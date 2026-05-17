import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../database/hive_storage.dart';
import '../models/designation.dart';
import '../models/devis.dart';
import '../models/facture.dart';
import 'numbering_service.dart';

/// Sauvegarde et restauration complètes : catégories, désignations, devis,
/// **factures**, paramètres entreprise, **numérotation pro** et compteurs.
///
/// Format **v2** (depuis CHANTIER 1 — Workflow facturation).
/// Les anciennes sauvegardes v1 restent restaurables : les nouveaux champs
/// (factures, compteurs pro) sont alors ignorés / mis à zéro.
class BackupService {
  static const int backupVersion = 2;
  static const String backupFileName = 'ngdevis_sauvegarde';

  /// Exporte tout dans un seul JSON.
  static Map<String, dynamic> exportAll() {
    final categories = HiveStorage.getCategories();
    final designations = HiveStorage.getDesignations();
    final devisList = HiveStorage.getDevisList();
    final factures = HiveStorage.getFactureList();
    final company = HiveStorage.getCompanySettings();
    final lastDevisNumber = HiveStorage.getLastDevisNumber();
    final numCfg = HiveStorage.getNumberingConfig();

    return {
      'version': backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories,
      'designations': designations.map((d) => d.toJson()).toList(),
      'devis': devisList.map((d) => d.toJson()).toList(),
      'factures': factures.map((f) => f.toJson()).toList(),
      'company': company,
      'lastDevisNumber': lastDevisNumber,
      'numberingConfig': numCfg.toJson(),
      'numberingCounters': {
        'devis_count': HiveStorage.getNumberingLastCount(NumberingService.devisType),
        'devis_year': HiveStorage.getNumberingLastYear(NumberingService.devisType),
        'facture_count': HiveStorage.getNumberingLastCount(NumberingService.factureType),
        'facture_year': HiveStorage.getNumberingLastYear(NumberingService.factureType),
      },
    };
  }

  static String exportToJsonString() {
    final data = exportAll();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Boîte de dialogue "Enregistrer sous" (Android + iOS).
  static Future<String?> saveToPhoneFolder() async {
    final jsonStr = exportToJsonString();
    final bytes = utf8.encode(jsonStr);
    final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final fileName = '${backupFileName}_$dateStr.json';

    final savePath = await FilePicker.saveFile(
      dialogTitle: 'Enregistrer la sauvegarde - Choisir le dossier et le nom du fichier',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
    return savePath != null && savePath.isNotEmpty ? savePath : null;
  }

  static Future<BackupImportResult> importFromFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty || result.files.single.path == null) {
      return BackupImportResult(cancelled: true);
    }
    final path = result.files.single.path!;
    final content = await File(path).readAsString();
    final map = jsonDecode(content);
    if (map is! Map) throw const FormatException('Fichier JSON invalide');
    final data = Map<String, dynamic>.from(map);

    final version = data['version'] as int? ?? 1;
    if (version > backupVersion) {
      throw const FormatException('Version de sauvegarde non supportée');
    }

    int categoriesCount = 0;
    int designationsCount = 0;
    int devisCount = 0;
    int facturesCount = 0;

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

    if (data['factures'] is List) {
      final list = <Facture>[];
      for (final e in data['factures'] as List) {
        if (e is! Map) continue;
        try {
          list.add(Facture.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
      await HiveStorage.saveFactureList(list);
      facturesCount = list.length;
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

    if (data['numberingConfig'] is Map) {
      final cfg = NumberingConfig.fromJson(
        Map<String, dynamic>.from(data['numberingConfig'] as Map),
      );
      await HiveStorage.setNumberingConfig(cfg);
    }

    if (data['numberingCounters'] is Map) {
      final counters = Map<String, dynamic>.from(data['numberingCounters'] as Map);
      if (counters['devis_count'] is num) {
        await HiveStorage.setNumberingLastCount(
          NumberingService.devisType,
          (counters['devis_count'] as num).toInt(),
        );
      }
      if (counters['devis_year'] is num) {
        await HiveStorage.setNumberingLastYear(
          NumberingService.devisType,
          (counters['devis_year'] as num).toInt(),
        );
      }
      if (counters['facture_count'] is num) {
        await HiveStorage.setNumberingLastCount(
          NumberingService.factureType,
          (counters['facture_count'] as num).toInt(),
        );
      }
      if (counters['facture_year'] is num) {
        await HiveStorage.setNumberingLastYear(
          NumberingService.factureType,
          (counters['facture_year'] as num).toInt(),
        );
      }
    }

    return BackupImportResult(
      cancelled: false,
      categoriesCount: categoriesCount,
      designationsCount: designationsCount,
      devisCount: devisCount,
      facturesCount: facturesCount,
    );
  }
}

class BackupImportResult {
  final bool cancelled;
  final int categoriesCount;
  final int designationsCount;
  final int devisCount;
  final int facturesCount;

  BackupImportResult({
    this.cancelled = false,
    this.categoriesCount = 0,
    this.designationsCount = 0,
    this.devisCount = 0,
    this.facturesCount = 0,
  });
}
