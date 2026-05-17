import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../core/controllers/designation_controller.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/responsive.dart';

/// Écran d'accueil : Enregistrer / gérer les catégories.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _newCategoryController = TextEditingController();

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dc = Get.find<DesignationController>();
    final r = context.responsive;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrer les catégories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _importJson(context, dc),
            tooltip: 'Importer catégories et désignations (JSON)',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportJson(context, dc),
            tooltip: 'Exporter catégories et désignations (JSON)',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            r.horizontalPadding,
            20,
            r.horizontalPadding,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            Text(
              'Créez et gérez les catégories (Plomberie, Maçonnerie, Charpenterie…). Elles servent à organiser les désignations et les devis.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'Nouvelle catégorie',
                      hintText: 'Ex: Plomberie, Charpenterie',
                    ),
                    onSubmitted: (_) => _addCategory(dc),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _addCategory(dc),
                  child: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Obx(() {
              final categories = dc.categories;
              if (categories.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.category_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune catégorie. Ajoutez-en une ci-dessus.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catégories enregistrées',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...categories.map((cat) {
                    final count = dc.list.where((d) => d.categorie == cat).length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          leading: Icon(Icons.folder_outlined, color: Theme.of(context).colorScheme.primary),
                          title: Text(cat),
                          subtitle: count > 0 ? Text('$count désignation(s)') : null,
                          onTap: () => Get.toNamed(AppRoutes.categoryDesignations, arguments: cat),
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
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
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
              ? '« $cat » est utilisée par $designationCount désignation(s). La catégorie sera retirée de la liste.'
              : '« $cat » sera retirée de la liste.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await dc.removeCategory(cat);
              if (context.mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Catégorie « $cat » supprimée'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _importJson(BuildContext context, DesignationController dc) async {
    final result = await dc.importJson();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.designationsAdded > 0 || result.categoriesCount > 0
              ? '${result.designationsAdded} désignation(s), ${result.categoriesCount} catégorie(s) importés'
              : 'Aucun fichier sélectionné ou fichier invalide',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {});
  }

  Future<void> _exportJson(BuildContext context, DesignationController dc) async {
    final categories = dc.categories;
    if (categories.isEmpty && dc.list.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune catégorie ni désignation à exporter'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    try {
      final jsonStr = dc.exportJson();
      final bytes = utf8.encode(jsonStr);
      final fileName = 'categories_designations_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.json';
      final path = await FilePicker.saveFile(
        dialogTitle: 'Exporter catégories et désignations (JSON)',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      if (!context.mounted) return;
      if (path != null && path.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier enregistré : $path'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export enregistré'),
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
