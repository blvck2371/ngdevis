import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../core/controllers/facture_controller.dart';
import '../core/models/facture.dart';
import '../core/models/facture_status.dart';
import '../core/models/payment.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_currency.dart';
import '../core/utils/responsive.dart';
import '../core/widgets/status_badge.dart';

/// Écran de détail d'une facture : récap chiffres + paiements + actions.
///
/// L'utilisateur peut : enregistrer un paiement (total/partiel), marquer
/// envoyée, marquer soldée, annuler, partager le PDF, ou supprimer un paiement.
class FactureDetailScreen extends StatefulWidget {
  const FactureDetailScreen({super.key});

  @override
  State<FactureDetailScreen> createState() => _FactureDetailScreenState();
}

class _FactureDetailScreenState extends State<FactureDetailScreen> {
  String? _factureId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map && args['factureId'] is String) {
      _factureId = args['factureId'] as String;
    } else if (args is String && args.trim().isNotEmpty) {
      _factureId = args.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fc = Get.find<FactureController>();
    final r = context.responsive;
    final p = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facture'),
      ),
      body: Obx(() {
        if (_factureId == null) return _missing(context, 'Facture introuvable');
        Facture? f;
        try {
          f = fc.list.firstWhere((e) => e.id == _factureId);
        } catch (_) {
          f = null;
        }
        if (f == null) return _missing(context, 'Cette facture n\'existe plus.');
        final fac = f;

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              r.horizontalPadding,
              16,
              r.horizontalPadding,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderCard(facture: fac),
                const SizedBox(height: 14),
                _PaymentSummaryCard(facture: fac),
                const SizedBox(height: 14),
                _ActionsRow(
                  facture: fac,
                  onAddPayment: () => _showAddPaymentSheet(context, fac),
                  onMarkSent: () async {
                    await fc.markSent(fac.id);
                    if (context.mounted) _snack(context, 'Facture marquée envoyée');
                  },
                  onMarkPaid: () async {
                    await fc.markFullyPaid(fac.id);
                    if (context.mounted) _snack(context, 'Facture soldée');
                  },
                  onCancel: () async {
                    final ok = await _confirm(
                      context,
                      title: 'Annuler la facture ?',
                      text: 'La facture sera marquée comme annulée. Le contenu est conservé pour historique.',
                      confirmLabel: 'Annuler la facture',
                      destructive: true,
                    );
                    if (ok != true) return;
                    await fc.markCancelled(fac.id);
                    if (context.mounted) _snack(context, 'Facture annulée');
                  },
                  onPreview: () => fc.previewPdf(fac),
                  onShare: () => fc.sharePdf(fac),
                ),
                const SizedBox(height: 22),
                _ClientCard(facture: fac),
                const SizedBox(height: 14),
                _ItemsCard(facture: fac),
                const SizedBox(height: 14),
                _PaymentsListCard(
                  facture: fac,
                  onDelete: (id) async {
                    final ok = await _confirm(
                      context,
                      title: 'Supprimer ce paiement ?',
                      text: 'L\'encaissement sera retiré et le statut recalculé.',
                      confirmLabel: 'Supprimer',
                      destructive: true,
                    );
                    if (ok != true) return;
                    await fc.removePayment(fac.id, id);
                    if (context.mounted) _snack(context, 'Paiement supprimé');
                  },
                ),
                const SizedBox(height: 18),
                // Bouton Supprimer la facture (rouge, en bas)
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await _confirm(
                      context,
                      title: 'Supprimer définitivement ?',
                      text: 'La facture ${fac.numero} sera supprimée. Cette action est irréversible.',
                      confirmLabel: 'Supprimer',
                      destructive: true,
                    );
                    if (ok != true) return;
                    await fc.deleteFacture(fac.id);
                    if (context.mounted) Navigator.of(context).maybePop();
                  },
                  icon: Icon(Icons.delete_outline_rounded, color: p.error),
                  label: Text('Supprimer la facture', style: TextStyle(color: p.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: p.error.withValues(alpha: 0.4)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _missing(BuildContext context, String text) {
    final p = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: p.inkMuted),
            const SizedBox(height: 10),
            Text(text, style: TextStyle(color: p.inkMuted)),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentSheet(BuildContext context, Facture f) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _AddPaymentSheet(facture: f),
    );
  }
}

// ============================================================================
// HEADER (numéro, statut, dates)
// ============================================================================

