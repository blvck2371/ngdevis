import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/controllers/devis_controller.dart';
import '../core/controllers/facture_controller.dart';
import '../core/models/devis.dart';
import '../core/models/devis_status.dart';
import '../core/models/facture.dart';
import '../core/models/facture_status.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_currency.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/responsive.dart';
import '../core/widgets/app_bottom_nav.dart';
import '../core/widgets/status_badge.dart';
import 'cover_picker_sheet.dart';

/// Écran "Documents" : onglets **Devis / Factures**.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // Filtres par onglet
  DevisStatus? _devisFilter;
  FactureStatus? _factureFilter;

  // Recherche globale (numéro / client)
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.find<DevisController>().load();
      Get.find<FactureController>().load();
    });
    _searchCtrl.addListener(() {
      if (!mounted) return;
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final r = context.responsive;
    final bottomNavSpace = 92.0 + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Documents'),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: p.surfaceLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.outlineSoft, width: 0.6),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: p.accent.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: p.ink,
                unselectedLabelColor: p.inkMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(text: 'Devis'),
                  Tab(text: 'Factures'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Barre de recherche + filtres
            Padding(
              padding: EdgeInsets.fromLTRB(r.horizontalPadding, 8, r.horizontalPadding, 6),
              child: _SearchAndFilters(
                query: _query,
                searchController: _searchCtrl,
                isDevisTab: _tab.index == 0,
                devisFilter: _devisFilter,
                factureFilter: _factureFilter,
                onDevisFilter: (v) => setState(() => _devisFilter = v),
                onFactureFilter: (v) => setState(() => _factureFilter = v),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                physics: const BouncingScrollPhysics(),
                children: [
                  _DevisTab(
                    query: _query,
                    filter: _devisFilter,
                    bottomPadding: 24 + bottomNavSpace,
                  ),
                  _FacturesTab(
                    query: _query,
                    filter: _factureFilter,
                    bottomPadding: 24 + bottomNavSpace,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(active: AppTab.devis),
    );
  }
}

// ============================================================================
// SEARCH + FILTERS
// ============================================================================

class _SearchAndFilters extends StatelessWidget {
  final String query;
  final TextEditingController searchController;
  final bool isDevisTab;
  final DevisStatus? devisFilter;
  final FactureStatus? factureFilter;
  final ValueChanged<DevisStatus?> onDevisFilter;
  final ValueChanged<FactureStatus?> onFactureFilter;

  const _SearchAndFilters({
    required this.query,
    required this.searchController,
    required this.isDevisTab,
    required this.devisFilter,
    required this.factureFilter,
    required this.onDevisFilter,
    required this.onFactureFilter,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher un numéro ou un client…',
            prefixIcon: Icon(Icons.search_rounded, color: p.inkMuted),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close_rounded, color: p.inkMuted, size: 18),
                    onPressed: searchController.clear,
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: isDevisTab
              ? _DevisFilterChips(active: devisFilter, onChange: onDevisFilter)
              : _FactureFilterChips(active: factureFilter, onChange: onFactureFilter),
        ),
      ],
    );
  }
}

class _DevisFilterChips extends StatelessWidget {
  final DevisStatus? active;
  final ValueChanged<DevisStatus?> onChange;
  const _DevisFilterChips({required this.active, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final all = [
      null,
      ...DevisStatus.values,
    ];
    return Row(
      children: [
        for (final s in all) ...[
          _FilterChip(
            label: s == null ? 'Tous' : s.label,
            icon: s?.icon,
            active: active == s,
            onTap: () => onChange(s),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _FactureFilterChips extends StatelessWidget {
  final FactureStatus? active;
  final ValueChanged<FactureStatus?> onChange;
  const _FactureFilterChips({required this.active, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final all = [
      null,
      ...FactureStatus.values,
    ];
    return Row(
      children: [
        for (final s in all) ...[
          _FilterChip(
            label: s == null ? 'Toutes' : s.label,
            icon: s?.icon,
            active: active == s,
            onTap: () => onChange(s),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? p.accent.withValues(alpha: 0.16) : p.surfaceLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? p.accent.withValues(alpha: 0.6) : p.outlineSoft,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: active ? p.accent : p.inkMuted, size: 14),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: active ? p.accent : p.ink,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12.5,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TAB DEVIS
// ============================================================================

class _DevisTab extends StatelessWidget {
  final String query;
  final DevisStatus? filter;
  final double bottomPadding;

  const _DevisTab({
    required this.query,
    required this.filter,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DevisController>();
    final r = context.responsive;
    return Obx(() {
      final all = c.list.where((d) {
        if (filter != null && d.status != filter) return false;
        if (query.isEmpty) return true;
        final inNum = d.numero.toLowerCase().contains(query);
        final inClient = (d.client?.nom ?? '').toLowerCase().contains(query) ||
            (d.client?.societe ?? '').toLowerCase().contains(query);
        return inNum || inClient;
      }).toList();
      if (all.isEmpty) {
        return _EmptyState(
          icon: Icons.description_outlined,
          title: filter == null && query.isEmpty
              ? 'Aucun devis enregistré'
              : 'Aucun résultat',
          subtitle: filter == null && query.isEmpty
              ? 'Touchez le bouton + en bas pour créer votre premier devis.'
              : 'Affinez votre recherche ou changez de filtre.',
        );
      }
      return ListView.builder(
        padding: EdgeInsets.fromLTRB(
          r.horizontalPadding,
          12,
          r.horizontalPadding,
          bottomPadding,
        ),
        itemCount: all.length,
        itemBuilder: (context, i) => _DevisTile(devis: all[i]),
      );
    });
  }
}

// ============================================================================
// TAB FACTURES
// ============================================================================

class _FacturesTab extends StatelessWidget {
  final String query;
  final FactureStatus? filter;
  final double bottomPadding;

  const _FacturesTab({
    required this.query,
    required this.filter,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FactureController>();
    final r = context.responsive;
    return Obx(() {
      final all = c.list.where((f) {
        if (filter != null && f.status != filter) return false;
        if (query.isEmpty) return true;
        final inNum = f.numero.toLowerCase().contains(query);
        final inClient = (f.client?.nom ?? '').toLowerCase().contains(query) ||
            (f.client?.societe ?? '').toLowerCase().contains(query);
        return inNum || inClient;
      }).toList();
      if (all.isEmpty) {
        return _EmptyState(
          icon: Icons.receipt_long_outlined,
          title: filter == null && query.isEmpty
              ? 'Aucune facture'
              : 'Aucun résultat',
          subtitle: filter == null && query.isEmpty
              ? 'Convertissez un devis accepté pour générer votre première facture.'
              : 'Affinez votre recherche ou changez de filtre.',
        );
      }
      return ListView.builder(
        padding: EdgeInsets.fromLTRB(
          r.horizontalPadding,
          12,
          r.horizontalPadding,
          bottomPadding,
        ),
        itemCount: all.length,
        itemBuilder: (context, i) => _FactureTile(facture: all[i]),
      );
    });
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.accent.withValues(alpha: 0.12),
                border: Border.all(color: p.accent.withValues(alpha: 0.22), width: 0.7),
              ),
              child: Icon(icon, size: 36, color: p.accent),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: p.ink,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: p.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DEVIS TILE
// ============================================================================

class _DevisTile extends StatelessWidget {
  final Devis devis;
  const _DevisTile({required this.devis});

  @override
  Widget build(BuildContext context) {
    final dc = Get.find<DevisController>();
    final p = AppColors.of(context);
    final theme = Theme.of(context);
    final clientName = devis.client?.nom.trim();
    final clientLine =
        (clientName == null || clientName.isEmpty) ? 'Sans client' : clientName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => Get.toNamed(
            AppRoutes.createDevis,
            arguments: {'devisId': devis.id},
          ),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.outlineSoft, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            p.accent.withValues(alpha: 0.20),
                            p.gold.withValues(alpha: 0.20),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'N°',
                          style: TextStyle(
                            color: p.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Devis ${devis.numero}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$clientLine · ${_formatDate(devis.date)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: p.inkMuted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_formatNumberFr(devis.total)} $kCurrencyLabel',
                          style: TextStyle(
                            color: p.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          child: PopupMenuButton<String>(
                            tooltip: 'Actions',
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            icon: Icon(Icons.more_horiz_rounded, color: p.inkMuted),
                            onSelected: (v) => _onAction(context, v, dc),
                            itemBuilder: (context) => _buildMenu(devis),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StatusBadge(
                      label: devis.status.label,
                      icon: devis.status.icon,
                      toneCode: devis.status.toneCode,
                      compact: true,
                    ),
                    if (devis.validUntil != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.surfaceLow,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: p.outlineSoft, width: 0.6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_rounded, size: 11, color: p.inkMuted),
                            const SizedBox(width: 4),
                            Text(
                              'Valable jusqu\'au ${_formatDate(devis.validUntil!)}',
                              style: TextStyle(
                                color: p.inkMuted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenu(Devis d) {
    final entries = <PopupMenuEntry<String>>[
      const PopupMenuItem(
        value: 'view',
        child: Row(children: [Icon(Icons.edit_outlined, size: 19), SizedBox(width: 12), Text('Voir / Modifier')]),
      ),
      const PopupMenuItem(
        value: 'duplicate',
        child: Row(children: [Icon(Icons.copy_rounded, size: 19), SizedBox(width: 12), Text('Dupliquer')]),
      ),
      const PopupMenuItem(
        value: 'pdf',
        child: Row(children: [Icon(Icons.picture_as_pdf_rounded, size: 19), SizedBox(width: 12), Text('Aperçu PDF')]),
      ),
      const PopupMenuItem(
        value: 'share',
        child: Row(children: [Icon(Icons.share_rounded, size: 19), SizedBox(width: 12), Text('Partager PDF')]),
      ),
      const PopupMenuDivider(),
    ];

    if (d.status == DevisStatus.brouillon) {
      entries.add(const PopupMenuItem(
        value: 'sent',
        child: Row(children: [Icon(Icons.send_rounded, size: 19), SizedBox(width: 12), Text('Marquer envoyé')]),
      ));
    }
    if (d.status == DevisStatus.envoye || d.status == DevisStatus.expire) {
      entries.add(const PopupMenuItem(
        value: 'accept',
        child: Row(children: [Icon(Icons.check_circle_outline_rounded, size: 19), SizedBox(width: 12), Text('Marquer accepté')]),
      ));
      entries.add(const PopupMenuItem(
        value: 'refuse',
        child: Row(children: [Icon(Icons.cancel_outlined, size: 19), SizedBox(width: 12), Text('Marquer refusé')]),
      ));
    }
    if (d.status.canConvertToFacture) {
      entries.add(const PopupMenuItem(
        value: 'convert',
        child: Row(children: [Icon(Icons.receipt_long_rounded, size: 19), SizedBox(width: 12), Text('Convertir en facture')]),
      ));
    }
    entries.add(const PopupMenuDivider());
    entries.add(const PopupMenuItem(
      value: 'delete',
      child: Row(children: [Icon(Icons.delete_outline_rounded, size: 19), SizedBox(width: 12), Text('Supprimer')]),
    ));
    return entries;
  }

  void _onAction(BuildContext context, String action, DevisController dc) async {
    switch (action) {
      case 'view':
        Get.toNamed(AppRoutes.createDevis, arguments: {'devisId': devis.id});
        break;
      case 'duplicate':
        dc.duplicateDevis(devis);
        _snack(context, 'Devis dupliqué');
        break;
      case 'pdf':
        {
          final template = await CoverPickerSheet.show(
            context,
            confirmLabel: 'Aperçu PDF',
            previewData: CoverPreviewData.fromDevis(devis),
          );
          if (template != null) {
            await dc.previewPdf(devis, template: template);
          }
        }
        break;
      case 'share':
        {
          final template = await CoverPickerSheet.show(
            context,
            confirmLabel: 'Partager le PDF',
            previewData: CoverPreviewData.fromDevis(devis),
          );
          if (template != null) {
            await dc.sharePdf(devis, template: template);
          }
        }
        break;
      case 'sent':
        await dc.markSent(devis.id);
        if (context.mounted) _snack(context, 'Devis marqué envoyé');
        break;
      case 'accept':
        await dc.markAccepted(devis.id);
        if (context.mounted) _snack(context, 'Devis accepté');
        break;
      case 'refuse':
        await dc.markRefused(devis.id);
        if (context.mounted) _snack(context, 'Devis refusé');
        break;
      case 'convert':
        await _convertDialog(context, dc);
        break;
      case 'delete':
        _confirmDelete(context, dc);
        break;
    }
  }

  Future<void> _convertDialog(BuildContext context, DevisController dc) async {
    DateTime due = DateTime.now().add(const Duration(days: 30));
    String terms = '';
    final p = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: const Text('Convertir en facture'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Le devis ${devis.numero} va être converti en facture. Le contenu sera copié et le devis sera verrouillé en statut « Facturé ».',
                  style: TextStyle(color: p.inkMuted, fontSize: 13),
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: due,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) setSt(() => due = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: p.surfaceLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.outlineSoft),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_rounded, color: p.accent, size: 18),
                        const SizedBox(width: 10),
                        const Text('Échéance', style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(_formatDate(due), style: TextStyle(color: p.ink, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Modalités de paiement (optionnel)',
                    hintText: 'Ex : 30% à la commande, solde à réception',
                  ),
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (v) => terms = v,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final f = await dc.convertToFacture(
                      devis.id,
                      dueDate: due,
                      paymentTerms: terms,
                    );
                    if (context.mounted) {
                      _snack(context, 'Facture ${f.numero} créée');
                      Get.toNamed(AppRoutes.factureDetail, arguments: {'factureId': f.id});
                    }
                  } catch (e) {
                    if (context.mounted) _snack(context, 'Erreur : $e');
                  }
                },
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text('Convertir'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, DevisController dc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le devis ?'),
        content: Text('Le devis ${devis.numero} sera définitivement supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              dc.deleteDevis(devis.id);
              Navigator.pop(ctx);
              _snack(context, 'Devis supprimé');
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FACTURE TILE
// ============================================================================

class _FactureTile extends StatelessWidget {
  final Facture facture;
  const _FactureTile({required this.facture});

  @override
  Widget build(BuildContext context) {
    final fc = Get.find<FactureController>();
    final p = AppColors.of(context);
    final theme = Theme.of(context);
    final clientName = facture.client?.nom.trim();
    final clientLine =
        (clientName == null || clientName.isEmpty) ? 'Sans client' : clientName;
    final ratio = facture.paidRatio;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => Get.toNamed(
            AppRoutes.factureDetail,
            arguments: {'factureId': facture.id},
          ),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.outlineSoft, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            p.gold.withValues(alpha: 0.25),
                            p.accent.withValues(alpha: 0.18),
                          ],
                        ),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: p.gold, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Facture ${facture.numero}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$clientLine · ${_formatDate(facture.date)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: p.inkMuted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_formatNumberFr(facture.total)} $kCurrencyLabel',
                          style: TextStyle(
                            color: p.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (facture.remaining > 0)
                          Text(
                            'Reste ${_formatNumberFr(facture.remaining)} $kCurrencyLabel',
                            style: TextStyle(
                              color: p.inkMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            'Soldée',
                            style: TextStyle(
                              color: p.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(
                      height: 28,
                      child: PopupMenuButton<String>(
                        tooltip: 'Actions',
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: Icon(Icons.more_horiz_rounded, color: p.inkMuted),
                        onSelected: (v) => _onAction(context, v, fc),
                        itemBuilder: (context) => _buildMenu(facture),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Barre de progression encaissement
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 4,
                    backgroundColor: p.surfaceLow,
                    valueColor: AlwaysStoppedAnimation(
                      facture.status == FactureStatus.payee ? p.success : p.gold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StatusBadge(
                      label: facture.status.label,
                      icon: facture.status.icon,
                      toneCode: facture.status.toneCode,
                      compact: true,
                    ),
                    if (facture.dueDate != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: facture.isOverdue
                              ? p.error.withValues(alpha: 0.10)
                              : p.surfaceLow,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: facture.isOverdue
                                ? p.error.withValues(alpha: 0.35)
                                : p.outlineSoft,
                            width: 0.6,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_rounded,
                              size: 11,
                              color: facture.isOverdue ? p.error : p.inkMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Échéance ${_formatDate(facture.dueDate!)}',
                              style: TextStyle(
                                color: facture.isOverdue ? p.error : p.inkMuted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenu(Facture f) {
    final entries = <PopupMenuEntry<String>>[
      const PopupMenuItem(
        value: 'open',
        child: Row(children: [Icon(Icons.open_in_new_rounded, size: 19), SizedBox(width: 12), Text('Ouvrir')]),
      ),
      const PopupMenuItem(
        value: 'pdf',
        child: Row(children: [Icon(Icons.picture_as_pdf_rounded, size: 19), SizedBox(width: 12), Text('Aperçu PDF')]),
      ),
      const PopupMenuItem(
        value: 'share',
        child: Row(children: [Icon(Icons.share_rounded, size: 19), SizedBox(width: 12), Text('Partager PDF')]),
      ),
      const PopupMenuDivider(),
    ];
    if (f.status == FactureStatus.brouillon) {
      entries.add(const PopupMenuItem(
        value: 'sent',
        child: Row(children: [Icon(Icons.send_rounded, size: 19), SizedBox(width: 12), Text('Marquer envoyée')]),
      ));
    }
    if (f.status.canRecordPayment) {
      entries.add(const PopupMenuItem(
        value: 'pay',
        child: Row(children: [Icon(Icons.payments_rounded, size: 19), SizedBox(width: 12), Text('Marquer payée')]),
      ));
    }
    if (f.status != FactureStatus.annulee) {
      entries.add(const PopupMenuItem(
        value: 'cancel',
        child: Row(children: [Icon(Icons.block_rounded, size: 19), SizedBox(width: 12), Text('Annuler la facture')]),
      ));
    }
    entries.add(const PopupMenuDivider());
    entries.add(const PopupMenuItem(
      value: 'delete',
      child: Row(children: [Icon(Icons.delete_outline_rounded, size: 19), SizedBox(width: 12), Text('Supprimer')]),
    ));
    return entries;
  }

  void _onAction(BuildContext context, String action, FactureController fc) async {
    switch (action) {
      case 'open':
        Get.toNamed(AppRoutes.factureDetail, arguments: {'factureId': facture.id});
        break;
      case 'pdf':
        fc.previewPdf(facture);
        break;
      case 'share':
        fc.sharePdf(facture);
        break;
      case 'sent':
        await fc.markSent(facture.id);
        if (context.mounted) _snack(context, 'Facture marquée envoyée');
        break;
      case 'pay':
        await fc.markFullyPaid(facture.id);
        if (context.mounted) _snack(context, 'Facture soldée');
        break;
      case 'cancel':
        await fc.markCancelled(facture.id);
        if (context.mounted) _snack(context, 'Facture annulée');
        break;
      case 'delete':
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer la facture ?'),
            content: Text('La facture ${facture.numero} sera définitivement supprimée.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              FilledButton(
                onPressed: () {
                  fc.deleteFacture(facture.id);
                  Navigator.pop(ctx);
                  _snack(context, 'Facture supprimée');
                },
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
        break;
    }
  }
}

// ============================================================================
// HELPERS GLOBAUX
// ============================================================================

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _formatNumberFr(double v) {
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

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}
