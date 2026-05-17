import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../core/controllers/designation_controller.dart';
import '../core/models/designation.dart';
import '../core/models/devis_unit.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_currency.dart';
import '../core/utils/responsive.dart';
import '../core/widgets/app_bottom_nav.dart';

const String _newCategoryValue = '__nouvelle_categorie__';

void showEditDesignationDialog(BuildContext context, Designation? d, int index, {String? initialCategory}) {
  showDialog(
    context: context,
    builder: (ctx) => _EditDesignationDialog(designation: d, index: index, initialCategory: initialCategory),
  );
}

class _EditDesignationDialog extends StatefulWidget {
  final Designation? designation;
  final int index;
  final String? initialCategory;

  const _EditDesignationDialog({this.designation, required this.index, this.initialCategory});

  @override
  State<_EditDesignationDialog> createState() => _EditDesignationDialogState();
}

class _EditDesignationDialogState extends State<_EditDesignationDialog> {
  final _nomC = TextEditingController();
  final _puC = TextEditingController();
  final _newCatC = TextEditingController();
  String? _selectedCategory;
  bool _showNewCategoryField = false;
  String _uniteDefaut = DevisUnit.unite.code;

  @override
  void initState() {
    super.initState();
    _nomC.text = widget.designation?.nom ?? '';
    _puC.text = widget.designation?.prixUnitaire.toString() ?? '';
    _uniteDefaut = DevisUnit.fromCode(widget.designation?.uniteDefaut).code;
    final dc = Get.find<DesignationController>();
    final categories = dc.categories;
    final cat = widget.designation == null ? null : widget.designation!.categorie.trim();
    if (cat != null && cat.isNotEmpty && categories.contains(cat)) {
      _selectedCategory = cat;
    } else if (widget.designation == null && widget.initialCategory != null && widget.initialCategory!.trim().isNotEmpty) {
      final initCat = widget.initialCategory!.trim();
      if (categories.contains(initCat)) {
        _selectedCategory = initCat;
      } else {
        _showNewCategoryField = true;
        _newCatC.text = initCat;
        _selectedCategory = null;
      }
    } else {
      _selectedCategory = categories.isNotEmpty ? categories.first : '';
      if (categories.isEmpty) _showNewCategoryField = true;
    }
  }

  @override
  void dispose() {
    _nomC.dispose();
    _puC.dispose();
    _newCatC.dispose();
    super.dispose();
  }

  String get _effectiveCategory {
    if (_showNewCategoryField && _newCatC.text.trim().isNotEmpty) {
      return _newCatC.text.trim();
    }
    return _selectedCategory?.trim().isEmpty == true ? '' : (_selectedCategory ?? '');
  }

