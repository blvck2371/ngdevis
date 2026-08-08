import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../core/controllers/company_controller.dart';
import '../core/controllers/designation_controller.dart';
import '../core/controllers/devis_controller.dart';
import '../core/controllers/facture_controller.dart';
import '../core/controllers/theme_controller.dart';
import '../core/database/hive_storage.dart';
import '../core/models/devis.dart';
import '../core/models/facture_status.dart';
import '../core/services/backup_service.dart';
import '../core/services/json_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_currency.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/responsive.dart';
import '../core/widgets/animated_counter.dart';
import '../core/widgets/app_bottom_nav.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/mesh_gradient_background.dart';
import '../core/widgets/revenue_chart.dart';

/// Dashboard premium 2026 — refonte complète mais préservation à 100 % des
/// actions existantes (créer devis, historique, catégories, import/export,
/// sauvegarde, paramètres).
///
/// Hiérarchie :
///   1. Hero avec revenu du mois + variation vs mois précédent + chart 12 mois
///   2. Grille de statistiques (4 mini-cards animées)
///   3. Actions rapides (chips défilantes)
///   4. Derniers devis (3 derniers, lien vers historique)
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final maxW = r.isExpanded ? 1080.0 : double.infinity;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: MeshGradientBackground(intensity: 0.45),
          ),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: const _DashboardContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(active: AppTab.home),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    // 92 = hauteur réelle de la nav bar (72) + ses paddings internes.
    final bottomNavSpace = 92.0 + MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        r.horizontalPadding,
        12,
        r.horizontalPadding,
        24 + bottomNavSpace,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _TopBar(),
          SizedBox(height: 18),
          _Greeting(),
          SizedBox(height: 20),
          _HeroCard(),
          SizedBox(height: 22),
          _SectionHeader(title: 'Aperçu'),
          SizedBox(height: 12),
          _StatsGrid(),
          SizedBox(height: 22),
          _SectionHeader(title: 'Mes factures', actionLabel: 'Voir tout'),
          SizedBox(height: 12),
          _FactureKpisCard(),
          SizedBox(height: 26),
          _SectionHeader(title: 'Actions rapides'),
          SizedBox(height: 12),
          _QuickActionsRow(),
          SizedBox(height: 26),
          _SectionHeader(title: 'Derniers devis', actionLabel: 'Voir tout'),
          SizedBox(height: 12),
          _RecentDevisList(),
        ],
      ),
    );
  }
}

// ============================================================================
// TOP BAR & GREETING
// ============================================================================

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final tc = Get.find<ThemeController>();

    return Row(
      children: [
        // Logo monogramme
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.accent, p.accentDeep],
            ),
            boxShadow: [
              BoxShadow(
                color: p.accent.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'N',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'NG Devis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
          ),
        ),
        // Bouton thème (auto/clair/sombre)
        Obx(() {
          // Lire mode.value pour réactivité
          tc.mode.value;
          return _IconChip(
            icon: tc.icon(),
            tooltip: 'Thème : ${tc.label()} (toucher pour changer)',
            onTap: tc.cycle,
          );
        }),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0);
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _IconChip({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.outlineSoft),
            ),
            child: Icon(icon, size: 20, color: p.ink),
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppColors.of(context);
    final company = Get.find<CompanyController>();

    return Obx(() {
      final nom = company.nom.value.trim();
      final h = DateTime.now().hour;
      final greeting = h < 12
          ? 'Bonjour'
          : h < 18
              ? 'Bon après-midi'
              : 'Bonsoir';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting${nom.isEmpty ? '' : ',  $nom'} 👋',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: p.inkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tableau de bord',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.05,
            ),
          ),
        ],
      ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.15, end: 0);
    });
  }
}

// ============================================================================
// HERO CARD : revenu du mois + chart
// ============================================================================

class _HeroCard extends StatefulWidget {
  const _HeroCard();

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
  RevenueChartStyle _style = RevenueChartStyle.line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppColors.of(context);
    final devisCtrl = Get.find<DevisController>();

