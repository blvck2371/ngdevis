import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/designation.dart';
import '../database/hive_storage.dart';
import '../services/csv_service.dart';
import '../services/json_service.dart';

class DesignationController extends GetxController {
  final list = <Designation>[].obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void load() {
    list.assignAll(HiveStorage.getDesignations());
  }

  List<Designation> get filteredList {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((d) {
      return d.nom.toLowerCase().contains(q) ||
          d.categorie.toLowerCase().contains(q);
    }).toList();
  }

  /// Suggestions pour l'autocomplétion (nom ou catégorie contient la requête).
  List<Designation> suggestions(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((d) {
      return d.nom.toLowerCase().contains(q) ||
          d.categorie.toLowerCase().contains(q);
    }).toList();
  }

  /// Suggestions filtrées par catégorie (ex: Plomberie, Maçonnerie, Charpenterie).
  /// Si category est vide, retourne toutes les désignations filtrées par query.
  List<Designation> suggestionsByCategory(String? category, String query) {
    final q = query.trim().toLowerCase();
    final cat = (category ?? '').trim().toLowerCase();
    List<Designation> result;
    if (cat.isNotEmpty) {
      result = list.where((d) => d.categorie.trim().toLowerCase() == cat).toList();
    } else {
      result = list.toList();
    }
    if (q.isEmpty) return result;
    return result.where((d) =>
        d.nom.toLowerCase().contains(q) || d.categorie.trim().toLowerCase().contains(q)).toList();
  }

  /// Liste des catégories : celles créées par l'utilisateur + celles des désignations.
  /// Peut être vide si aucune catégorie n'existe.
  List<String> get categories {
    final set = <String>{};
    for (final c in HiveStorage.getCategories()) {
      if (c.trim().isNotEmpty) set.add(c.trim());
    }
    for (final d in list) {
      if (d.categorie.trim().isNotEmpty) set.add(d.categorie.trim());
    }
    return set.toList()..sort();
  }

  Future<void> addCategory(String name) async {
    await HiveStorage.addCategory(name);
  }

  /// Supprime la catégorie et réaffecte les désignations concernées à une chaîne vide (sans catégorie).
  /// La liste des catégories peut ainsi rester vide.
  Future<void> removeCategory(String name) async {
    final cat = name.trim();
    if (cat.isEmpty) return;
    await HiveStorage.removeCategory(cat);
    final designations = HiveStorage.getDesignations();
    final catLower = cat.toLowerCase();
    var changed = false;
    for (final d in designations) {
      if (d.categorie.trim().toLowerCase() == catLower) {
        d.categorie = '';
        changed = true;
      }
    }
    if (changed) await HiveStorage.saveDesignations(designations);
    load();
  }

  /// Renomme une catégorie et met à jour les désignations associées.
  /// Retourne false si le nouveau nom existe déjà ou est invalide.
  Future<bool> renameCategory(String oldName, String newName) async {
    final ok = await HiveStorage.renameCategory(oldName, newName);
    if (ok) load();
    return ok;
  }

  /// Trouve une désignation par nom (exact, insensible à la casse).
  Designation? findByName(String name) {
    final n = name.trim();
    if (n.isEmpty) return null;
    final lower = n.toLowerCase();
    try {
      return list.firstWhere((d) => d.nom.toLowerCase() == lower);
    } catch (_) {
      return null;
    }
  }

