import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/controllers/create_devis_controller.dart';
import '../core/controllers/designation_controller.dart';
import '../core/controllers/devis_controller.dart';
import '../core/models/designation.dart';
import '../core/models/devis_item.dart';
import '../core/models/devis_unit.dart';
import '../core/models/section_devis.dart';
import '../core/services/json_service.dart';
import '../core/utils/app_currency.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/responsive.dart';
import 'cover_picker_sheet.dart';

class CreateDevisScreen extends StatelessWidget {
  const CreateDevisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CreateDevisController>();
    final r = context.responsive;
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final invoice = c.asInvoice.value;
          final editing = c.editingDevisId != null;
          if (editing) return const Text('Modifier le devis');
          return Text(invoice ? 'Nouvelle facture' : 'Nouveau devis');
        }),
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
          Obx(() {
            final invoice = c.asInvoice.value;
            return IconButton(
              icon: const Icon(Icons.save),
              tooltip: invoice ? 'Enregistrer la facture' : 'Enregistrer le devis',
              onPressed: () => _handlePrimarySave(context, c),
            );
          }),
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
      floatingActionButton: r.isSideBySide
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
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
                    onPressed: () => _pickAndPreviewDevis(context, c),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Aperçu PDF'),
                    tooltip:
                        'Choisir un modèle puis enregistrer et prévisualiser',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // —————————————————————————————————————————————————————————————————————————
  // Save / dispatch
  // —————————————————————————————————————————————————————————————————————————

  /// Sauvegarde "primaire" : aiguillage entre devis classique et facture
  /// directe selon `c.asInvoice`. Affiche les feedbacks utilisateur,
  /// navigue vers le bon écran à la fin.
  Future<void> _handlePrimarySave(
    BuildContext context,
    CreateDevisController c,
  ) async {
    if (c.asInvoice.value) {
      final dueDate = await _pickInvoiceDueDate(context);
      if (dueDate == null) return;
      try {
        final facture = await c.saveAsFacture(dueDate: dueDate);
        if (facture == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Impossible d’enregistrer : la facture ne contient aucune ligne.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
        Get.offNamedUntil(AppRoutes.dashboard, (route) => false);
        Get.toNamed(AppRoutes.factureDetail, arguments: facture.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Facture ${facture.numero} créée'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur création facture : $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

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
          content: Text(
            'Impossible d’enregistrer : le devis ne contient aucune ligne.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Sélecteur de date d'échéance pour le mode facture (défaut J+30).
  Future<DateTime?> _pickInvoiceDueDate(BuildContext context) async {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      helpText: 'Date d’échéance de la facture',
      confirmText: 'Valider',
      cancelText: 'Annuler',
    );
  }

  /// Ouvre la feuille d’import : historique ou fichier JSON.
  /// Layout tablette / PC : formulaire à gauche, aperçu PDF à droite (visible sans scroller).
  // Helper d'aperçu accessible aux deux layouts (mobile et side-by-side).
  // Voir `_pickAndPreviewDevis` ci-dessous (top-level).
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
                    _buildCompanySummaryWithLink(context, c, r),
                    SizedBox(height: r.sectionSpacing),
                    _buildClientSummaryWithLink(context, c, r),
                    SizedBox(height: r.sectionSpacing),
                    _buildDevisInfoSummaryWithLink(context, c, r),
                    SizedBox(height: r.sectionSpacing),
                    Obx(() => _buildSections(context, c, r)),
                    SizedBox(height: r.sectionSpacing),
                    Obx(() => _buildTotal(context, c)),
                    SizedBox(height: r.sectionSpacing),
                    Obx(() => _buildDeletedHistoryCard(context, c)),
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
                    padding: EdgeInsets.only(
                      top: 16,
                      right: r.horizontalPadding,
                    ),
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
                        padding: EdgeInsets.only(
                          right: r.horizontalPadding,
                          bottom: 24,
                        ),
                        child: preview,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Layout mobile : onglets Saisie | Informations | Aperçu (FAB « section » seulement sur Saisie).
  Widget _buildMobileTabLayout(
    BuildContext context,
    CreateDevisController c,
    Responsive r,
    BoxConstraints constraints,
  ) {
    final bottomPadding = 140 + MediaQuery.of(context).padding.bottom;
    final hPad = r.horizontalPadding;
    return _MobileCreateDevisTabLayout(
      controller: c,
      saisieTab: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() => _buildSections(context, c, r)),
            SizedBox(height: r.sectionSpacing),
            Obx(() => _buildTotal(context, c)),
          ],
        ),
      ),
      informationsTab: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Renseignez l’entreprise, le client et le devis. Utilisez les boutons pour modifier chaque bloc.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: r.sectionSpacing),
            _buildCompanySummaryWithLink(context, c, r),
            SizedBox(height: r.sectionSpacing),
            _buildClientSummaryWithLink(context, c, r),
            SizedBox(height: r.sectionSpacing),
            _buildDevisInfoSummaryWithLink(context, c, r),
          ],
        ),
      ),
      apercuTab: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() => _buildPdfPreviewTable(context, c)),
            SizedBox(height: r.sectionSpacing),
            Obx(() => _buildTotal(context, c)),
          ],
        ),
      ),
      historiqueTab: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, bottomPadding),
        child: Obx(() => _buildDeletedHistoryCard(context, c)),
      ),
    );
  }

  /// Ouvre la feuille d'import : historique ou fichier JSON.
  static void _showImportDevisSheet(
    BuildContext context,
    CreateDevisController c,
  ) {
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
                  Icon(
                    Icons.upload_file,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Importer un devis',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  controller: scrollController,
                  itemCount: dc.list.length,
                  itemBuilder: (context, i) {
                    final devis = dc.list[i];
                    final subtitle =
                        devis.client?.nom ?? devis.titreDevis ?? devis.numero;
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
                ),
              ),
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
    try {
      final devis = await JsonService.pickDevisJsonFile();
      if (devis == null) return;
      c.initForEdit(devis);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Devis n° ${devis.numero} importé depuis le fichier'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on FormatException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier JSON invalide : $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
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
  static Future<void> _exportDevisToJson(
    BuildContext context,
    CreateDevisController c,
  ) async {
    final hasAnyLine = c.sections.any((s) => s.items.isNotEmpty);
    if (!hasAnyLine) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible d’exporter : le devis ne contient aucune ligne.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final devis = c.buildCurrentDevis();
    try {
      final jsonStr = const JsonEncoder.withIndent(
        '  ',
      ).convert(devis.toJson());
      final dir = await getApplicationDocumentsDirectory();
      final devisDir = Directory('${dir.path}/Devis');
      if (!await devisDir.exists()) await devisDir.create(recursive: true);
      final dateStr = devis.date
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
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
            content: Text(
              'Devis exporté en JSON : $fileName. Enregistré et partagé.',
            ),
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

  Widget _buildCompanySummaryWithLink(
    BuildContext context,
    CreateDevisController c,
    Responsive r,
  ) {
    return _SectionCard(
      icon: Icons.business,
      title: 'Entreprise',
      child: Obx(() {
        final path = c.logoPath.value;
        final hasFile = path.isNotEmpty && File(path).existsSync();
        final nom = c.nomEntreprise.value.trim();
        final tel = c.telEntreprise.value.trim();
        final adr = c.adresseEntreprise.value.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasFile)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(path),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.business, color: Colors.grey.shade600),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (nom.isNotEmpty)
                        Text(
                          nom,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        )
                      else
                        Text(
                          'Nom non renseigné',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      if (tel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Tél : $tel',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (adr.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(adr, style: Theme.of(context).textTheme.bodySmall),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showCompanyEditBottomSheet(context, c),
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text('Modifier les informations de l\'entreprise'),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildClientSummaryWithLink(
    BuildContext context,
    CreateDevisController c,
    Responsive r,
  ) {
    return _SectionCard(
      icon: Icons.person,
      title: 'Client',
      child: Obx(() {
        final nom = c.clientNom.value.trim();
        final societe = c.clientSociete.value.trim();
        final tel = c.clientTel.value.trim();
        final adr = c.clientAdresse.value.trim();
        final email = c.clientEmail.value.trim();
        final hasAny =
            nom.isNotEmpty ||
            societe.isNotEmpty ||
            tel.isNotEmpty ||
            adr.isNotEmpty ||
            email.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hasAny)
              Text(
                'Aucune information renseignée',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              )
            else ...[
              if (nom.isNotEmpty)
                Text(
                  nom,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              if (societe.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Société : $societe',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (tel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Tél : $tel',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (adr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    adr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (email.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'E-mail : $email',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showClientEditBottomSheet(context, c),
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text('Modifier les informations du client'),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDevisInfoSummaryWithLink(
    BuildContext context,
    CreateDevisController c,
    Responsive r,
  ) {
    return _SectionCard(
      icon: Icons.description,
      title: 'Informations devis',
      child: Obx(() {
        final numStr = c.numero.value.trim();
        final titre = c.titreDevis.value.trim();
        final note = c.noteNb.value.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'N° devis : ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                Expanded(
                  child: Text(
                    numStr.isNotEmpty ? numStr : '—',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (titre.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(titre, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'NB : $note',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (titre.isEmpty && note.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Titre et note modifiables via le lien ci-dessous',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showDevisInfoEditBottomSheet(context, c),
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text('Modifier les informations du devis'),
              ),
            ),
          ],
        );
      }),
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
            Icon(Icons.list_alt, color: Theme.of(context).colorScheme.primary),
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
          (i) => _SectionCardDevis(
            key: ObjectKey(c.sections[i]),
            controller: c,
            sectionIndex: i,
            r: r,
          ),
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
              Icon(
                Icons.picture_as_pdf_outlined,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Text(
                'Aperçu du PDF',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                Icon(
                  Icons.picture_as_pdf_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Aperçu du PDF',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...c.sections.asMap().entries.map((entry) {
              final i = entry.key;
              final section = entry.value;
              final titreSection = section.titre.trim().isEmpty
                  ? 'Section ${i + 1}'
                  : section.titre.toUpperCase();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      titreSection,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          theme.colorScheme.surfaceContainerHighest,
                        ),
                        columns: const [
                          DataColumn(label: Text('Désignation')),
                          DataColumn(label: Text('Qte'), numeric: true),
                          DataColumn(label: Text('PU'), numeric: true),
                          DataColumn(label: Text('PT'), numeric: true),
                        ],
                        rows: [
                          ...section.items.map(
                            (item) => DataRow(
                              cells: [
                                DataCell(Text(item.designation)),
                                DataCell(Text(DevisUnit.formatQuantity(item.unit, item.quantite))),
                                DataCell(Text('${_formatPrice(item.prixUnitaire)} $kCurrencyLabel')),
                                DataCell(Text('${_formatPrice(item.total)} $kCurrencyLabel')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'TOTAL MATERIELLE ${_formatPrice(section.totalMateriel)} $kCurrencyLabel',
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
                          "MAIN D'OEUVRE ${_formatPrice(section.mainOeuvre)} $kCurrencyLabel",
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'TOTAL $titreSection ${_formatPrice(section.totalSection)} $kCurrencyLabel',
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

  /// Espaces milliers — affichage UI (évite les chaînes trop longues sur mobile).
  static String _formatMontantEspacement(double v) {
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

  Widget _buildTotal(BuildContext context, CreateDevisController c) {
    final manualAmount = c.manualMainOeuvre.value;
    final manualText = manualAmount > 0 ? manualAmount.toStringAsFixed(0) : '';
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'TOTAL',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: c.useManualMainOeuvre.value,
              onChanged: (v) => c.setUseManualMainOeuvre(v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Voulez-vous saisir une main d\'oeuvre manuelle ?',
              ),
            ),
            if (c.useManualMainOeuvre.value) ...[
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: manualText)
                  ..selection = TextSelection.collapsed(
                    offset: manualText.length,
                  ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Main d'oeuvre manuelle",
                  hintText: 'Saisir un montant',
                  suffixText: kCurrencyLabel,
                ),
                onChanged: c.setManualMainOeuvreFromInput,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Main d'oeuvre manuelle",
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 3,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_formatMontantEspacement(c.manualMainOeuvre.value)} $kCurrencyLabel',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'TOTAL GÉNÉRAL',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_formatMontantEspacement(c.totalGeneral)} $kCurrencyLabel',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletedHistoryCard(
    BuildContext context,
    CreateDevisController c,
  ) {
    final entries = c.deletedEntries;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Historique des suppressions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (entries.isNotEmpty)
                  TextButton(
                    onPressed: c.clearDeletedHistory,
                    child: const Text('Vider'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text(
                'Les sections et lignes supprimées apparaîtront ici.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              )
            else
              ...entries.map((entry) {
                final isSection = entry.type == DeletedEntryType.section;
                final rawTitle = isSection
                    ? entry.sectionTitle
                    : entry.itemSnapshot?.designation ?? '';
                final title = rawTitle.trim().isEmpty
                    ? (isSection
                          ? 'Section sans titre'
                          : 'Ligne sans désignation')
                    : rawTitle.trim();
                final sectionLabel = entry.sectionTitle.trim().isEmpty
                    ? 'Section sans titre'
                    : entry.sectionTitle.trim();
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSection ? Icons.view_stream : Icons.remove_circle_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(title),
                  subtitle: Text(
                    '${isSection ? 'Section' : 'Ligne'} • $sectionLabel • ${_formatTime(entry.deletedAt)}',
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: () => c.restoreDeletedEntry(entry.id),
                    child: const Text('Restaurer'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _showClientEditBottomSheet(
    BuildContext context,
    CreateDevisController c,
  ) {
    final nomC = TextEditingController(text: c.clientNom.value);
    final societeC = TextEditingController(text: c.clientSociete.value);
    final telC = TextEditingController(text: c.clientTel.value);
    final adrC = TextEditingController(text: c.clientAdresse.value);
    final emailC = TextEditingController(text: c.clientEmail.value);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: 24 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Informations client',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nomC,
                  decoration: const InputDecoration(
                    labelText: 'Nom client',
                    hintText: 'Nom du client',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: societeC,
                  decoration: const InputDecoration(
                    labelText: 'Société',
                    hintText: 'Raison sociale (optionnel)',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telC,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    hintText: 'Ex: 698 87 93 76',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adrC,
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    hintText: 'Adresse du client',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailC,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    hintText: 'email@exemple.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    c.clientNom.value = nomC.text;
                    c.clientSociete.value = societeC.text;
                    c.clientTel.value = telC.text;
                    c.clientAdresse.value = adrC.text;
                    c.clientEmail.value = emailC.text;
                    c.autoSave();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCompanyEditBottomSheet(
    BuildContext context,
    CreateDevisController c,
  ) {
    final nomC = TextEditingController(text: c.nomEntreprise.value);
    final telC = TextEditingController(text: c.telEntreprise.value);
    final adrC = TextEditingController(text: c.adresseEntreprise.value);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: 24 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Informations entreprise',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final path = c.logoPath.value;
                  final hasFile = path.isNotEmpty && File(path).existsSync();
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasFile)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(path),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.image, color: Colors.grey.shade600),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => c.pickLogo(),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Choisir un logo'),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                TextField(
                  controller: nomC,
                  decoration: const InputDecoration(
                    labelText: 'Nom entreprise',
                    hintText: 'Votre raison sociale',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telC,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    hintText: 'Ex: 698 87 93 76',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adrC,
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    hintText: 'Adresse de l\'entreprise',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    c.nomEntreprise.value = nomC.text;
                    c.telEntreprise.value = telC.text;
                    c.adresseEntreprise.value = adrC.text;
                    c.autoSave();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDevisInfoEditBottomSheet(
    BuildContext context,
    CreateDevisController c,
  ) {
    final titreC = TextEditingController(text: c.titreDevis.value);
    final noteC = TextEditingController(text: c.noteNb.value);
    final numeroAffiche = c.numero.value.trim();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: 24 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Informations du devis',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Numéro devis',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(ctx).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                  ),
                  child: Text(
                    numeroAffiche.isNotEmpty ? numeroAffiche : '—',
                    style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Le numéro de devis ne peut pas être modifié ici.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titreC,
                  decoration: const InputDecoration(
                    labelText: 'Titre du devis',
                    hintText: 'Ex: Devis évacuation et alimentation',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteC,
                  decoration: const InputDecoration(
                    labelText: 'Note (NB)',
                    hintText: 'Ex: Nous travaillons selon la norme DTU 60.1',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    c.titreDevis.value = titreC.text;
                    c.noteNb.value = noteC.text;
                    c.autoSave();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Onglets mobile avec FAB : « Ajouter une section » uniquement sur l’onglet Saisie (index 0).
class _MobileCreateDevisTabLayout extends StatefulWidget {
  final CreateDevisController controller;
  final Widget saisieTab;
  final Widget informationsTab;
  final Widget apercuTab;
  final Widget historiqueTab;

  const _MobileCreateDevisTabLayout({
    required this.controller,
    required this.saisieTab,
    required this.informationsTab,
    required this.apercuTab,
    required this.historiqueTab,
  });

  @override
  State<_MobileCreateDevisTabLayout> createState() =>
      _MobileCreateDevisTabLayoutState();
}

class _MobileCreateDevisTabLayoutState
    extends State<_MobileCreateDevisTabLayout>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() => setState(() {});

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final showAddSection = _tabController.index == 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(icon: Icon(Icons.edit_note, size: 20), text: 'Saisie'),
                  Tab(
                    icon: Icon(Icons.info_outline, size: 20),
                    text: 'Informations',
                  ),
                  Tab(
                    icon: Icon(Icons.picture_as_pdf_outlined, size: 20),
                    text: 'Aperçu',
                  ),
                  Tab(icon: Icon(Icons.history, size: 20), text: 'Historique'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  widget.saisieTab,
                  widget.informationsTab,
                  widget.apercuTab,
                  widget.historiqueTab,
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16 + bottomInset,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showAddSection) ...[
                FloatingActionButton.extended(
                  heroTag: 'add_section_mobile',
                  onPressed: () => widget.controller.addSection(),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une section'),
                  tooltip: 'Ajouter une section au devis',
                ),
                const SizedBox(height: 12),
              ],
              FloatingActionButton.extended(
                heroTag: 'preview_pdf_mobile',
                onPressed: () =>
                    _pickAndPreviewDevis(context, widget.controller),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Aperçu PDF'),
                tooltip:
                    'Choisir un modèle puis enregistrer et prévisualiser',
              ),
            ],
          ),
        ),
      ],
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

  const _SectionTitleField({required this.section, required this.onChanged});

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

class _SectionCardDevis extends StatefulWidget {
  final CreateDevisController controller;
  final int sectionIndex;
  final Responsive r;

  const _SectionCardDevis({
    super.key,
    required this.controller,
    required this.sectionIndex,
    required this.r,
  });

  @override
  State<_SectionCardDevis> createState() => _SectionCardDevisState();
}

class _SectionCardDevisState extends State<_SectionCardDevis> {
  late final TextEditingController _moPercentCtrl;

  CreateDevisController get c => widget.controller;

  SectionDevis get section => c.sections[widget.sectionIndex];

  /// Champ libre pour un `double` (ex. `15`, `15.5`) — évite `"15.0"` figé qui gêne la saisie.
  static String _percentAsFieldText(double p) {
    if (p <= 0 || p.abs() < 1e-9) return '';
    final r = p.roundToDouble();
    if ((p - r).abs() < 1e-9) return r.toInt().toString();
    return p.toString();
  }

  @override
  void initState() {
    super.initState();
    _moPercentCtrl = TextEditingController(
      text: _percentAsFieldText(section.mainOeuvrePercent),
    );
  }

  @override
  void dispose() {
    _moPercentCtrl.dispose();
    super.dispose();
  }

  /// Après clamp / rechargement, réaligner le texte uniquement si le modèle ne correspond plus à la saisie affichée.
  @override
  void didUpdateWidget(covariant _SectionCardDevis oldWidget) {
    super.didUpdateWidget(oldWidget);
    final modelP = section.mainOeuvrePercent;
    final raw = _moPercentCtrl.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) {
      if (modelP <= 0) return;
      final t = _percentAsFieldText(modelP);
      if (_moPercentCtrl.text != t) {
        _moPercentCtrl.value = TextEditingValue(
          text: t,
          selection: TextSelection.collapsed(offset: t.length),
        );
      }
      return;
    }
    final typed = double.tryParse(raw);
    if (typed == null) return;
    if ((typed - modelP).abs() < 1e-6) return;
    final t = _percentAsFieldText(modelP);
    if (_moPercentCtrl.text != t) {
      _moPercentCtrl.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    }
  }

  void _onMainOeuvrePercentChanged(String v) {
    final t = v.trim();
    if (t.isEmpty) {
      c.setSectionMainOeuvrePercent(widget.sectionIndex, 0);
      return;
    }
    final d = double.tryParse(t.replaceAll(',', '.'));
    if (d != null) {
      c.setSectionMainOeuvrePercent(widget.sectionIndex, d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final idx = widget.sectionIndex;
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
                    onPressed: () => c.removeSectionAt(idx),
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
                      hintText: '15 ou 15,5 — nombre décimal libre',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    controller: _moPercentCtrl,
                    onChanged: _onMainOeuvrePercentChanged,
                  ),
                ),
                const SizedBox(width: 12),
                if (section.mainOeuvre > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '= ${section.mainOeuvre.toStringAsFixed(0)} $kCurrencyLabel',
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
                key: ValueKey('$idx-$index'),
                controller: c,
                sectionIndex: idx,
                itemIndex: index,
                item: item,
                isCompact: r.isCompact,
              );
            }),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _showAddLigneModal(context, c, idx),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Ajouter une ligne'),
            ),
            const Divider(height: 24),
            Text(
              'Total section : ${section.totalSection.toStringAsFixed(0)} $kCurrencyLabel',
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

  /// Code d'unité sélectionné. Pré-rempli depuis la désignation choisie dans
  /// l'autocomplete, sinon « unité » par défaut.
  String _unite = DevisUnit.unite.code;

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
      _errorPrixUnitaire = pu < 0
          ? 'Le prix unitaire ne peut pas être négatif'
          : null;
    });

    return _errorDesignation == null &&
        _errorQuantite == null &&
        _errorPrixUnitaire == null;
  }

  Future<void> _onAdd() async {
    if (!_validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez remplir tous les champs obligatoires correctement',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final nom = (_designationFieldController?.text.trim() ?? '').trim();
    final category = widget.category?.trim().isEmpty == true
        ? ''
        : (widget.category ?? '');
    try {
      final c = Get.find<CreateDevisController>();
      final wasCreated = await c.addItemFromModal(
        widget.sectionIndex,
        nom,
        _quantite,
        _prixUnitaire,
        widget.category,
        _unite,
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
                  _prixUnitaireController.text = d.prixUnitaire.toStringAsFixed(
                    0,
                  );
                  // Pré-remplir l'unité avec celle par défaut de la désignation.
                  _unite = DevisUnit.fromCode(d.uniteDefaut).code;
                  setState(() {});
                },
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      if (_designationFieldController !=
                          textEditingController) {
                        _designationFieldController?.removeListener(
                          _onFieldsChanged,
                        );
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
                              subtitle: Text(
                                '${d.prixUnitaire.toStringAsFixed(0)} $kCurrencyLabel',
                              ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
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
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _UnitChip(
                      code: _unite,
                      dense: false,
                      onChanged: (v) => setState(() => _unite = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _prixUnitaireController,
                decoration: InputDecoration(
                  labelText: 'Prix unitaire ($kCurrencyLabel) *',
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
                        '${_total.toStringAsFixed(0)} $kCurrencyLabel',
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
                  Icon(
                    Icons.drag_handle,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.designation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: _buildRowContent(context),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: isHighlight
                ? BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Qte',
                    ),
                    keyboardType: TextInputType.number,
                    controller:
                        TextEditingController(text: item.quantite.toString())
                          ..selection = TextSelection.collapsed(
                            offset: item.quantite.toString().length,
                          ),
                    onChanged: (v) => _update(
                      quantite: double.tryParse(v.replaceAll(',', '.')) ?? 0,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _UnitChip(
                    code: item.unite,
                    onChanged: (v) => _update(unite: v),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: TextField(
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'PU',
                    ),
                    keyboardType: TextInputType.number,
                    controller:
                        TextEditingController(
                            text: item.prixUnitaire.toStringAsFixed(0),
                          )
                          ..selection = TextSelection.collapsed(
                            offset: item.prixUnitaire.toStringAsFixed(0).length,
                          ),
                    onChanged: (v) => _update(
                      prixUnitaire:
                          double.tryParse(v.replaceAll(',', '.')) ?? 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: 64,
                    child: Text(
                      '${item.total.toStringAsFixed(0)} $kCurrencyLabel',
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
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _UnitChip(
            code: item.unite,
            onChanged: (v) => _update(unite: v),
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
            '${item.total.toStringAsFixed(0)} $kCurrencyLabel',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        _buildActionButtons(context),
      ],
    );
  }

  void _update({
    String? designation,
    double? quantite,
    double? prixUnitaire,
    String? unite,
  }) {
    controller.updateItemInSection(
      sectionIndex,
      itemIndex,
      DevisItem(
        designation: designation ?? item.designation,
        quantite: quantite ?? item.quantite,
        prixUnitaire: prixUnitaire ?? item.prixUnitaire,
        designationId: item.designationId,
        unite: unite ?? item.unite,
      ),
    );
  }
}

/// Sélecteur d'unité compact — affiché comme une puce cliquable avec le symbole
/// (`m`, `kg`, `m²`, …). Au tap : menu déroulant groupé par catégorie.
///
/// Utilisé dans [_ItemRow] et la modale d'ajout pour ne pas alourdir l'UI.
class _UnitChip extends StatelessWidget {
  final String code;
  final ValueChanged<String> onChanged;
  final bool dense;

  const _UnitChip({
    required this.code,
    required this.onChanged,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = DevisUnit.fromCode(code);
    return PopupMenuButton<String>(
      tooltip: 'Choisir l’unité (${unit.label})',
      initialValue: unit.code,
      onSelected: onChanged,
      itemBuilder: (context) => _buildMenuItems(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 10 : 12,
          vertical: dense ? 9 : 11,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              unit.symbole,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <PopupMenuEntry<String>>[];
    DevisUnitCategory? lastCategory;
    for (final u in DevisUnit.all) {
      if (lastCategory != null && u.categorie != lastCategory) {
        entries.add(const PopupMenuDivider(height: 8));
      }
      lastCategory = u.categorie;
      entries.add(PopupMenuItem<String>(
        value: u.code,
        height: 36,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                u.symbole,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                u.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ));
    }
    return entries;
  }
}


// =====================================================================
// Helpers PDF — sélection de modèle + aperçu
// =====================================================================

/// Demande à l'utilisateur de choisir un modèle de couverture, sauvegarde
/// le devis courant, puis ouvre l'aperçu PDF avec le modèle choisi.
Future<void> _pickAndPreviewDevis(
  BuildContext context,
  CreateDevisController c,
) async {
  final template = await CoverPickerSheet.show(
    context,
    confirmLabel: 'Aperçu PDF',
  );
  if (template == null) return;
  try {
    final devis = c.buildCurrentDevis();
    final dc = Get.find<DevisController>();
    await dc.saveDevis(devis);
    c.editingDevisId = devis.id;
    await dc.previewPdf(devis, template: template);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur PDF: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