    return Obx(() {
      final stats = _DevisStats.from(devisCtrl.list);
      final now = DateTime.now();
      final monthLabel = _frenchMonth(now.month);

      return GlassCard(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        tintOpacity: 0.78,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '$monthLabel ${now.year}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: p.inkMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                _VariationPill(percent: stats.monthChangePercent),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedCounter(
              value: stats.currentMonthRevenue,
              duration: const Duration(milliseconds: 1100),
              formatter: (v) => '${_formatNumber(v)} $kCurrencyLabel',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                color: p.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stats.currentMonthCount == 0
                  ? 'Aucun devis ce mois — créez-en un pour démarrer.'
                  : '${stats.currentMonthCount} devis créé(s) ce mois',
              style: theme.textTheme.bodySmall?.copyWith(
                color: p.inkMuted,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 18),
            RevenueChart(
              data: stats.monthlyRevenue,
              currentIndex: stats.monthlyRevenue.length - 1,
              style: _style,
              height: _style == RevenueChartStyle.pie ? 220 : 200,
            ),
            const SizedBox(height: 14),
            _ChartStyleToggle(
              current: _style,
              onChange: (s) => setState(() => _style = s),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.15, end: 0);
    });
  }
}

// ============================================================================
// CHART STYLE TOGGLE — 3 onglets Courbe / Barres / Camembert
// ============================================================================

class _ChartStyleToggle extends StatelessWidget {
  final RevenueChartStyle current;
  final ValueChanged<RevenueChartStyle> onChange;

