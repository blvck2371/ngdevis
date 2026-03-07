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
  String? _selected;
  final _newCategoryController = TextEditingController();

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_selected == null || _selected!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez une catégorie'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Get.offNamed(AppRoutes.createDevis, arguments: [_selected!]);
  }

  Future<void> _addNewCategory(DesignationController dc, String t) async {
    if (t.isEmpty) return;
    final name = t.trim();
    if (dc.categories.any((c) => c.toLowerCase() == name.toLowerCase())) {
      setState(
        () => _selected = dc.categories.firstWhere(
          (c) => c.toLowerCase() == name.toLowerCase(),
        ),
      );
    } else {
      await dc.addCategory(name);
      setState(() => _selected = name);
    }
    _newCategoryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final dc = Get.find<DesignationController>();
    final r = context.responsive;
    final categories = dc.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir la catégorie'),
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
              'Choisissez une seule catégorie pour votre devis. Les désignations proposées seront celles de cette catégorie.',
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
                final isSelected = _selected == cat;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.6)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selected = cat);
                      },
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
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
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
            onPressed: _onContinue,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _selected != null
                  ? 'Continuer avec « $_selected »'
                  : 'Choisir une catégorie',
            ),
          ),
        ),
      ),
    );
  }
}
