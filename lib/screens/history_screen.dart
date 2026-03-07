import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/controllers/devis_controller.dart';
import '../core/models/devis.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/responsive.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Recharger la liste depuis le stockage JSON (Hive) à chaque ouverture de l'écran
    Get.find<DevisController>().load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DevisController>();
    final r = context.responsive;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des devis'),
      ),
      body: SafeArea(
        child: Obx(() {
          if (c.list.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(r.horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun devis enregistré',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez un devis depuis le tableau de bord',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
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
              24 + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: c.list.length,
            itemBuilder: (context, i) {
              final d = c.list[i];
              return _DevisTile(devis: d);
            },
          );
        }),
      ),
    );
  }
}

class _DevisTile extends StatelessWidget {
  final Devis devis;

  const _DevisTile({required this.devis});

  @override
  Widget build(BuildContext context) {
    final dc = Get.find<DevisController>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.responsive.horizontalPadding,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.description, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text(
          'Devis n° ${devis.numero}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${devis.client?.nom ?? "Sans client"} • ${_formatDate(devis.date)} • ${_formatPrice(devis.total)}',
        ),
        isThreeLine: true,
        onTap: () => Get.toNamed(AppRoutes.createDevis, arguments: devis.toJson()),
        trailing: PopupMenuButton<String>(
          tooltip: 'Actions',
          onSelected: (v) => _onAction(context, v, dc),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Voir / Modifier')])),
            const PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.copy, size: 20), SizedBox(width: 12), Text('Dupliquer')])),
            const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf, size: 20), SizedBox(width: 12), Text('Exporter PDF')])),
            const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 20), SizedBox(width: 12), Text('Partager PDF')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 20), SizedBox(width: 12), Text('Supprimer')])),
          ],
        ),
      ),
    );
  }

  void _onAction(BuildContext context, String action, DevisController dc) {
    switch (action) {
      case 'view':
        Get.toNamed(AppRoutes.createDevis, arguments: devis.toJson());
        break;
      case 'duplicate':
        dc.duplicateDevis(devis);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devis dupliqué'), behavior: SnackBarBehavior.floating),
        );
        break;
      case 'pdf':
        dc.previewPdf(devis);
        break;
      case 'share':
        dc.sharePdf(devis);
        break;
      case 'delete':
        _confirmDelete(context, dc);
        break;
    }
  }

  void _confirmDelete(BuildContext context, DevisController dc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le devis ?'),
        content: Text('Le devis n° ${devis.numero} sera définitivement supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              dc.deleteDevis(devis.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Devis supprimé'), behavior: SnackBarBehavior.floating),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatPrice(double v) => '${v.toStringAsFixed(0)} F';
}
