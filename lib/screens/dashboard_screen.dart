import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../core/controllers/devis_controller.dart';
import '../core/controllers/designation_controller.dart';
import '../core/controllers/company_controller.dart';
import '../core/database/hive_storage.dart';
import '../core/services/backup_service.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/responsive.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const List<_DashboardCardData> _cards = [
    _DashboardCardData(
      icon: Icons.add_circle_outline,
      title: 'Créer un devis',
      subtitle: 'Choisir les catégories puis composer le devis',
      route: null,
      isCreateDevis: true,
    ),
    _DashboardCardData(
      icon: Icons.history,
      title: 'Historique des devis',
      subtitle: 'Voir, exporter ou supprimer les devis',
      route: AppRoutes.history,
      isCreateDevis: false,
    ),
    _DashboardCardData(
      icon: Icons.category_outlined,
      title: 'Enregistrer les catégories',
      subtitle: 'Créer et gérer les catégories (Plomberie, Maçonnerie…)',
      route: AppRoutes.categories,
      isCreateDevis: false,
    ),
    _DashboardCardData(
      icon: Icons.import_export_rounded,
      title: 'Import / Export (JSON)',
      subtitle: 'Importer ou exporter catégories et désignations',
      route: null,
      isImportExport: true,
    ),
    _DashboardCardData(
      icon: Icons.save_rounded,
      title: 'Sauvegarde',
      subtitle: 'Sauvegarder ou restaurer toute l\'app (catégories, devis, paramètres)',
      route: null,
      isBackup: true,
    ),
    _DashboardCardData(
      icon: Icons.settings_outlined,
      title: 'Paramètres entreprise',
      subtitle: 'Logo, nom, téléphone, adresse',
      route: AppRoutes.settings,
      isCreateDevis: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final theme = Theme.of(context);
    final isGrid = r.gridColumns > 1;
    final maxW = r.isExpanded ? 1000.0 : double.infinity;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      r.horizontalPadding,
                      r.isCompact ? 20 : 28,
                      r.horizontalPadding,
                      r.isCompact ? 18 : 24,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.35),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(r.isCompact ? 10 : 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(r.isCompact ? 12 : 16),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: r.isCompact ? 28 : 32,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: r.isCompact ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NG Devis',
                                style: (r.isCompact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Créez et gérez vos devis',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      r.horizontalPadding,
                      r.isCompact ? 16 : 20,
                      r.horizontalPadding,
                      24 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: isGrid
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = r.gridColumns;
                              const spacing = 12.0;
                              final totalSpacing = spacing * (crossAxisCount - 1);
                              final childWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
                              final aspectRatio = r.isCompact ? 1.4 : (r.isMedium ? 1.25 : 1.05);
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: _cards.map((data) => SizedBox(
                                  width: childWidth,
                                  child: AspectRatio(
                                    aspectRatio: aspectRatio,
                                    child: _DashboardCard(
                                      icon: data.icon,
                                      title: data.title,
                                      subtitle: data.subtitle,
                                      compact: r.isCompact,
                                      onTap: () => _onCardTap(context, data),
                                    ),
                                  ),
                                )).toList(),
                              );
                            },
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < _cards.length; i++) ...[
                                _DashboardCard(
                                  icon: _cards[i].icon,
                                  title: _cards[i].title,
                                  subtitle: _cards[i].subtitle,
                                  compact: r.isCompact,
                                  onTap: () => _onCardTap(context, _cards[i]),
                                ),
                                if (i < _cards.length - 1) SizedBox(height: r.isCompact ? 10 : 12),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCardTap(BuildContext context, _DashboardCardData data) {
    if (data.isCreateDevis) {
      _goCreateDevis(null);
    } else if (data.isImportExport) {
      _showImportExportSheet(context);
    } else if (data.isBackup) {
      _showBackupSheet(context);
    } else if (data.route != null) {
      Get.toNamed(data.route!);
    }
  }

  void _showBackupSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.save_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Sauvegarde complète',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Catégories, désignations, historique des devis et paramètres entreprise',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.upload_rounded, color: Theme.of(context).colorScheme.primary),
                title: const Text('Sauvegarder tout'),
                subtitle: const Text('Choisir un dossier du téléphone (ex. Téléchargements) et enregistrer le fichier JSON'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _backupAll(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.restore_rounded, color: Theme.of(context).colorScheme.primary),
                title: const Text('Restaurer tout'),
                subtitle: const Text('Importer une sauvegarde (remplace les données actuelles)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _restoreAll(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.restart_alt_rounded, color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Tout réinitialiser',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                subtitle: const Text('Supprimer toutes les données (catégories, devis, paramètres)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showResetConfirmation(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 48),
        title: const Text('Tout réinitialiser ?'),
        content: const Text(
          'Toutes les données seront supprimées : catégories, désignations, historique des devis et paramètres entreprise.\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await HiveStorage.resetAll();
              Get.find<DesignationController>().load();
              Get.find<DevisController>().load();
              Get.find<CompanyController>().load();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Application réinitialisée'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Réinitialiser tout'),
          ),
        ],
      ),
    );
  }

  Future<void> _backupAll(BuildContext context) async {
    try {
      final path = await BackupService.saveToPhoneFolder();
      if (context.mounted) {
        String message;
        if (path != null && path.isNotEmpty) {
          if (path.toLowerCase().contains('download')) {
            message = 'Sauvegarde enregistrée dans Téléchargements';
          } else {
            message = 'Sauvegarde enregistrée sur le téléphone';
          }
        } else {
          message = 'Enregistrement annulé';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
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
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _restoreAll(BuildContext context) async {
    try {
      final result = await BackupService.importFromFile();
      if (result.cancelled) return;
      Get.find<DesignationController>().load();
      Get.find<DevisController>().load();
      Get.find<CompanyController>().load();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restauration terminée : ${result.categoriesCount} catégorie(s), '
              '${result.designationsCount} désignation(s), ${result.devisCount} devis.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on FormatException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier invalide : $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _goCreateDevis(String? id) {
    if (id != null) {
      final devis = Get.find<DevisController>().getById(id);
      if (devis != null) {
        Get.toNamed(AppRoutes.createDevis, arguments: devis);
      } else {
        Get.toNamed(AppRoutes.createDevis);
      }
    } else {
      Get.toNamed(AppRoutes.chooseCategory);
    }
  }

  void _showImportExportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Import / Export (JSON)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Catégories et désignations',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.upload_file, color: Theme.of(context).colorScheme.primary),
                title: const Text('Importer'),
                subtitle: const Text('Charger depuis un fichier JSON'),
                onTap: () {
                  Navigator.pop(ctx);
                  _importJson(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.download, color: Theme.of(context).colorScheme.primary),
                title: const Text('Exporter'),
                subtitle: const Text('Enregistrer en fichier JSON'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportJson(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importJson(BuildContext context) async {
    final dc = Get.find<DesignationController>();
    final result = await dc.importJson();
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

  Future<void> _exportJson(BuildContext context) async {
    final dc = Get.find<DesignationController>();
    if (dc.list.isEmpty) {
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
      final jsonStr = dc.exportJson();
      final bytes = utf8.encode(jsonStr);
      final fileName = 'designations_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.json';
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer les désignations (JSON)',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(path != null && path.isNotEmpty ? 'Fichier enregistré' : 'Enregistrement effectué'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

class _DashboardCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;
  final bool isCreateDevis;
  final bool isImportExport;
  final bool isBackup;

  const _DashboardCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
    this.isCreateDevis = false,
    this.isImportExport = false,
    this.isBackup = false,
  });
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool compact;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = compact ? 14.0 : 20.0;
    final iconSize = compact ? 22.0 : 26.0;
    final borderRadius = compact ? 16.0 : 20.0;

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 10 : 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(compact ? 12 : 16),
                ),
                child: Icon(icon, size: iconSize, color: theme.colorScheme.primary),
              ),
              SizedBox(width: compact ? 12 : 18),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: (compact ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: compact ? 2 : 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: compact ? 22 : 28,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
