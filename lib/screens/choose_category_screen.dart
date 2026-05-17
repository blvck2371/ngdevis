import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/controllers/designation_controller.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/responsive.dart';

/// Écran de choix des catégories avant de créer un devis.
/// Les désignations proposées dans le devis seront filtrées par ces catégories.
class ChooseCategoryScreen extends StatefulWidget {
  const ChooseCategoryScreen({super.key});

  @override
  State<ChooseCategoryScreen> createState() => _ChooseCategoryScreenState();
}

class _ChooseCategoryScreenState extends State<ChooseCategoryScreen> {
  /// Ordre de sélection conservé pour les sections du devis.
  final Set<String> _selected = <String>{};
  final _newCategoryController = TextEditingController();

  /// `true` si on est en train de créer une **facture** directement
  /// (le devis intermédiaire sera converti automatiquement à la sauvegarde).
  bool _asInvoice = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map && args['asInvoice'] == true) {
      _asInvoice = true;
    }
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  void _toggleCategory(String cat) {
    setState(() {
      if (_selected.contains(cat)) {
        _selected.remove(cat);
      } else {
        _selected.add(cat);
      }
    });
  }

  void _onContinue() {
    if (_selected.isEmpty) return;
    Get.toNamed(
      AppRoutes.devisClientPrep,
      arguments: {
        'categories': _selected.toList(),
        'asInvoice': _asInvoice,
      },
    );
  }

  Future<void> _addNewCategory(DesignationController dc, String t) async {
    if (t.isEmpty) return;
    final name = t.trim();
    if (dc.categories.any((c) => c.toLowerCase() == name.toLowerCase())) {
      final existing = dc.categories.firstWhere(
        (c) => c.toLowerCase() == name.toLowerCase(),
      );
      setState(() => _selected.add(existing));
    } else {
      await dc.addCategory(name);
      setState(() => _selected.add(name));
    }
    _newCategoryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final dc = Get.find<DesignationController>();
    final r = context.responsive;
    final categories = dc.categories;
    final canContinue = _selected.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_asInvoice ? 'Catégorie · Facture' : 'Choisir la catégorie'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            r.horizontalPadding,
            20,
            r.horizontalPadding,
            100 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            Text(
              _asInvoice
                  ? 'Choisissez une ou plusieurs catégories pour votre facture. Les désignations proposées correspondront à ces catégories.'
                  : 'Choisissez une ou plusieurs catégories pour votre devis. Les désignations proposées correspondront à ces catégories.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'Catégories disponibles',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            if (categories.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune catégorie pour l\'instant. Ajoutez-en une ci‑dessous ou importez des désignations (CSV) depuis l\'accueil.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...categories.map((cat) {
                final isSelected = _selected.contains(cat);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.6)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => _toggleCategory(cat),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                cat,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
            Text(
              'Ajouter une catégorie',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCategoryController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Plomberie, Maçonnerie…',
                    ),
                    onSubmitted: (v) => _addNewCategory(dc, v.trim()),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: () =>
                      _addNewCategory(dc, _newCategoryController.text.trim()),
                  child: const Text('Ajouter'),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            r.horizontalPadding,
            12,
            r.horizontalPadding,
            12 + MediaQuery.of(context).padding.bottom,
          ),
          child: FilledButton(
            onPressed: canContinue ? _onContinue : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              canContinue
                  ? 'Suivant (${_selected.length} catégorie${_selected.length > 1 ? 's' : ''})'
                  : 'Choisir au moins une catégorie',
            ),
          ),
        ),
      ),
    );
  }
}