  Future<void> _onSave() async {
    final nom = _nomC.text.trim();
    if (nom.isEmpty) return;
    final pu = double.tryParse(_puC.text.replaceAll(',', '.')) ?? 0;
    final cat = _effectiveCategory;
    final dc = Get.find<DesignationController>();
    if (_showNewCategoryField && _newCatC.text.trim().isNotEmpty) {
      await dc.addCategory(_newCatC.text.trim());
    }
    if (widget.designation == null) {
      dc.add(Designation(
        id: const Uuid().v4(),
        nom: nom,
        prixUnitaire: pu,
        categorie: cat,
        uniteDefaut: _uniteDefaut,
      ));
    } else {
      dc.updateAt(
        widget.index,
        Designation(
          id: widget.designation!.id,
          nom: nom,
          prixUnitaire: pu,
          categorie: cat,
          uniteDefaut: _uniteDefaut,
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dc = Get.find<DesignationController>();
    final categories = dc.categories;

    return AlertDialog(
      title: Text(widget.designation == null ? 'Nouvelle désignation' : 'Modifier la désignation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nomC,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Ex: Tuyaux PVC 125',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _puC,
              decoration: const InputDecoration(
                labelText: 'Prix unitaire ($kCurrencyLabel)',
                hintText: 'Ex: 6000',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _uniteDefaut,
              decoration: const InputDecoration(
                labelText: 'Unité par défaut',
                helperText: 'Pré-remplie à l’ajout d’une ligne de devis',
              ),
              isExpanded: true,
              items: DevisUnit.all
                  .map(
                    (u) => DropdownMenuItem<String>(
                      value: u.code,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              u.symbole,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              u.label,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _uniteDefaut = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _showNewCategoryField || categories.isEmpty
                  ? _newCategoryValue
                  : (categories.contains(_selectedCategory) ? _selectedCategory! : categories.first),
              decoration: const InputDecoration(
                labelText: 'Catégorie',
              ),
              items: [
                ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                const DropdownMenuItem(value: _newCategoryValue, child: Text('➕ Nouvelle catégorie')),
              ],
              onChanged: (v) {
                setState(() {
                  if (v == _newCategoryValue) {
                    _showNewCategoryField = true;
                    _selectedCategory = null;
                  } else {
                    _showNewCategoryField = false;
                    _selectedCategory = v;
                    _newCatC.clear();
                  }
                });
              },
            ),
            if (_showNewCategoryField) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _newCatC,
                decoration: const InputDecoration(
                  labelText: 'Nom de la nouvelle catégorie',
                  hintText: 'Ex: Plomberie, Maçonnerie',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(onPressed: _onSave, child: const Text('Enregistrer')),
      ],
    );
  }
}

class DesignationsScreen extends StatelessWidget {
  const DesignationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DesignationController>();
    final r = context.responsive;
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Désignations'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () => _showManageCategories(context, c),
            tooltip: 'Gérer les catégories',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _importJson(c, context),
            tooltip: 'Importer un fichier JSON',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportJson(c, context),
            tooltip: 'Exporter en JSON',
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(r.horizontalPadding, 12, r.horizontalPadding, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher une désignation…',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.of(context).inkMuted),
                ),
                onChanged: (v) => c.searchQuery.value = v,
              ),
            ),
            Expanded(
              child: Obx(() {
                final p = AppColors.of(context);
                final list = c.filteredList.toList()
                  ..sort((a, b) => a.categorie.toLowerCase().compareTo(b.categorie.toLowerCase()));
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(r.horizontalPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.accent.withValues(alpha: 0.12),
                            ),
                            child: Icon(Icons.inventory_2_rounded, size: 38, color: p.accent),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            c.searchQuery.value.trim().isEmpty
                                ? 'Aucune désignation'
                                : 'Aucun résultat',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: p.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.searchQuery.value.trim().isEmpty
                                ? 'Importez un JSON ou ajoutez une désignation'
                                : 'Modifiez la recherche',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: p.inkMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                String? prevCat;
                final items = <Widget>[];
                for (var i = 0; i < list.length; i++) {
                  final d = list[i];
                  if (d.categorie != prevCat) {
                    prevCat = d.categorie;
                    items.add(Padding(
                      padding: const EdgeInsets.only(top: 18, bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 14,
                            decoration: BoxDecoration(
                              color: p.accent,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            prevCat.toUpperCase(),
                            style: TextStyle(
                              color: p.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ));
                  }
                  final fullIndex = c.list.indexOf(d);
                  items.add(_DesignationTile(designation: d, index: fullIndex));
                }
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    r.horizontalPadding,
                    8,
                    r.horizontalPadding,
                    100 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: items,
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        // On remonte le FAB pour qu'il ne soit pas caché par la bottom nav.
        padding: EdgeInsets.only(bottom: 76 + MediaQuery.paddingOf(context).bottom),
        child: FloatingActionButton.extended(
          onPressed: () => showEditDesignationDialog(context, null, -1),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter'),
          tooltip: 'Ajouter une désignation',
        ),
      ),
      bottomNavigationBar: const AppBottomNav(active: AppTab.catalog),
    );
  }

  Future<void> _importJson(DesignationController c, BuildContext context) async {
    final result = await c.importJson();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.designationsAdded > 0 || result.categoriesCount > 0
                ? '${result.designationsAdded} désignation(s), ${result.categoriesCount} catégorie(s) importés'
                : 'Aucun fichier ou fichier annulé',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showManageCategories(BuildContext context, DesignationController c) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _ManageCategoriesSheet(),
    );
  }

  Future<void> _exportJson(DesignationController c, BuildContext context) async {
    if (c.list.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune désignation à exporter'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    try {
      final jsonStr = c.exportJson();
      final bytes = utf8.encode(jsonStr);
      final fileName = 'designations_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.json';

      final path = await FilePicker.saveFile(
        dialogTitle: 'Enregistrer les désignations (JSON)',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (context.mounted && path != null && path.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier enregistré : $path'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (context.mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistrement effectué dans l\'emplacement choisi'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Écran des désignations d'une catégorie (ouvert depuis l'écran Catégories).
/// Permet de voir, ajouter, modifier et supprimer les désignations de cette catégorie.
class CategoryDesignationsScreen extends StatelessWidget {
  const CategoryDesignationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final category = Get.arguments as String? ?? '';
    final c = Get.find<DesignationController>();
    final r = context.responsive;

    if (category.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Catégorie')),
        body: const Center(child: Text('Catégorie non précisée')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Désignations · $category'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final p = AppColors.of(context);
          final designations = c.list.where((d) => d.categorie == category).toList()
            ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
          if (designations.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(r.horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.accent.withValues(alpha: 0.12),
                      ),
                      child: Icon(Icons.inventory_2_rounded, size: 38, color: p.accent),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Aucune désignation dans « $category »',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: p.ink,
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ajoutez-en une avec le bouton ci-dessous',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: p.inkMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              r.horizontalPadding,
              12,
              r.horizontalPadding,
              80 + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: designations.length,
            itemBuilder: (context, i) {
              final d = designations[i];
              final fullIndex = c.list.indexWhere((e) => e.id == d.id);
              return _DesignationTile(designation: d, index: fullIndex >= 0 ? fullIndex : 0);
            },
          );
        }),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: FloatingActionButton.extended(
          onPressed: () => showEditDesignationDialog(context, null, -1, initialCategory: category),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une désignation'),
          tooltip: 'Ajouter une désignation dans cette catégorie',
        ),
      ),
    );
  }
}

class _DesignationTile extends StatelessWidget {
  final Designation designation;
  final int index;

  const _DesignationTile({required this.designation, required this.index});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => showEditDesignationDialog(context, designation, index),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.outlineSoft, width: 1),
            ),
            child: Row(
              children: [
                // Icône container — violet accent
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        p.accent.withValues(alpha: 0.18),
                        p.accent.withValues(alpha: 0.06),
                      ],
                    ),
                  ),
                  child: Icon(Icons.inventory_2_rounded, color: p.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        designation.nom,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          // Prix unitaire → couleur **or** (cohérent avec
                          // tous les montants affichés dans le dashboard).
                          Text(
                            '${_fmtPrice(designation.prixUnitaire)} $kCurrencyLabel',
                            style: TextStyle(
                              color: p.gold,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: -0.1,
                            ),
                          ),
                          Text(
                            '  ·  ',
                            style: TextStyle(color: p.inkMuted, fontSize: 12),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.surfaceHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              designation.unit.symbole,
                              style: TextStyle(
                                color: p.inkMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: p.inkMuted, size: 19),
                  onPressed: () => showEditDesignationDialog(context, designation, index),
                  tooltip: 'Modifier',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: p.error.withValues(alpha: 0.85), size: 19),
                  onPressed: () => _delete(context),
                  tooltip: 'Supprimer',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _fmtPrice(double v) {
    final s = v.toStringAsFixed(0);
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    var i = s.length % 3;
    if (i == 0) i = 3;
    buf.write(s.substring(0, i));
    for (; i < s.length; i += 3) {
      buf.write(' ${s.substring(i, i + 3)}');
    }
    return buf.toString();
  }

  void _delete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette désignation ?'),
        content: Text('« ${designation.nom } » sera supprimée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              Get.find<DesignationController>().removeAt(index);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

/// Feuille modale pour créer et gérer les catégories.
class _ManageCategoriesSheet extends StatefulWidget {
  @override
  State<_ManageCategoriesSheet> createState() => _ManageCategoriesSheetState();
}

class _ManageCategoriesSheetState extends State<_ManageCategoriesSheet> {
  final _newCategoryController = TextEditingController();

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dc = Get.find<DesignationController>();
    final categories = dc.categories;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Gérer les catégories',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Créez des catégories (Plomberie, Maçonnerie…) puis assignez-les aux désignations.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Nouvelle catégorie',
                        hintText: 'Ex: Plomberie, Charpenterie',
                      ),
                      onSubmitted: (v) => _addCategory(dc),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => _addCategory(dc),
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: categories.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune catégorie. Ajoutez-en une ci-dessus.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: categories.length,
                        itemBuilder: (context, i) {
                          final cat = categories[i];
                          final count = dc.list.where((d) => d.categorie == cat).length;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(Icons.folder_outlined, color: Theme.of(context).colorScheme.primary),
                              title: Text(cat),
                              subtitle: count > 0 ? Text('$count désignation(s)') : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _editCategory(context, dc, cat),
                                    tooltip: 'Modifier la catégorie',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _removeCategory(context, dc, cat, count),
                                    tooltip: 'Supprimer la catégorie',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addCategory(DesignationController dc) async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;
    await dc.addCategory(name);
    _newCategoryController.clear();
    setState(() {});
  }

  void _editCategory(BuildContext context, DesignationController dc, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier la catégorie'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nouveau nom',
            hintText: 'Ex: Plomberie sanitaire',
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ).then((newName) async {
      if (newName != null && newName.isNotEmpty && newName != currentName) {
        final ok = await dc.renameCategory(currentName, newName);
        if (mounted) {
          setState(() {});
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ce nom de catégorie existe déjà'), behavior: SnackBarBehavior.floating),
            );
          }
        }
      }
    });
  }

  void _removeCategory(BuildContext context, DesignationController dc, String cat, int designationCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette catégorie ?'),
        content: Text(
          designationCount > 0
              ? '« $cat » est utilisée par $designationCount désignation(s). La catégorie sera retirée de la liste ; les désignations garderont ce nom de catégorie.'
              : '« $cat » sera retirée de la liste.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              await dc.removeCategory(cat);
              Navigator.pop(ctx);
              setState(() {});
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
