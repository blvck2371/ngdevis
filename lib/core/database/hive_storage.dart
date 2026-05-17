import 'package:hive_flutter/hive_flutter.dart';
import '../models/designation.dart';
import '../models/devis.dart';
import '../models/facture.dart';
import '../services/numbering_service.dart';

/// Clés des boxes / préférences Hive.
class HiveKeys {
  static const designations = 'designations';
  static const devis = 'devis';
  static const factures = 'factures';
  static const company = 'company';
  static const lastDevisNumber = 'last_devis_number';
  static const categoriesList = 'categories_list';

  /// Préférences UI persistées (thème, onboarding…).
  static const themeMode = 'ui_theme_mode';
  static const onboardingSeen = 'ui_onboarding_seen';
  static const coverTemplateId = 'pdf_cover_template_id';

  /// Numérotation (préfixes, reset annuel, padding).
  static const numberingConfig = 'numbering_config';
  static const numberingCountPrefix = 'numbering_count_';
  static const numberingYearPrefix = 'numbering_year_';
}

/// Stockage local Hive pour désignations, devis, factures et paramètres.
class HiveStorage {
  static Box<dynamic>? _designationsBox;
  static Box<dynamic>? _devisBox;
  static Box<dynamic>? _facturesBox;
  static Box<dynamic>? _prefsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _designationsBox = await Hive.openBox(HiveKeys.designations);
    _devisBox = await Hive.openBox(HiveKeys.devis);
    _facturesBox = await Hive.openBox(HiveKeys.factures);
    _prefsBox = await Hive.openBox('prefs');
  }

  // ——— Désignations ———————————————————————————————————————————————————
  static List<Designation> getDesignations() {
    final list = _designationsBox?.get('list') as List<dynamic>? ?? [];
    return list
        .map((e) => Designation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveDesignations(List<Designation> list) async {
    await _designationsBox?.put('list', list.map((e) => e.toJson()).toList());
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

  // ——— Devis ——————————————————————————————————————————————————————————
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

  // ——— Factures ——————————————————————————————————————————————————————
  static List<Facture> getFactureList() {
    final list = _facturesBox?.get('list') as List<dynamic>? ?? [];
    return list
        .map((e) => Facture.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveFactureList(List<Facture> list) async {
    await _facturesBox?.put('list', list.map((e) => e.toJson()).toList());
  }

  static Future<void> addFacture(Facture f) async {
    final list = getFactureList();
    list.insert(0, f);
    await saveFactureList(list);
  }

  static Future<void> updateFacture(String id, Facture f) async {
    final list = getFactureList();
    final i = list.indexWhere((e) => e.id == id);
    if (i >= 0) {
      list[i] = f;
      await saveFactureList(list);
    }
  }

  static Future<void> removeFacture(String id) async {
    final list = getFactureList();
    list.removeWhere((e) => e.id == id);
    await saveFactureList(list);
  }

  static Facture? getFactureById(String id) {
    try {
      return getFactureList().firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // ——— Ancien compteur de devis (legacy, conservé pour rétrocompat) ——
  static int getLastDevisNumber() {
    return _prefsBox?.get(HiveKeys.lastDevisNumber) as int? ?? 0;
  }

  static Future<void> setLastDevisNumber(int n) async {
    await _prefsBox?.put(HiveKeys.lastDevisNumber, n);
  }

  // ——— Numérotation pro (config + compteurs par type) ————————————————
  static NumberingConfig getNumberingConfig() {
    final raw = _prefsBox?.get(HiveKeys.numberingConfig);
    if (raw is Map) {
      return NumberingConfig.fromJson(Map<String, dynamic>.from(raw));
    }
    return const NumberingConfig();
  }

  static Future<void> setNumberingConfig(NumberingConfig cfg) async {
    await _prefsBox?.put(HiveKeys.numberingConfig, cfg.toJson());
  }

  static int getNumberingLastCount(String type) {
    return _prefsBox?.get('${HiveKeys.numberingCountPrefix}$type') as int? ?? 0;
  }

  static Future<void> setNumberingLastCount(String type, int n) async {
    await _prefsBox?.put('${HiveKeys.numberingCountPrefix}$type', n);
  }

  static int? getNumberingLastYear(String type) {
    return _prefsBox?.get('${HiveKeys.numberingYearPrefix}$type') as int?;
  }

  static Future<void> setNumberingLastYear(String type, int y) async {
    await _prefsBox?.put('${HiveKeys.numberingYearPrefix}$type', y);
  }

  // ——— Paramètres entreprise ———————————————————————————————————————
  static Map<String, String> getCompanySettings() {
    final raw = _prefsBox?.get(HiveKeys.company);
    if (raw is Map) return Map<String, String>.from(raw);
    return {};
  }

  static Future<void> saveCompanySettings(Map<String, String> map) async {
    await _prefsBox?.put(HiveKeys.company, map);
  }

  // ——— Catégories ——————————————————————————————————————————————————
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

  /// Réinitialise toute l'application : catégories, désignations, devis,
  /// factures, paramètres entreprise, compteurs.
  static Future<void> resetAll() async {
    await saveDesignations([]);
    await saveDevisList([]);
    await saveFactureList([]);
    await saveCategories([]);
    await saveCompanySettings({});
    await setLastDevisNumber(0);
    await setNumberingLastCount(NumberingService.devisType, 0);
    await setNumberingLastCount(NumberingService.factureType, 0);
  }

  // ——— Préférences UI ——————————————————————————————————————————————
  /// Mode de thème stocké (`'system'`, `'light'`, `'dark'`). `'system'` par défaut.
  static String getThemeMode() {
    final v = _prefsBox?.get(HiveKeys.themeMode);
    if (v is String && (v == 'system' || v == 'light' || v == 'dark')) return v;
    return 'system';
  }

  static Future<void> setThemeMode(String mode) async {
    await _prefsBox?.put(HiveKeys.themeMode, mode);
  }

  /// Vrai si l'onboarding a déjà été affiché au moins une fois.
  static bool isOnboardingSeen() {
    return _prefsBox?.get(HiveKeys.onboardingSeen) as bool? ?? false;
  }

  static Future<void> markOnboardingSeen() async {
    await _prefsBox?.put(HiveKeys.onboardingSeen, true);
  }

  // ——— Couverture PDF préférée ———————————————————————————————————————
  /// Dernier `CoverTemplate.name` choisi par l'utilisateur. `null` au premier
  /// usage → l'app retombera sur le modèle classique.
  static String? getCoverTemplateId() {
    final v = _prefsBox?.get(HiveKeys.coverTemplateId);
    return v is String && v.isNotEmpty ? v : null;
  }

  static Future<void> setCoverTemplateId(String id) async {
    await _prefsBox?.put(HiveKeys.coverTemplateId, id);
  }
}