class _HeaderCard extends StatelessWidget {
  final Facture facture;
  const _HeaderCard({required this.facture});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.accent.withValues(alpha: 0.14),
            p.gold.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.outlineSoft, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long_rounded, color: p.gold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Facture ${facture.numero}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Émise le ${_formatDate(facture.date)}',
                      style: TextStyle(color: p.inkMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: facture.status.label,
                icon: facture.status.icon,
                toneCode: facture.status.toneCode,
              ),
            ],
          ),
          if (facture.dueDate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 15,
                  color: facture.isOverdue ? p.error : p.inkMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  facture.isOverdue
                      ? 'En retard depuis le ${_formatDate(facture.dueDate!)}'
                      : 'Échéance ${_formatDate(facture.dueDate!)}',
                  style: TextStyle(
                    color: facture.isOverdue ? p.error : p.inkMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// RÉCAP PAIEMENT (barre de progression)
// ============================================================================

class _PaymentSummaryCard extends StatelessWidget {
  final Facture facture;
  const _PaymentSummaryCard({required this.facture});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final paid = facture.totalPaid;
    final ratio = facture.paidRatio;
    final isPaid = facture.status == FactureStatus.payee;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.outlineSoft, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TOTAL À RÉGLER',
            style: TextStyle(
              color: p.inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatNumberFr(facture.total)} $kCurrencyLabel',
            style: TextStyle(
              color: p.gold,
              fontWeight: FontWeight.w800,
              fontSize: 32,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: p.surfaceLow,
              valueColor: AlwaysStoppedAnimation(isPaid ? p.success : p.gold),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatColumn(label: 'Encaissé', value: '${_formatNumberFr(paid)} $kCurrencyLabel', color: p.success),
              _StatColumn(
                label: isPaid ? 'Soldée' : 'Restant dû',
                value: '${_formatNumberFr(facture.remaining)} $kCurrencyLabel',
                color: isPaid ? p.success : p.gold,
              ),
              _StatColumn(
                label: 'Progression',
                value: '${(ratio * 100).toStringAsFixed(0)} %',
                color: p.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatColumn({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: p.inkMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACTIONS RAPIDES
// ============================================================================

class _ActionsRow extends StatelessWidget {
  final Facture facture;
  final VoidCallback onAddPayment;
  final VoidCallback onMarkSent;
  final VoidCallback onMarkPaid;
  final VoidCallback onCancel;
  final VoidCallback onPreview;
  final VoidCallback onShare;

  const _ActionsRow({
    required this.facture,
    required this.onAddPayment,
    required this.onMarkSent,
    required this.onMarkPaid,
    required this.onCancel,
    required this.onPreview,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final canPay = facture.status.canRecordPayment;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (canPay)
          _PrimaryAction(
            icon: Icons.payments_rounded,
            label: 'Enregistrer un paiement',
            onTap: onAddPayment,
          ),
        if (facture.status == FactureStatus.brouillon)
          _SecondaryAction(
            icon: Icons.send_rounded,
            label: 'Marquer envoyée',
            onTap: onMarkSent,
          ),
        if (canPay && facture.remaining > 0)
          _SecondaryAction(
            icon: Icons.verified_rounded,
            label: 'Tout marquer soldé',
            onTap: onMarkPaid,
          ),
        _SecondaryAction(
          icon: Icons.picture_as_pdf_rounded,
          label: 'Aperçu PDF',
          onTap: onPreview,
        ),
        _SecondaryAction(
          icon: Icons.share_rounded,
          label: 'Partager',
          onTap: onShare,
        ),
        if (facture.status != FactureStatus.annulee)
          _SecondaryAction(
            icon: Icons.block_rounded,
            label: 'Annuler la facture',
            onTap: onCancel,
            destructive: true,
          ),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Material(
      borderRadius: BorderRadius.circular(14),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: [p.accent, p.accentDeep]),
            boxShadow: [
              BoxShadow(
                color: p.accent.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final color = destructive ? p.error : p.ink;
    return Material(
      borderRadius: BorderRadius.circular(14),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: p.surface,
            border: Border.all(
              color: destructive ? p.error.withValues(alpha: 0.35) : p.outlineSoft,
              width: 0.7,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CLIENT
// ============================================================================

class _ClientCard extends StatelessWidget {
  final Facture facture;
  const _ClientCard({required this.facture});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final c = facture.client;
    final lines = <String>[
      if ((c?.societe ?? '').trim().isNotEmpty) c!.societe.trim(),
      if ((c?.adresse ?? '').trim().isNotEmpty) c!.adresse.trim(),
      if ((c?.telephone ?? '').trim().isNotEmpty) 'Tél. ${c!.telephone.trim()}',
      if ((c?.email ?? '').trim().isNotEmpty) c!.email.trim(),
    ];
    final nom = (c?.nom ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.outlineSoft, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FACTURÉ À',
            style: TextStyle(
              color: p.inkMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nom.isEmpty ? '—' : nom.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
          ),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(lines.join('\n'),
                style: TextStyle(color: p.inkMuted, height: 1.4, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// ARTICLES
// ============================================================================

class _ItemsCard extends StatelessWidget {
  final Facture facture;
  const _ItemsCard({required this.facture});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.outlineSoft, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ARTICLES',
            style: TextStyle(
              color: p.inkMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          for (final s in facture.sections) ...[
            if (s.titre.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text(
                  s.titre,
                  style: TextStyle(
                    color: p.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            for (final it in s.items) _itemRow(context, it.designation, it.quantite, it.prixUnitaire, it.total, it.unit.symbole),
            if (s.mainOeuvre > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.mainOeuvrePercent > 0
                            ? 'Main d\'œuvre (${s.mainOeuvrePercent.toStringAsFixed(0)} %)'
                            : 'Main d\'œuvre',
                        style: TextStyle(color: p.accent, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    Text(
                      '${_formatNumberFr(s.mainOeuvre)} $kCurrencyLabel',
                      style: TextStyle(color: p.accent, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            Divider(color: p.outlineSoft, height: 18),
          ],
          Row(
            children: [
              const Expanded(child: Text('Total HT/TTC', style: TextStyle(fontWeight: FontWeight.w700))),
              Text(
                '${_formatNumberFr(facture.total)} $kCurrencyLabel',
                style: TextStyle(color: p.gold, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemRow(BuildContext context, String designation, double qte, double pu, double total, String unit) {
    final p = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(designation, style: TextStyle(color: p.ink, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(
                  '${_trimNumber(qte)} $unit × ${_formatNumberFr(pu)} $kCurrencyLabel',
                  style: TextStyle(color: p.inkMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Text(
            '${_formatNumberFr(total)} $kCurrencyLabel',
            style: TextStyle(color: p.ink, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LISTE PAIEMENTS
// ============================================================================

class _PaymentsListCard extends StatelessWidget {
  final Facture facture;
  final ValueChanged<String> onDelete;
  const _PaymentsListCard({required this.facture, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    if (facture.payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.outlineSoft, width: 0.7),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: p.inkMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucun paiement enregistré.\nEnregistrez-en un pour mettre la facture à jour.',
                style: TextStyle(color: p.inkMuted, fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }
    final sorted = [...facture.payments]..sort((a, b) => b.date.compareTo(a.date));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.outlineSoft, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ENCAISSEMENTS',
            style: TextStyle(
              color: p.inkMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          for (final pay in sorted) _paymentTile(context, pay),
        ],
      ),
    );
  }

  Widget _paymentTile(BuildContext context, Payment pay) {
    final p = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.success.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(pay.method.icon, color: p.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pay.method.label,
                  style: TextStyle(color: p.ink, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  '${_formatDate(pay.date)}${pay.reference.isEmpty ? '' : ' · ${pay.reference}'}',
                  style: TextStyle(color: p.inkMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Text(
            '+${_formatNumberFr(pay.amount)} $kCurrencyLabel',
            style: TextStyle(color: p.success, fontWeight: FontWeight.w800, fontSize: 14),
          ),
          IconButton(
            tooltip: 'Supprimer',
            onPressed: () => onDelete(pay.id),
            icon: Icon(Icons.close_rounded, color: p.inkMuted, size: 18),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SHEET : AJOUT D'UN PAIEMENT
// ============================================================================

class _AddPaymentSheet extends StatefulWidget {
  final Facture facture;
  const _AddPaymentSheet({required this.facture});

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _refCtrl;
  PaymentMethod _method = PaymentMethod.especes;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.facture.remaining.toStringAsFixed(0),
    );
    _refCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final remaining = widget.facture.remaining;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.payments_rounded, color: p.accent),
                const SizedBox(width: 10),
                Text(
                  'Enregistrer un paiement',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Reste à percevoir : ${_formatNumberFr(remaining)} $kCurrencyLabel',
              style: TextStyle(color: p.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Montant ($kCurrencyLabel)',
                prefixIcon: const Icon(Icons.attach_money_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMethod.values.map((m) {
                final active = m == _method;
                return InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () => setState(() => _method = m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? p.accent.withValues(alpha: 0.14) : p.surfaceLow,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: active ? p.accent.withValues(alpha: 0.6) : p.outlineSoft,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(m.icon, color: active ? p.accent : p.inkMuted, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          m.label,
                          style: TextStyle(
                            color: active ? p.accent : p.ink,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _refCtrl,
              decoration: const InputDecoration(
                labelText: 'Référence (n° transaction, chèque, etc.)',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: p.surfaceLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.outlineSoft),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_rounded, color: p.accent),
                    const SizedBox(width: 10),
                    const Text('Date du paiement', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(_formatDate(_date), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Enregistrer le paiement'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final raw = _amountCtrl.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      _snack(context, 'Saisir un montant valide.');
      return;
    }
    final fc = Get.find<FactureController>();
    await fc.addPayment(
      widget.facture.id,
      Payment(
        id: const Uuid().v4(),
        date: _date,
        amount: amount,
        method: _method,
        reference: _refCtrl.text.trim(),
      ),
    );
    if (mounted) {
      Navigator.of(context).pop();
      _snack(context, 'Paiement de ${_formatNumberFr(amount)} $kCurrencyLabel enregistré');
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

String _trimNumber(double v) {
  if (v == v.toInt()) return v.toInt().toString();
  return v.toStringAsFixed(2);
}

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String text,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}
