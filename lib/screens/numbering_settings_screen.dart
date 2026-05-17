import 'package:flutter/material.dart';
import '../core/database/hive_storage.dart';
import '../core/services/numbering_service.dart';
import '../core/theme/app_theme.dart';

/// Réglages de la numérotation pro : préfixe, année, reset annuel, padding.
class NumberingSettingsScreen extends StatefulWidget {
  const NumberingSettingsScreen({super.key});

  @override
  State<NumberingSettingsScreen> createState() => _NumberingSettingsScreenState();
}

class _NumberingSettingsScreenState extends State<NumberingSettingsScreen> {
  late NumberingConfig _cfg;
  late TextEditingController _devisPrefixCtrl;
  late TextEditingController _facturePrefixCtrl;

  @override
  void initState() {
    super.initState();
    _cfg = HiveStorage.getNumberingConfig();
    _devisPrefixCtrl = TextEditingController(text: _cfg.devisPrefix);
    _facturePrefixCtrl = TextEditingController(text: _cfg.facturePrefix);
  }

  @override
  void dispose() {
    _devisPrefixCtrl.dispose();
    _facturePrefixCtrl.dispose();
    super.dispose();
  }

  Future<void> _save({bool silent = false}) async {
    _cfg = _cfg.copyWith(
      devisPrefix: _devisPrefixCtrl.text.trim(),
      facturePrefix: _facturePrefixCtrl.text.trim(),
    );
    await HiveStorage.setNumberingConfig(_cfg);
    if (mounted) setState(() {});
    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numérotation enregistrée'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final previewDevis = NumberingService.preview(NumberingService.devisType);
    final previewFacture = NumberingService.preview(NumberingService.factureType);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Numérotation'),
        actions: [
          IconButton(
            tooltip: 'Réinitialiser les compteurs',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _previewCard(
              p,
              icon: Icons.description_rounded,
              label: 'Prochain numéro de devis',
              value: previewDevis,
              tone: p.accent,
            ),
            const SizedBox(height: 10),
            _previewCard(
              p,
              icon: Icons.receipt_long_rounded,
              label: 'Prochain numéro de facture',
              value: previewFacture,
              tone: p.gold,
            ),
            const SizedBox(height: 24),
            Text(
              'PRÉFIXES',
              style: TextStyle(
                color: p.inkMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _devisPrefixCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Préfixe devis',
                hintText: 'Ex : DEV',
              ),
              onChanged: (_) => _save(silent: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _facturePrefixCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Préfixe facture',
                hintText: 'Ex : FAC',
              ),
              onChanged: (_) => _save(silent: true),
            ),
            const SizedBox(height: 22),
            Text(
              'OPTIONS',
              style: TextStyle(
                color: p.inkMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            _toggleTile(
              p,
              title: 'Inclure l\'année',
              subtitle: 'Format DEV-2026-0001 vs DEV-0001',
              value: _cfg.includeYear,
              onChanged: (v) async {
                setState(() => _cfg = _cfg.copyWith(includeYear: v));
                await _save(silent: true);
              },
            ),
            _toggleTile(
              p,
              title: 'Reset annuel',
              subtitle: 'Compteur remis à zéro au 1er janvier',
              value: _cfg.resetAnnual,
              onChanged: (v) async {
                setState(() => _cfg = _cfg.copyWith(resetAnnual: v));
                await _save(silent: true);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'PADDING (nombre de chiffres)',
              style: TextStyle(
                color: p.inkMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final n in [3, 4, 5, 6])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$n'),
                      selected: _cfg.padding == n,
                      onSelected: (s) async {
                        if (!s) return;
                        setState(() => _cfg = _cfg.copyWith(padding: n));
                        await _save(silent: true);
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Enregistrer'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewCard(
    AppPalette p, {
    required IconData icon,
    required String label,
    required String value,
    required Color tone,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.outlineSoft, width: 0.7),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tone, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: p.inkMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: tone, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleTile(
    AppPalette p, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.outlineSoft, width: 0.7),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: TextStyle(color: p.inkMuted, fontSize: 12.5)),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final p = AppColors.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser les compteurs ?'),
        content: const Text(
          'Les prochains devis et factures repartiront à 0001. Les documents déjà créés ne sont pas modifiés.\n\nUtile en début d\'exercice.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: p.error),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await HiveStorage.setNumberingLastCount(NumberingService.devisType, 0);
    await HiveStorage.setNumberingLastCount(NumberingService.factureType, 0);
    if (mounted) setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compteurs réinitialisés')),
      );
    }
  }
}
