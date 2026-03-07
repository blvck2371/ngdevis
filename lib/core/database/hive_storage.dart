import 'package:hive_flutter/hive_flutter.dart';
import '../models/designation.dart';
import '../models/devis.dart';

/// Clé des boxes Hive.
class HiveKeys {
  static const designations = 'designations';
  static const devis = 'devis';
  static const company = 'company';
  static const lastDevisNumber = 'last_devis_number';
  static const categoriesList = 'categories_list';
}

/// Stockage local Hive pour désignations, devis et paramètres entreprise.
class HiveStorage {
  static Box<dynamic>? _designationsBox;
  static Box<dynamic>? _devisBox;
  static Box<dynamic>? _prefsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _designationsBox = await Hive.openBox(HiveKeys.designations);
    _devisBox = await Hive.openBox(HiveKeys.devis);
    _prefsBox = await Hive.openBox('prefs');
  }

  // ——— Désignations ———
  static List<Designation> getDesignations() {
    final list = _designationsBox?.get('list') as List<dynamic>? ?? [];
    return list
        .map((e) => Designation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveDesignations(List<Designation> list) async {
    await _designationsBox?.put(
        'list', list.map((e) => e.toJson()).toList());
  }

  static Future<void> addDesignation(Designation d) async {
    final list = getDesignations();
    list.add(d);
    await saveDesignations(list);
  }

  static Future<void> updateDesignation(int index, Designation d) async {
    final list = getDesignations();
    if (index >= 0 && index < list.length) {
      list[index] = d;
      await saveDesignations(list);
    }
  }

  static Future<void> removeDesignationAt(int index) async {
    final list = getDesignations();
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await saveDesignations(list);
    }
  }

  // ——— Devis ———
  static List<Devis> getDevisList() {
    final list = _devisBox?.get('list') as List<dynamic>? ?? [];
    return list
        .map((e) => Devis.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveDevisList(List<Devis> list) async {
    await _devisBox?.put('list', list.map((e) => e.toJson()).toList());
  }

  static Future<void> addDevis(Devis d) async {
    final list = getDevisList();
    list.insert(0, d);
    await saveDevisList(list);
  }

  static Future<void> updateDevis(String id, Devis d) async {
    final list = getDevisList();
    final i = list.indexWhere((e) => e.id == id);
    if (i >= 0) {
      list[i] = d;
      await saveDevisList(list);
    }
  }

  static Future<void> removeDevis(String id) async {
    final list = getDevisList();
    list.removeWhere((e) => e.id == id);
    await saveDevisList(list);
  }

  static Devis? getDevisById(String id) {
    try {
      return getDevisList().firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // ——— Numéro de devis ———
  static int getLastDevisNumber() {
    return _prefsBox?.get(HiveKeys.lastDevisNumber) as int? ?? 0;
  }

  static Future<void> setLastDevisNumber(int n) async {
    await _prefsBox?.put(HiveKeys.lastDevisNumber, n);
  }

  // ——— Paramètres entreprise (pour formulaire par défaut) ———
  static Map<String, String> getCompanySettings() {
    final raw = _prefsBox?.get(HiveKeys.company);
    if (raw is Map) return Map<String, String>.from(raw);
    return {};
  }

  static Future<void> saveCompanySettings(Map<String, String> map) async {
    await _prefsBox?.put(HiveKeys.company, map);
  }

  // ——— Catégories (liste créée par l'utilisateur) ———
  static List<String> getCategories() {
    final raw = _prefsBox?.get(HiveKeys.categoriesList);
    if (raw is List) return List<String>.from(raw.map((e) => e.toString()));
    return [];
  }

  static Future<void> saveCategories(List<String> categories) async {
    await _prefsBox?.put(HiveKeys.categoriesList, categories);
  }

  static Future<void> addCategory(String name) async {
    final cat = name.trim();
    if (cat.isEmpty) return;
    final list = getCategories();
    if (list.any((c) => c.toLowerCase() == cat.toLowerCase())) return;
    list.add(cat);
    list.sort();
    await saveCategories(list);
  }

  static Future<void> removeCategory(String name) async {
    final list = getCategories();
    list.removeWhere((c) => c.trim().toLowerCase() == name.trim().toLowerCase());
    await saveCategories(list);
  }

  /// Renomme une catégorie et met à jour toutes les désignations qui l'utilisent.
  /// Retourne false si le nouveau nom existe déjà ou est invalide.
  static Future<bool> renameCategory(String oldName, String newName) async {
    final oldTrim = oldName.trim();
    final newTrim = newName.trim();
    if (oldTrim.isEmpty || newTrim.isEmpty || oldTrim.toLowerCase() == newTrim.toLowerCase()) return false;
    final catList = getCategories();
    final oldIdx = catList.indexWhere((c) => c.trim().toLowerCase() == oldTrim.toLowerCase());
    if (oldIdx < 0) return false;
    if (catList.any((c) => c.trim().toLowerCase() == newTrim.toLowerCase())) return false;
    catList[oldIdx] = newTrim;
    catList.sort();
    await saveCategories(catList);
    final designations = getDesignations();
    var changed = false;
    for (final d in designations) {
      if (d.categorie.trim().toLowerCase() == oldTrim.toLowerCase()) {
        d.categorie = newTrim;
        changed = true;
      }
    }
    if (changed) await saveDesignations(designations);
    return true;
  }

  /// Réinitialise toute l'application : catégories, désignations, devis, paramètres entreprise, numéro devis.
  static Future<void> resetAll() async {
    await saveDesignations([]);
    await saveDevisList([]);
    await saveCategories([]);
    await saveCompanySettings({});
    await setLastDevisNumber(0);
  }
}
