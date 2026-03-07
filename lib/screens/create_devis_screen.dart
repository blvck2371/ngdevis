import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/controllers/create_devis_controller.dart';
import '../core/controllers/designation_controller.dart';
import '../core/controllers/devis_controller.dart';
import '../core/models/devis.dart';
import '../core/models/designation.dart';
import '../core/models/devis_item.dart';
import '../core/models/section_devis.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/responsive.dart';

class CreateDevisScreen extends StatelessWidget {
  const CreateDevisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CreateDevisController>();
    final r = context.responsive;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          c.editingDevisId == null ? 'Nouveau devis' : 'Modifier le devis',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importer un devis (historique ou fichier JSON)',
            onPressed: () => _showImportDevisSheet(context, c),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter le devis en JSON et enregistrer sur l’appareil',
            onPressed: () => _exportDevisToJson(context, c),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Enregistrer le devis',
            onPressed: () async {
              final saved = await c.save();
              if (saved != null) {
                Get.offNamedUntil(AppRoutes.dashboard, (route) => false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Devis enregistré'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Impossible d’enregistrer : le devis ne contient aucune ligne.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (r.isSideBySide) {
              return _buildSideBySideLayout(context, c, r, constraints);
            }
            return _buildMobileTabLayout(context, c, r, constraints);
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'add_section',
              onPressed: () => c.addSection(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une section'),
              tooltip: 'Ajouter une section au devis',
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'preview_pdf',
              onPressed: () async {
                final devis = c.buildCurrentDevis();
                final dc = Get.find<DevisController>();
                await dc.saveDevis(devis);
                c.editingDevisId = devis.id;
                await dc.previewPdf(devis);
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Aperçu PDF'),
              tooltip: 'Enregistrer le devis dans l\'historique et voir le PDF',
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre la feuille d’import : historique ou fichier JSON.
  /// Layout tablette / PC : formulaire à gauche, aperçu PDF à droite (visible sans scroller).
  Widget _buildSideBySideLayout(
    BuildContext context,
    CreateDevisController c,
    Responsive r,
    BoxConstraints constraints,
  ) {
    final bottomPadding = 140 + MediaQuery.of(context).padding.bottom;
    return SizedBox(
      height: constraints.maxHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              r.horizontalPadding,
              16,
              r.horizontalPadding,
              bottomPadding,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCompanySection(context, c, r),
                  SizedBox(height: r.sectionSpacing),
                  _buildClientSection(context, c, r),
                  SizedBox(height: r.sectionSpacing),
                  _buildDevisInfoSection(context, c, r),
                  SizedBox(height: r.sectionSpacing),
                  Obx(() => _buildSections(context, c, r)),
                  SizedBox(height: r.sectionSpacing),
                  Obx(() => _buildTotal(context, c)),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: r.horizontalPadding),
        Expanded(
          flex: 1,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 16, right: r.horizontalPadding),
                  child: Text(
                    'Aperçu du PDF',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Obx(() {
                    final preview = _buildPdfPreviewTable(context, c);
                    return SingleChildScrollView(
                      padding: EdgeInsets.only(right: r.horizontalPadding, bottom: 24),
                      child: preview,
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    )
    );
  }

  /// Layout mobile : onglets Saisie | Aperçu pour voir l'aperçu sans scroller.
  Widget _buildMobileTabLayout(
    BuildContext context,
    CreateDevisController c,
    Responsive r,
    BoxConstraints constraints,
  ) {
    final bottomPadding = 140 + MediaQuery.of(context).padding.bottom;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(icon: Icon(Icons.edit_note, size: 22), text: 'Saisie'),
                Tab(icon: Icon(Icons.picture_as_pdf_outlined, size: 22), text: 'Aperçu'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    r.horizontalPadding,
                    16,
                    r.horizontalPadding,
                    bottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCompanySection(context, c, r),
                      SizedBox(height: r.sectionSpacing),
                      _buildClientSection(context, c, r),
                      SizedBox(height: r.sectionSpacing),
                      _buildDevisInfoSection(context, c, r),
                      SizedBox(height: r.sectionSpacing),
                      Obx(() => _buildSections(context, c, r)),
                      SizedBox(height: r.sectionSpacing),
                      Obx(() => _buildTotal(context, c)),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    r.horizontalPadding,
                    16,
                    r.horizontalPadding,
                    bottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Obx(() => _buildPdfPreviewTable(context, c)),
                      SizedBox(height: r.sectionSpacing),
                      Obx(() => _buildTotal(context, c)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ouvre la feuille d'import : historique ou fichier JSON.
  static void _showImportDevisSheet(BuildContext context, CreateDevisController c) {
    final dc = Get.find<DevisController>();
    dc.load();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: Theme.of(ctx).colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Importer un devis',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Choisir dans l’historique'),
              subtitle: const Text('Charger un devis déjà enregistré'),
              onTap: () {
                Navigator.pop(ctx);
                _showHistoryDevisPicker(context, c, dc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Importer depuis un fichier JSON'),
              subtitle: const Text('Charger un devis depuis un fichier .json'),
              onTap: () async {
                Navigator.pop(ctx);
                await _importDevisFromJsonFile(context, c);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche la liste des devis de l’historique pour en charger un.
  static void _showHistoryDevisPicker(
    BuildContext context,
    CreateDevisController c,
    DevisController dc,
  ) {
    if (dc.list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun devis dans l’historique'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Choisir un devis',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Obx(() => ListView.builder(
                controller: scrollController,
                itemCount: dc.list.length,
                itemBuilder: (context, i) {
                  final devis = dc.list[i];
                  final subtitle = devis.client?.nom ?? devis.titreDevis ?? devis.numero;
                  return ListTile(
                    title: Text('Devis n° ${devis.numero}'),
                    subtitle: Text(subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      c.initForEdit(devis);
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Devis n° ${devis.numero} chargé'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }

  /// Sélectionne un fichier JSON et charge le devis dans l’éditeur.
  static Future<void> _importDevisFromJsonFile(
    BuildContext context,
    CreateDevisController c,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty || result.files.single.path == null) return;
    final path = result.files.single.path!;
    try {
      final content = await File(path).readAsString();
      final map = jsonDecode(content);
      if (map is! Map) throw FormatException('Le fichier doit contenir un objet JSON');
      final devis = Devis.fromJson(Map<String, dynamic>.from(map));
      c.initForEdit(devis);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Devis n° ${devis.numero} importé depuis le fichier'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier JSON invalide : $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Exporte le devis en JSON, l’enregistre sur l’appareil et ouvre le partage pour sauvegarder ailleurs si besoin.
  /// Ne fait rien si le devis est vide (aucune ligne).
  static Future<void> _exportDevisToJson(BuildContext context, CreateDevisController c) async {
    final hasAnyLine = c.sections.any((s) => s.items.isNotEmpty);
    if (!hasAnyLine) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d’exporter : le devis ne contient aucune ligne.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final devis = c.buildCurrentDevis();
    try {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(devis.toJson());
      final dir = await getApplicationDocumentsDirectory();
      final devisDir = Directory('${dir.path}/Devis');
      if (!await devisDir.exists()) await devisDir.create(recursive: true);
      final dateStr = devis.date.toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = 'Devis_${devis.numero}_$dateStr.json';
      final file = File('${devisDir.path}/$fileName');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Devis n° ${devis.numero} exporté',
        subject: 'Devis ${devis.numero}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Devis exporté en JSON : $fileName. Enregistré et partagé.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l’export : $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildCompanySection(
    BuildContext context,
    CreateDevisController c,
    Responsive r,
  ) {
    return _SectionCard(
      icon: Icons.business,
      title: 'Entreprise',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.logoPath.value.isNotEmpty &&
                  File(c.logoPath.value).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(c.logoPath.value),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, size: 32),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => c.pickLogo(),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choisir un logo'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Nom entreprise',
              hintText: 'Votre raison sociale',
            ),
            controller: TextEditingController(text: c.nomEntreprise.value)
              ..selection = TextSelection.collapsed(
                offset: c.nomEntreprise.value.length,
              ),
            onChanged: (v) => c.nomEntreprise.value = v,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tél entreprise',
              hintText: 'Ex: 698 87 93 76',
            ),
            keyboardType: TextInputType.phone,
            controller: TextEditingController(text: c.telEntreprise.value)
              ..selection = TextSelection.collapsed(
                offset: c.telEntreprise.value.length,
              ),
            onChanged: (v) => c.telEntreprise.value = v,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Adresse entreprise'),
            maxLines: 2,
            controller: TextEditingController(text: c.adresseEntreprise.value)
              ..selection = TextSelection.collapsed(
                offset: c.adresseEntreprise.value.length,
              ),
            onChanged: (v) => c.adresseEntreprise.value = v,
          ),
        ],
      ),
    );
  }

  Widget _buildClientSection(
    BuildContext context,
    CreateDevisController c,
    Responsive r,
  ) {
    return _SectionCard(
      icon: Icons.person,
      title: 'Client',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Nom client',
              hintText: 'Nom du client',
            ),
            controller: TextEditingController(text: c.clientNom.value)
              ..selection = TextSelection.collapsed(
                offset: c.clientNom.value.length,
              ),
            onChanged: (v) => c.clientNom.value = v,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Tél client'),
            keyboardType: TextInputType.phone,
            controller: TextEditingController(text: c.clientTel.value)
              ..selection = TextSelection.collapsed(
                offset: c.clientTel.value.length,
              ),
            onChanged: (v) => c.clientTel.value = v,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Adresse client'),
            maxLines: 2,
            controller: TextEditingController(text: c.clientAdresse.value)
              ..selection = TextSelection.collapsed(
                offset: c.clientAdresse.value.length,
              ),
            onChanged: (v) => c.clientAdresse.value = v,
          ),
        ],
      ),
    );
  }

  Widget _buildDevisInfoSection(
    BuildContext context,
    CreateDevisController c,
    Responsive r,
  ) {
    return _SectionCard(
      icon: Icons.description,
      title: 'Informations devis',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Numéro devis',
              hintText: 'Ex: 0001',
            ),
            controller: TextEditingController(text: c.numero.value)
              ..selection = TextSelection.collapsed(
                offset: c.numero.value.length,
              ),
            onChanged: (v) => c.numero.value = v,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Titre du devis',
              hintText: 'Ex: Devis évacuation et alimentation',
            ),
            controller: TextEditingController(text: c.titreDevis.value)
              ..selection = TextSelection.collapsed(
                offset: c.titreDevis.value.length,
              ),
            onChanged: (v) => c.titreDevis.value = v,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Note (NB)',
              hintText: 'Ex: Nous travaillons selon la norme DTU 60.1',
            ),
            maxLines: 2,
            controller: TextEditingController(text: c.noteNb.value)
              ..selection = TextSelection.collapsed(
                offset: c.noteNb.value.length,
              ),
            onChanged: (v) => c.noteNb.value = v,
          ),
        ],
      ),
    );
  }

  Widget _buildSections(
    BuildContext context,
    CreateDevisController c,
    Responsive r,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.list_alt,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Sections du devis',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(
          c.sections.length,
          (i) => _SectionCardDevis(controller: c, sectionIndex: i, r: r),
        ),
      ],
    );
  }

  /// Aperçu sous forme de tableau de ce qui sera affiché dans le PDF.
  Widget _buildPdfPreviewTable(BuildContext context, CreateDevisController c) {
    if (c.sections.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 12),
              Text(
                'Aperçu du PDF',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Text(
                'Ajoutez des sections et des lignes pour voir l’aperçu.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.picture_as_pdf_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Aperçu du PDF',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...c.sections.asMap().entries.map((entry) {
              final i = entry.key;
              final section = entry.value;
              final titreSection = section.titre.trim().isEmpty ? 'Section ${i + 1}' : section.titre.toUpperCase();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      titreSection,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest),
                        columns: const [
                          DataColumn(label: Text('Désignation')),
                          DataColumn(label: Text('Qte'), numeric: true),
                          DataColumn(label: Text('PU'), numeric: true),
                          DataColumn(label: Text('PT'), numeric: true),
                        ],
                        rows: [
                          ...section.items.map((item) => DataRow(
                                cells: [
                                  DataCell(Text(item.designation)),
                                  DataCell(Text(_formatQte(item.quantite))),
                                  DataCell(Text(_formatPrice(item.prixUnitaire))),
                                  DataCell(Text('${_formatPrice(item.total)} F')),
                                ],
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'TOTAL MATERIELLE ${_formatPrice(section.totalMateriel)} F',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                    if (section.mainOeuvre > 0) ...[
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "MAIN D'OEUVRE ${_formatPrice(section.mainOeuvre)} F",
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'TOTAL $titreSection ${_formatPrice(section.totalSection)} F',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(double v) => v.toStringAsFixed(0);
  static String _formatQte(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Widget _buildTotal(BuildContext context, CreateDevisController c) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOTAL GÉNÉRAL',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${c.total.toStringAsFixed(0)} F',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Champ titre de section : saisie et sélection dans le même champ (suggestions = catégories).
class _SectionTitleField extends StatefulWidget {
  final SectionDevis section;
  final VoidCallback onChanged;

  const _SectionTitleField({
    required this.section,
    required this.onChanged,
  });

  @override
  State<_SectionTitleField> createState() => _SectionTitleFieldState();
}

class _SectionTitleFieldState extends State<_SectionTitleField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.section.titre);
    _focusNode = FocusNode();
    _controller.addListener(_syncToSection);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncToSection);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncToSection() {
    if (widget.section.titre != _controller.text) {
      widget.section.titre = _controller.text;
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dc = Get.find<DesignationController>();
    final categories = dc.categories;

    return RawAutocomplete<String>(
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (option) => option,
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return categories;
        return categories.where((c) => c.toLowerCase().contains(q)).toList();
      },
      onSelected: (value) {
        _controller.text = value;
        widget.section.titre = value;
        widget.onChanged();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Titre section (catégorie)',
            hintText: 'Saisir ou choisir une catégorie…',
          ),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(option),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionCardDevis extends StatelessWidget {
  final CreateDevisController controller;
  final int sectionIndex;
  final Responsive r;

  const _SectionCardDevis({
    required this.controller,
    required this.sectionIndex,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final section = c.sections[sectionIndex];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(r.isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SectionTitleField(
                    section: section,
                    onChanged: () => c.sections.refresh(),
                  ),
                ),
                if (c.sections.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Supprimer la section',
                    onPressed: () => c.removeSectionAt(sectionIndex),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: "Main d'œuvre (%)",
                      hintText: 'Ex: 15 pour 15%',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    controller: TextEditingController(
                      text: section.mainOeuvrePercent > 0
                          ? section.mainOeuvrePercent.toStringAsFixed(1)
                          : '',
                    ),
                    onChanged: (v) {
                      c.setSectionMainOeuvrePercent(
                        sectionIndex,
                        double.tryParse(v.replaceAll(',', '.')) ?? 0,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (section.mainOeuvre > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '= ${section.mainOeuvre.toStringAsFixed(0)} F',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(section.items.length, (index) {
              final item = section.items[index];
              return _DraggableItemRow(
                key: ValueKey('$sectionIndex-$index'),
                controller: c,
                sectionIndex: sectionIndex,
                itemIndex: index,
                item: item,
                isCompact: r.isCompact,
              );
            }),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _showAddLigneModal(context, c, sectionIndex),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Ajouter une ligne'),
            ),
            const Divider(height: 24),
            Text(
              'Total section : ${section.totalSection.toStringAsFixed(0)} F',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLigneModal(
    BuildContext context,
    CreateDevisController c,
    int sectionIndex,
  ) {
    final section = c.sections[sectionIndex];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _AddLigneModal(
        sectionIndex: sectionIndex,
        category: section.titre.trim().isEmpty ? null : section.titre.trim(),
        onAdded: () => Navigator.pop(ctx),
      ),
    );
  }
}

/// Modale pour ajouter une ligne : désignation par catégorie (section), quantité et PU en temps réel.
class _AddLigneModal extends StatefulWidget {
  final int sectionIndex;
  final String? category;
  final VoidCallback onAdded;

  const _AddLigneModal({
    required this.sectionIndex,
    this.category,
    required this.onAdded,
  });

  @override
  State<_AddLigneModal> createState() => _AddLigneModalState();
}

class _AddLigneModalState extends State<_AddLigneModal> {
  TextEditingController? _designationFieldController;
  final _quantiteController = TextEditingController(text: '1');
  final _prixUnitaireController = TextEditingController(text: '0');

  String? _errorDesignation;
  String? _errorQuantite;
  String? _errorPrixUnitaire;

  void _onFieldsChanged() {
    setState(() {
      _errorDesignation = null;
      _errorQuantite = null;
      _errorPrixUnitaire = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _quantiteController.addListener(_onFieldsChanged);
    _prixUnitaireController.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    _designationFieldController?.removeListener(_onFieldsChanged);
    _quantiteController.removeListener(_onFieldsChanged);
    _prixUnitaireController.removeListener(_onFieldsChanged);
    _quantiteController.dispose();
    _prixUnitaireController.dispose();
    super.dispose();
  }

  double get _quantite =>
      double.tryParse(_quantiteController.text.replaceAll(',', '.')) ?? 0;
  double get _prixUnitaire =>
      double.tryParse(_prixUnitaireController.text.replaceAll(',', '.')) ?? 0;
  double get _total => _quantite * _prixUnitaire;

  bool _validate() {
    final nom = _designationFieldController?.text.trim() ?? '';
    final q = _quantite;
    final pu = _prixUnitaire;

    setState(() {
      _errorDesignation = nom.isEmpty ? 'La désignation est obligatoire' : null;
      _errorQuantite = q <= 0 ? 'La quantité doit être supérieure à 0' : null;
      _errorPrixUnitaire = pu < 0 ? 'Le prix unitaire ne peut pas être négatif' : null;
    });

    return _errorDesignation == null && _errorQuantite == null && _errorPrixUnitaire == null;
  }

  Future<void> _onAdd() async {
    if (!_validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires correctement'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final nom = (_designationFieldController?.text.trim() ?? '').trim();
    final category = widget.category?.trim().isEmpty == true ? '' : (widget.category ?? '');
    try {
      final c = Get.find<CreateDevisController>();
      final wasCreated = await c.addItemFromModal(
        widget.sectionIndex,
        nom,
        _quantite,
        _prixUnitaire,
        widget.category,
      );
      if (mounted) {
        widget.onAdded();
        if (wasCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Désignation « $nom » enregistrée dans $category'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dc = Get.find<DesignationController>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nouvelle ligne',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              if (widget.category != null && widget.category!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(
                    Icons.category,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text('Catégorie : ${widget.category}'),
                ),
              ],
              const SizedBox(height: 16),
              Autocomplete<Designation>(
                displayStringForOption: (d) => d.nom,
                optionsBuilder: (value) {
                  final query = value.text.trim();
                  final list = dc.suggestionsByCategory(widget.category, query);
                  return list.take(30);
                },
                onSelected: (d) {
                  _designationFieldController?.text = d.nom;
                  _prixUnitaireController.text = d.prixUnitaire.toStringAsFixed(0);
                  setState(() {});
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  if (_designationFieldController != textEditingController) {
                    _designationFieldController?.removeListener(_onFieldsChanged);
                    _designationFieldController = textEditingController;
                    textEditingController.addListener(_onFieldsChanged);
                  }
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Désignation *',
                      hintText: widget.category != null
                          ? 'Rechercher dans ${widget.category}…'
                          : 'Tapez ou choisissez ci‑dessous',
                      errorText: _errorDesignation,
                    ),
                    textInputAction: TextInputAction.next,
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final d = options.elementAt(index);
                            return ListTile(
                              dense: true,
                              title: Text(d.nom),
                              subtitle: Text('${d.prixUnitaire.toStringAsFixed(0)} F'),
                              onTap: () => onSelected(d),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _quantiteController,
                decoration: InputDecoration(
                  labelText: 'Quantité *',
                  hintText: '1',
                  errorText: _errorQuantite,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _prixUnitaireController,
                decoration: InputDecoration(
                  labelText: 'Prix unitaire (F) *',
                  hintText: '0',
                  errorText: _errorPrixUnitaire,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total (PT)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${_total.toStringAsFixed(0)} F',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.category != null
                    ? 'Nouvelle désignation ? Elle sera enregistrée dans la catégorie « ${widget.category} ».'
                    : 'Si la désignation n\'existe pas, elle sera enregistrée en base.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _onAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter la ligne'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligne réordonnable par glisser-déposer (longue pression sur la poignée).
class _DraggableItemRow extends StatelessWidget {
  final CreateDevisController controller;
  final int sectionIndex;
  final int itemIndex;
  final DevisItem item;
  final bool isCompact;

  const _DraggableItemRow({
    super.key,
    required this.controller,
    required this.sectionIndex,
    required this.itemIndex,
    required this.item,
    this.isCompact = true,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onAccept: (draggedIndex) {
        if (draggedIndex != itemIndex) {
          controller.reorderItem(sectionIndex, draggedIndex, itemIndex);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlight = candidateData.isNotEmpty;
        return LongPressDraggable<int>(
          data: itemIndex,
          delay: const Duration(milliseconds: 150),
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.drag_handle, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 8),
                  Text(item.designation, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.4, child: _buildRowContent(context)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: isHighlight
                ? BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: _buildRowContent(context),
          ),
        );
      },
    );
  }

  Widget _buildRowContent(BuildContext context) {
    return _ItemRow(
      key: ValueKey('$sectionIndex-$itemIndex'),
      controller: controller,
      sectionIndex: sectionIndex,
      itemIndex: itemIndex,
      item: item,
      isCompact: isCompact,
      showDragHandle: true,
    );
  }
}

class _ItemRow extends StatelessWidget {
  final CreateDevisController controller;
  final int sectionIndex;
  final int itemIndex;
  final DevisItem item;
  final bool isCompact;
  final bool showDragHandle;

  const _ItemRow({
    super.key,
    required this.controller,
    required this.sectionIndex,
    required this.itemIndex,
    required this.item,
    this.isCompact = true,
    this.showDragHandle = true,
  });

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDragHandle)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.drag_handle,
              size: 24,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        IconButton(
          icon: Icon(
            Icons.remove_circle_outline,
            size: 22,
            color: Theme.of(context).colorScheme.error,
          ),
          tooltip: 'Supprimer la ligne',
          onPressed: () =>
              controller.removeItemFromSection(sectionIndex, itemIndex),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: isCompact ? _buildCompactRow(context) : _buildWideRow(context),
    );
  }

  Widget _buildCompactRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 140,
                  child: TextField(
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Désignation',
                    ),
                    controller: TextEditingController(text: item.designation)
                      ..selection = TextSelection.collapsed(
                        offset: item.designation.length,
                      ),
                    onChanged: (v) => _update(designation: v),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: TextField(
                    decoration: const InputDecoration(isDense: true, hintText: 'Qte'),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: item.quantite.toString())
                      ..selection = TextSelection.collapsed(
                        offset: item.quantite.toString().length,
                      ),
                    onChanged: (v) => _update(
                      quantite: double.tryParse(v.replaceAll(',', '.')) ?? 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: TextField(
                    decoration: const InputDecoration(isDense: true, hintText: 'PU'),
                    keyboardType: TextInputType.number,
                    controller:
                        TextEditingController(
                            text: item.prixUnitaire.toStringAsFixed(0),
                          )
                          ..selection = TextSelection.collapsed(
                            offset: item.prixUnitaire.toStringAsFixed(0).length,
                          ),
                    onChanged: (v) => _update(
                      prixUnitaire: double.tryParse(v.replaceAll(',', '.')) ?? 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: 64,
                    child: Text(
                      '${item.total.toStringAsFixed(0)} F',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildWideRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Désignation',
            ),
            controller: TextEditingController(text: item.designation)
              ..selection = TextSelection.collapsed(
                offset: item.designation.length,
              ),
            onChanged: (v) => _update(designation: v),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: TextField(
            decoration: const InputDecoration(isDense: true, hintText: 'Qte'),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: item.quantite.toString())
              ..selection = TextSelection.collapsed(
                offset: item.quantite.toString().length,
              ),
            onChanged: (v) =>
                _update(quantite: double.tryParse(v.replaceAll(',', '.')) ?? 0),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: TextField(
            decoration: const InputDecoration(isDense: true, hintText: 'PU'),
            keyboardType: TextInputType.number,
            controller:
                TextEditingController(
                    text: item.prixUnitaire.toStringAsFixed(0),
                  )
                  ..selection = TextSelection.collapsed(
                    offset: item.prixUnitaire.toStringAsFixed(0).length,
                  ),
            onChanged: (v) => _update(
              prixUnitaire: double.tryParse(v.replaceAll(',', '.')) ?? 0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            '${item.total.toStringAsFixed(0)} F',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        _buildActionButtons(context),
      ],
    );
  }

  void _update({String? designation, double? quantite, double? prixUnitaire}) {
    controller.updateItemInSection(
      sectionIndex,
      itemIndex,
      DevisItem(
        designation: designation ?? item.designation,
        quantite: quantite ?? item.quantite,
        prixUnitaire: prixUnitaire ?? item.prixUnitaire,
        designationId: item.designationId,
      ),
    );
  }
}