  /// Retourne la désignation existante ou crée et sauvegarde une nouvelle en base.
  /// Si une nouvelle désignation est créée, la catégorie est aussi enregistrée dans la liste des catégories,
  /// et l'unité par défaut [uniteDefaut] est conservée pour les futures lignes.
  /// Retourne (désignation, true si nouvellement créée).
  Future<(Designation, bool)> ensureDesignation(
    String nom,
    double prixUnitaire, [
    String? categorie,
    String? uniteDefaut,
  ]) async {
    final n = nom.trim();
    final cat = (categorie ?? '').trim();
    if (n.isEmpty) {
      final d = Designation(
        id: const Uuid().v4(),
        nom: 'Sans nom',
        prixUnitaire: prixUnitaire,
        categorie: cat,
        uniteDefaut: uniteDefaut,
      );
      await addCategory(cat);
      await add(d);
      return (d, true);
    }
    final existing = findByName(n);
    if (existing != null) return (existing, false);
    final d = Designation(
      id: const Uuid().v4(),
      nom: n,
      prixUnitaire: prixUnitaire,
      categorie: cat,
      uniteDefaut: uniteDefaut,
    );
    await addCategory(cat);
    await add(d);
    return (d, true);
  }

  Future<void> add(Designation d) async {
    await HiveStorage.addDesignation(d);
    load();
  }

  Future<void> updateAt(int index, Designation d) async {
    final fullList = HiveStorage.getDesignations();
    if (index >= 0 && index < fullList.length) {
      await HiveStorage.updateDesignation(index, d);
      load();
    }
  }

  Future<void> removeAt(int index) async {
    final fullList = HiveStorage.getDesignations();
    if (index >= 0 && index < fullList.length) {
      await HiveStorage.removeDesignationAt(index);
      load();
    }
  }

  /// Import CSV : fusionne avec la base (ajoute les nouvelles).
  Future<int> importCsv() async {
    final imported = await CsvService.importFromFile();
    if (imported.isEmpty) return 0;
    final existing = HiveStorage.getDesignations();
    final byNom = {for (var e in existing) e.nom: e};
    var added = 0;
    for (final d in imported) {
      if (!byNom.containsKey(d.nom)) {
        byNom[d.nom] = d;
        d.id = const Uuid().v4();
        await HiveStorage.addDesignation(d);
        added++;
      }
    }
    if (added > 0) load();
    return added;
  }

  /// Remplace toute la base par le CSV importé.
  Future<int> replaceWithCsv() async {
    final imported = await CsvService.importFromFile();
    if (imported.isEmpty) return 0;
    for (var i = 0; i < imported.length; i++) {
      imported[i].id = '${DateTime.now().millisecondsSinceEpoch}_$i';
    }
    await HiveStorage.saveDesignations(imported);
    load();
    return imported.length;
  }

  /// Export CSV : désignations triées par catégorie (rétrocompatibilité).
  String exportCsv() {
    final sorted = list.toList()
      ..sort((a, b) => a.categorie.toLowerCase().compareTo(b.categorie.toLowerCase()));
    return CsvService.exportToCsv(sorted);
  }

  /// Import JSON : charge catégories + désignations, fusionne avec la base.
  /// Retourne (nombre de désignations ajoutées, nombre de catégories chargées).
  Future<({int designationsAdded, int categoriesCount})> importJson() async {
    final data = await JsonService.importFromFile();
    if (data == null) return (designationsAdded: 0, categoriesCount: 0);
    for (final cat in data.categories) {
      await HiveStorage.addCategory(cat);
    }
    final existing = HiveStorage.getDesignations();
    final byNom = {for (var e in existing) e.nom: e};
    var added = 0;
    for (final d in data.designations) {
      if (!byNom.containsKey(d.nom)) {
        byNom[d.nom] = d;
        d.id = const Uuid().v4();
        await HiveStorage.addDesignation(d);
        added++;
      }
    }
    if (added > 0 || data.categories.isNotEmpty) load();
    return (designationsAdded: added, categoriesCount: data.categories.length);
  }

  /// Export JSON : catégories + désignations (triées par catégorie).
  String exportJson() {
    final categories = HiveStorage.getCategories();
    final sorted = list.toList()
      ..sort((a, b) => a.categorie.toLowerCase().compareTo(b.categorie.toLowerCase()));
    return JsonService.exportToJson(categories, sorted);
  }
}