  const _ChartStyleToggle({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.surfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.outlineSoft, width: 0.8),
      ),
      child: Row(
        children: [
          _ToggleItem(
            icon: Icons.show_chart_rounded,
            label: 'Courbe',
            active: current == RevenueChartStyle.line,
            onTap: () => onChange(RevenueChartStyle.line),
          ),
          _ToggleItem(
            icon: Icons.bar_chart_rounded,
            label: 'Barres',
            active: current == RevenueChartStyle.bars,
            onTap: () => onChange(RevenueChartStyle.bars),
          ),
          _ToggleItem(
            icon: Icons.pie_chart_rounded,
            label: 'Camembert',
            active: current == RevenueChartStyle.pie,
            onTap: () => onChange(RevenueChartStyle.pie),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? p.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: p.accent.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: active ? p.accent : p.inkMuted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: active ? p.ink : p.inkMuted,
                  fontSize: 11.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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

class _VariationPill extends StatelessWidget {
  final double percent;
  const _VariationPill({required this.percent});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final positive = percent >= 0;
    final color = positive ? p.success : p.error;
    final pretty = percent.isFinite
        ? '${positive ? '+' : ''}${percent.toStringAsFixed(0)}%'
        : '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            pretty,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATS GRID
// ============================================================================

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    final devisCtrl = Get.find<DevisController>();
    final designCtrl = Get.find<DesignationController>();

    return Obx(() {
      final stats = _DevisStats.from(devisCtrl.list);
      final designations = designCtrl.list.length;
      final cards = <_StatCardData>[
        _StatCardData(
          icon: Icons.receipt_long_rounded,
          label: 'Total devis',
          value: stats.totalCount.toDouble(),
          format: (v) => v.toInt().toString(),
          tone: _StatTone.accent,
        ),
        _StatCardData(
          icon: Icons.calendar_today_rounded,
          label: 'Cumul année',
          value: stats.currentYearRevenue,
          format: (v) => '${_formatNumber(v)} $kCurrencyLabel',
          tone: _StatTone.gold,
          isMoney: true,
        ),
        _StatCardData(
          icon: Icons.bar_chart_rounded,
          label: 'Panier moyen',
          value: stats.averageDevis,
          format: (v) => '${_formatNumber(v)} $kCurrencyLabel',
          tone: _StatTone.accent,
          isMoney: true,
        ),
        _StatCardData(
          icon: Icons.inventory_2_rounded,
          label: 'Désignations',
          value: designations.toDouble(),
          format: (v) => v.toInt().toString(),
          tone: _StatTone.neutral,
        ),
      ];
      return LayoutBuilder(builder: (context, cons) {
        final cols = cons.maxWidth > 560 ? 4 : 2;
        const gap = 12.0;
        final w = (cons.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < cards.length; i++)
              SizedBox(
                width: w,
                child: _StatCard(data: cards[i])
                    .animate()
                    .fadeIn(delay: (250 + i * 80).ms, duration: 500.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
              ),
          ],
        );
      });
    });
  }
}

enum _StatTone { accent, gold, neutral }

class _StatCardData {
  final IconData icon;
  final String label;
  final double value;
  final String Function(double) format;
  final _StatTone tone;
  /// Si vrai, la valeur (chiffre) sera affichée en couleur **or** —
  /// réservé aux montants monétaires.
  final bool isMoney;
  const _StatCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.format,
    required this.tone,
    this.isMoney = false,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppColors.of(context);
    final (iconColor, bgColor) = switch (data.tone) {
      _StatTone.accent => (p.accent, p.accent.withValues(alpha: 0.13)),
      _StatTone.gold => (p.gold, p.gold.withValues(alpha: 0.13)),
      _StatTone.neutral => (p.ink, p.surfaceHigh),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.outlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(data.icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(
            data.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: p.inkMuted,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedCounter(
            value: data.value,
            duration: const Duration(milliseconds: 900),
            formatter: data.format,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              fontSize: 19,
              color: data.isMoney ? p.gold : p.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// QUICK ACTIONS (chips défilantes)
// ============================================================================

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.add_rounded,
        label: 'Nouveau devis',
        primary: true,
        onTap: () => Get.toNamed(AppRoutes.chooseCategory),
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        label: 'Historique',
        onTap: () => Get.toNamed(AppRoutes.history),
      ),
      _QuickAction(
        icon: Icons.category_rounded,
        label: 'Catégories',
        onTap: () => Get.toNamed(AppRoutes.categories),
      ),
      _QuickAction(
        icon: Icons.inventory_2_rounded,
        label: 'Désignations',
        onTap: () => Get.toNamed(AppRoutes.designations),
      ),
      _QuickAction(
        icon: Icons.import_export_rounded,
        label: 'Import / Export',
        onTap: () => _DashboardSheets.showImportExportSheet(context),
      ),
      _QuickAction(
        icon: Icons.save_rounded,
        label: 'Sauvegarde',
        onTap: () => _DashboardSheets.showBackupSheet(context),
      ),
      _QuickAction(
        icon: Icons.settings_rounded,
        label: 'Paramètres',
        onTap: () => Get.toNamed(AppRoutes.settings),
      ),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _QuickActionChip(data: actions[i])
            .animate()
            .fadeIn(delay: (350 + i * 60).ms, duration: 400.ms)
            .slideX(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });
}

class _QuickActionChip extends StatelessWidget {
  final _QuickAction data;
  const _QuickActionChip({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppColors.of(context);
    final isPrimary = data.primary;

    return SizedBox(
      width: 108,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isPrimary
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [p.accent, p.accentDeep],
                    )
                  : null,
              color: isPrimary ? null : p.surface,
              border: isPrimary ? null : Border.all(color: p.outlineSoft),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: p.accent.withValues(alpha: 0.32),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  data.icon,
                  size: 22,
                  color: isPrimary ? Colors.white : p.ink,
                ),
                const Spacer(),
                Text(
                  data.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isPrimary ? Colors.white : p.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FACTURE KPIs (créances, encaissé, retards)
// ============================================================================

class _FactureKpisCard extends StatelessWidget {
  const _FactureKpisCard();

  @override
  Widget build(BuildContext context) {
    final fc = Get.find<FactureController>();
    final p = AppColors.of(context);
    return Obx(() {
      final all = fc.list;
      final now = DateTime.now();
      final factureeYear = all
          .where((f) => f.date.year == now.year && f.status != FactureStatus.annulee)
          .fold(0.0, (s, f) => s + f.total);
      final encaisseYear = all.fold(0.0, (s, f) {
        final paid = f.payments
            .where((pay) => pay.date.year == now.year)
            .fold(0.0, (a, pay) => a + pay.amount);
        return s + paid;
      });
      final outstanding = all
          .where((f) => f.status.isOpen)
          .fold(0.0, (s, f) => s + f.remaining);
      final overdueCount =
          all.where((f) => f.status == FactureStatus.enRetard).length;

      if (all.isEmpty) {
        return _EmptyKpisCard(
          onTap: () => Get.toNamed(AppRoutes.history),
        );
      }
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.history),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: p.surface,
              border: Border.all(color: p.outlineSoft, width: 0.7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _KpiBlock(
                      label: 'Facturé année',
                      value: '${_formatNumber(factureeYear)} $kCurrencyLabel',
                      icon: Icons.receipt_long_rounded,
                      color: p.gold,
                    ),
                    _KpiDivider(),
                    _KpiBlock(
                      label: 'Encaissé',
                      value: '${_formatNumber(encaisseYear)} $kCurrencyLabel',
                      icon: Icons.check_circle_rounded,
                      color: p.success,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _KpiBlock(
                      label: 'Restant dû',
                      value: '${_formatNumber(outstanding)} $kCurrencyLabel',
                      icon: Icons.hourglass_top_rounded,
                      color: p.accent,
                    ),
                    _KpiDivider(),
                    _KpiBlock(
                      label: 'En retard',
                      value: overdueCount.toString(),
                      icon: Icons.warning_amber_rounded,
                      color: overdueCount > 0 ? p.error : p.inkMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).animate().fadeIn(delay: 320.ms, duration: 500.ms).slideY(begin: 0.15, end: 0);
  }
}

class _KpiBlock extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiBlock({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: p.inkMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _KpiDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: p.outlineSoft,
    );
  }
}

class _EmptyKpisCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyKpisCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.outlineSoft, width: 0.7),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long_rounded, color: p.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pas encore de facture',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Acceptez un devis et convertissez-le en 1 clic.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: p.inkMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// RECENT DEVIS
// ============================================================================

class _RecentDevisList extends StatelessWidget {
  const _RecentDevisList();

  @override
  Widget build(BuildContext context) {
    final devisCtrl = Get.find<DevisController>();
    final p = AppColors.of(context);

    return Obx(() {
      final recent = devisCtrl.list.take(3).toList();
      if (recent.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.outlineSoft),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: p.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premier devis ?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Touchez “Nouveau devis” pour commencer.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: p.inkMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms, duration: 500.ms);
      }
      return Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            _DevisTile(devis: recent[i])
                .animate()
                .fadeIn(delay: (500 + i * 80).ms, duration: 450.ms)
                .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
            if (i < recent.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    });
  }
}

class _DevisTile extends StatelessWidget {
  final Devis devis;
  const _DevisTile({required this.devis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppColors.of(context);
    final clientName = devis.client?.nom.trim();
    final clientLine = (clientName == null || clientName.isEmpty)
        ? 'Sans client'
        : clientName;

    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.history),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.outlineSoft),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [p.accent.withValues(alpha: 0.18), p.gold.withValues(alpha: 0.18)],
                  ),
                ),
                child: Center(
                  child: Text(
                    'N°',
                    style: TextStyle(
                      color: p.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Devis #${devis.numero}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$clientLine · ${_shortDate(devis.date)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: p.inkMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatNumber(devis.total)} $kCurrencyLabel',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: p.gold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: p.inkMuted,
                    size: 18,
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

// ============================================================================
// SECTION HEADER
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.history),
              style: TextButton.styleFrom(
                foregroundColor: p.accent,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATS HELPER
// ============================================================================

class _DevisStats {
  final int totalCount;
  final int currentMonthCount;
  final double currentMonthRevenue;
  final double previousMonthRevenue;
  final double currentYearRevenue;
  final double averageDevis;
  final List<MonthlyRevenue> monthlyRevenue;
  final double monthChangePercent;

  const _DevisStats({
    required this.totalCount,
    required this.currentMonthCount,
    required this.currentMonthRevenue,
    required this.previousMonthRevenue,
    required this.currentYearRevenue,
    required this.averageDevis,
    required this.monthlyRevenue,
    required this.monthChangePercent,
  });

  factory _DevisStats.from(List<Devis> all) {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);

    double sumCurrent = 0;
    double sumPrev = 0;
    double sumYear = 0;
    double total = 0;
    int currentCount = 0;

    // 12 derniers mois → bucket par YYYYMM
    final months = <DateTime>[];
    for (var i = 11; i >= 0; i--) {
      months.add(DateTime(now.year, now.month - i, 1));
    }
    final buckets = {for (final m in months) _key(m): 0.0};

    for (final d in all) {
      total += d.total;
      final dt = d.date;
      if (dt.year == now.year) sumYear += d.total;
      if (dt.year == now.year && dt.month == now.month) {
        sumCurrent += d.total;
        currentCount += 1;
      }
      if (dt.year == prev.year && dt.month == prev.month) {
        sumPrev += d.total;
      }
      final k = _key(DateTime(dt.year, dt.month, 1));
      if (buckets.containsKey(k)) {
        buckets[k] = (buckets[k] ?? 0) + d.total;
      }
    }

    final monthly = months
        .map((m) => MonthlyRevenue(_shortMonth(m.month), buckets[_key(m)] ?? 0))
        .toList();

    final change = sumPrev == 0
        ? (sumCurrent > 0 ? 100.0 : 0.0)
        : ((sumCurrent - sumPrev) / sumPrev) * 100;

    return _DevisStats(
      totalCount: all.length,
      currentMonthCount: currentCount,
      currentMonthRevenue: sumCurrent,
      previousMonthRevenue: sumPrev,
      currentYearRevenue: sumYear,
      averageDevis: all.isEmpty ? 0 : total / all.length,
      monthlyRevenue: monthly,
      monthChangePercent: change,
    );
  }

  static String _key(DateTime d) => '${d.year}${d.month.toString().padLeft(2, '0')}';

  /// Libellés mois en français court (style "trader" / pro).
  static String _shortMonth(int m) =>
      const ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'][m - 1];
}

// ============================================================================
// FORMATTERS & HELPERS
// ============================================================================

String _formatNumber(double value) {
  final s = value.toStringAsFixed(0);
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

String _shortDate(DateTime d) {
  const months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
  return '${d.day} ${months[d.month - 1]}';
}

String _frenchMonth(int m) {
  const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
  return months[m - 1];
}

// ============================================================================
// BOTTOM SHEETS (logique préservée du dashboard original)
// ============================================================================

class _DashboardSheets {
  static void showBackupSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
        final p = AppColors.of(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.save_rounded, color: p.accent, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sauvegarde complète',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Catégories, désignations, historique des devis et paramètres entreprise.',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: 16),
                _SheetAction(
                  icon: Icons.upload_rounded,
                  iconColor: p.accent,
                  title: 'Sauvegarder tout',
                  subtitle: 'Enregistrer un fichier JSON sur le téléphone',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _backupAll(context);
                  },
                ),
                _SheetAction(
                  icon: Icons.restore_rounded,
                  iconColor: p.accent,
                  title: 'Restaurer tout',
                  subtitle: 'Importer une sauvegarde (remplace les données actuelles)',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _restoreAll(context);
                  },
                ),
                _SheetAction(
                  icon: Icons.restart_alt_rounded,
                  iconColor: p.error,
                  title: 'Tout réinitialiser',
                  subtitle: 'Supprimer toutes les données (irréversible)',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showResetConfirmation(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showImportExportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final p = AppColors.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.import_export_rounded, color: p.accent, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Import / Export (JSON)',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Catégories, désignations, ou un devis (.json).',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: 16),
                _SheetAction(
                  icon: Icons.upload_file_rounded,
                  iconColor: p.accent,
                  title: 'Importer',
                  subtitle: 'Catégories et désignations (JSON)',
                  onTap: () {
                    Navigator.pop(ctx);
                    _importJson(context);
                  },
                ),
                _SheetAction(
                  icon: Icons.description_outlined,
                  iconColor: p.accent,
                  title: 'Importer un devis',
                  subtitle: 'Charger un fichier .json (export devis ou sauvegarde)',
                  onTap: () {
                    Navigator.pop(ctx);
                    _importDevisJson(context);
                  },
                ),
                _SheetAction(
                  icon: Icons.download_rounded,
                  iconColor: p.accent,
                  title: 'Exporter',
                  subtitle: 'Enregistrer en fichier JSON',
                  onTap: () {
                    Navigator.pop(ctx);
                    _exportJson(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showResetConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final p = AppColors.of(ctx);
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: p.error, size: 44),
          title: const Text('Tout réinitialiser ?'),
          content: const Text(
            'Toutes les données seront supprimées : catégories, désignations, historique des devis et paramètres entreprise.\n\nCette action est irréversible.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await HiveStorage.resetAll();
                Get.find<DesignationController>().load();
                Get.find<DevisController>().load();
                Get.find<CompanyController>().load();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Application réinitialisée')),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: p.error),
              child: const Text('Réinitialiser tout'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _backupAll(BuildContext context) async {
    try {
      final path = await BackupService.saveToPhoneFolder();
      if (!context.mounted) return;
      final msg = (path != null && path.isNotEmpty)
          ? (path.toLowerCase().contains('download')
              ? 'Sauvegarde enregistrée dans Téléchargements'
              : 'Sauvegarde enregistrée sur le téléphone')
          : 'Enregistrement annulé';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  static Future<void> _restoreAll(BuildContext context) async {
    try {
      final result = await BackupService.importFromFile();
      if (result.cancelled) return;
      Get.find<DesignationController>().load();
      Get.find<DevisController>().load();
      Get.find<FactureController>().load();
      Get.find<CompanyController>().load();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restauration : ${result.categoriesCount} catégorie(s), '
              '${result.designationsCount} désignation(s), '
              '${result.devisCount} devis, ${result.facturesCount} facture(s).',
            ),
          ),
        );
      }
    } on FormatException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier invalide : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  static Future<void> _importDevisJson(BuildContext context) async {
    try {
      final devis = await JsonService.pickDevisJsonFile();
      if (devis == null) return;
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Importer ce devis ?'),
          content: Text(
            'Ouvrir le devis n° ${devis.numero} dans l’éditeur ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Importer'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      Get.toNamed(AppRoutes.createDevis, arguments: devis);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Devis n° ${devis.numero} ouvert dans l’éditeur'),
          ),
        );
      }
    } on FormatException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier devis invalide : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  static Future<void> _importJson(BuildContext context) async {
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
        ),
      );
    }
  }

  static Future<void> _exportJson(BuildContext context) async {
    final dc = Get.find<DesignationController>();
    if (dc.list.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune désignation à exporter')),
        );
      }
      return;
    }
    try {
      final jsonStr = dc.exportJson();
      final bytes = utf8.encode(jsonStr);
      final fileName = 'designations_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.json';
      final path = await FilePicker.saveFile(
        dialogTitle: 'Enregistrer les désignations (JSON)',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(path != null && path.isNotEmpty ? 'Fichier enregistré' : 'Enregistrement effectué')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _SheetAction({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: p.surfaceLow,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: destructive ? p.error : p.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: p.inkMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
