import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../core/controllers/devis_controller.dart';
import '../core/models/client.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_routes.dart';

/// Collecte d'informations client en **mode conversationnel**.
///
/// Au lieu d'un long formulaire visible d'un coup, on enchaîne 3 étapes
/// courtes avec une grande question, **un seul champ visible** à la fois,
/// transitions fluides, suggestions intelligentes (clients précédents),
/// et possibilité de sauter les étapes optionnelles.
class DevisClientPrepScreen extends StatefulWidget {
  const DevisClientPrepScreen({super.key});

  @override
  State<DevisClientPrepScreen> createState() => _DevisClientPrepScreenState();
}

class _DevisClientPrepScreenState extends State<DevisClientPrepScreen> {
  late final List<String> _categories;
  late final List<Client> _knownClients;
  bool _asInvoice = false;

  final _nom = TextEditingController();
  final _societe = TextEditingController();
  final _tel = TextEditingController();
  final _adresse = TextEditingController();
  final _email = TextEditingController();

  int _step = 0;
  static const _totalSteps = 3;

  void _onAnyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    // Compat : peut être une List<String> (ancien) ou un Map (nouveau).
    if (args is Map) {
      final cats = args['categories'];
      _categories = cats is List
          ? cats.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList()
          : <String>[];
      _asInvoice = args['asInvoice'] == true;
    } else if (args is List) {
      _categories = args.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    } else {
      _categories = <String>[];
    }

    final devisCtrl = Get.find<DevisController>();
    final seen = <String>{};
    _knownClients = devisCtrl.list
        .where((d) => d.client != null && d.client!.nom.trim().isNotEmpty)
        .map((d) => d.client!)
        .where((c) => seen.add(c.nom.trim().toLowerCase()))
        .take(8)
        .toList();

    _nom.addListener(_onAnyChanged);

    if (_categories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        Get.snackbar(
          'Catégories',
          'Choisissez au moins une catégorie',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      });
    }
  }

  @override
  void dispose() {
    _nom.removeListener(_onAnyChanged);
    _nom.dispose();
    _societe.dispose();
    _tel.dispose();
    _adresse.dispose();
    _email.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Get.back();
    }
  }

  void _skip() {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {
      if (_step < _totalSteps - 1) {
        _step++;
      } else {
        _finish();
      }
    });
  }

  void _useClient(Client c) {
    HapticFeedback.lightImpact();
    setState(() {
      _nom.text = c.nom;
      _societe.text = c.societe;
      _tel.text = c.telephone;
      _adresse.text = c.adresse;
      _email.text = c.email;
    });
  }

  void _finish() {
    Get.offNamed(
      AppRoutes.createDevis,
      arguments: {
        'categories': _categories,
        'clientNom': _nom.text.trim(),
        'clientSociete': _societe.text.trim(),
        'clientTel': _tel.text.trim(),
        'clientAdresse': _adresse.text.trim(),
        'clientEmail': _email.text.trim(),
        'asInvoice': _asInvoice,
      },
    );
  }

  bool get _canContinueCurrentStep {
    switch (_step) {
      case 0:
        return _nom.text.trim().isNotEmpty;
      case 1:
      case 2:
        return true;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header : back + progress + skip
            _Header(
              step: _step,
              total: _totalSteps,
              onBack: _back,
              onSkip: _step == 0 ? null : _skip,
              asInvoice: _asInvoice,
            ),

            // Corps : étape courante avec transition fluide
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildStep(_step),
                ),
              ),
            ),

            // CTA bas — Continuer / Démarrer le devis.
            // ⚠️ Pas de viewInsets.bottom ici : Scaffold gère déjà le clavier
            // via resizeToAvoidBottomInset:true, sinon on double-compte.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: _ContinueButton(
                enabled: _canContinueCurrentStep,
                isLast: _step == _totalSteps - 1,
                onTap: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _StepName(
          controller: _nom,
          categories: _categories,
          knownClients: _knownClients,
          onUseClient: _useClient,
          onSubmit: _next,
        );
      case 1:
        return _StepContact(
          tel: _tel,
          societe: _societe,
          onSubmit: _next,
        );
      case 2:
        return _StepLocation(
          adresse: _adresse,
          email: _email,
          onSubmit: _next,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ============================================================================
// HEADER
// ============================================================================

class _Header extends StatelessWidget {
  final int step;
  final int total;
  final VoidCallback onBack;
  final VoidCallback? onSkip;
  final bool asInvoice;

  const _Header({
    required this.step,
    required this.total,
    required this.onBack,
    this.onSkip,
    this.asInvoice = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: p.surfaceHigh,
                  foregroundColor: p.ink,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: _ProgressBar(step: step, total: total)),
              const SizedBox(width: 14),
              if (onSkip != null)
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: p.inkMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Passer',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                )
              else
                const SizedBox(width: 56),
            ],
          ),
          if (asInvoice)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: p.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: p.gold.withValues(alpha: 0.4), width: 0.6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 12, color: p.gold),
                        const SizedBox(width: 6),
                        Text(
                          'Nouvelle facture',
                          style: TextStyle(
                            color: p.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.2,
                          ),
                        ),
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
}

class _ProgressBar extends StatelessWidget {
  final int step;
  final int total;
  const _ProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Row(
      children: List.generate(total, (i) {
        final active = i <= step;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              height: 5,
              decoration: BoxDecoration(
                color: active ? p.accent : p.surfaceHigh,
                borderRadius: BorderRadius.circular(99),
                boxShadow: i == step
                    ? [BoxShadow(color: p.accent.withValues(alpha: 0.4), blurRadius: 8)]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ============================================================================
// CONTINUE BUTTON
// ============================================================================

class _ContinueButton extends StatelessWidget {
  final bool enabled;
  final bool isLast;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.enabled,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: IgnorePointer(
        ignoring: !enabled,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.accent, p.accentDeep],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: p.accent.withValues(alpha: 0.42),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLast ? 'Démarrer le devis' : 'Continuer',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isLast ? Icons.arrow_forward_rounded : Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: isLast ? 22 : 16,
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
// STEP SHELL — eyebrow + question + content
// ============================================================================

class _StepShell extends StatelessWidget {
  final String eyebrow;
  final String question;
  final String? hint;
  final Widget content;

  const _StepShell({
    required this.eyebrow,
    required this.question,
    required this.content,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: p.accent.withValues(alpha: 0.28), width: 0.6),
            ),
            child: Text(
              eyebrow,
              style: TextStyle(
                color: p.accent,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
                letterSpacing: 2.4,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 16),
          // Question (display)
          Text(
            question,
            style: TextStyle(
              color: p.ink,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
              height: 1.1,
            ),
          )
              .animate()
              .fadeIn(delay: 80.ms, duration: 500.ms)
              .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint!,
              style: TextStyle(
                color: p.inkMuted,
                fontSize: 14.5,
                height: 1.55,
                fontWeight: FontWeight.w400,
              ),
            )
                .animate()
                .fadeIn(delay: 180.ms, duration: 500.ms),
          ],
          const SizedBox(height: 26),
          content
              .animate()
              .fadeIn(delay: 240.ms, duration: 500.ms)
              .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

// ============================================================================
// STEP 1 — nom client (avec suggestions)
// ============================================================================

class _StepName extends StatefulWidget {
  final TextEditingController controller;
  final List<String> categories;
  final List<Client> knownClients;
  final ValueChanged<Client> onUseClient;
  final VoidCallback onSubmit;

  const _StepName({
    required this.controller,
    required this.categories,
    required this.knownClients,
    required this.onUseClient,
    required this.onSubmit,
  });

  @override
  State<_StepName> createState() => _StepNameState();
}

class _StepNameState extends State<_StepName> {
  late final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return _StepShell(
      eyebrow: 'ÉTAPE 1 SUR 3',
      question: 'À qui s’adresse\nce devis ?',
      hint: 'Le nom apparaîtra en haut du PDF — en majuscules.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Champ nom — grand, élégant
          _BigTextField(
            controller: widget.controller,
            focusNode: _focus,
            hint: 'Ex. Konaté Mamadou',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) {
              if (widget.controller.text.trim().isNotEmpty) widget.onSubmit();
            },
          ),

          // Suggestions : clients précédents
          if (widget.knownClients.isNotEmpty) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Icon(Icons.history_rounded, size: 14, color: p.inkMuted),
                const SizedBox(width: 6),
                Text(
                  'Vos clients récents',
                  style: TextStyle(
                    color: p.inkMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in widget.knownClients)
                  _ClientChip(
                    name: c.nom,
                    onTap: () => widget.onUseClient(c),
                  ),
              ],
            ),
          ],

          // Rappel des catégories choisies
          if (widget.categories.isNotEmpty) ...[
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.surfaceLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.outlineSoft),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.layers_rounded, color: p.accent, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catégories de ce devis',
                          style: TextStyle(
                            color: p.inkMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.categories.join(' · '),
                          style: TextStyle(
                            color: p.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClientChip extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _ClientChip({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: p.outlineSoft),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.accent.withValues(alpha: 0.14),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: p.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  color: p.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
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
// STEP 2 — téléphone + société (optionnels)
// ============================================================================

class _StepContact extends StatefulWidget {
  final TextEditingController tel;
  final TextEditingController societe;
  final VoidCallback onSubmit;

  const _StepContact({
    required this.tel,
    required this.societe,
    required this.onSubmit,
  });

  @override
  State<_StepContact> createState() => _StepContactState();
}

class _StepContactState extends State<_StepContact> {
  late final FocusNode _telFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _telFocus.requestFocus());
  }

  @override
  void dispose() {
    _telFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      eyebrow: 'ÉTAPE 2 SUR 3',
      question: 'Comment\nle joindre ?',
      hint: 'Téléphone et société — utiles pour le pied de page du PDF. Tous optionnels.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BigTextField(
            controller: widget.tel,
            focusNode: _telFocus,
            hint: '698 87 93 76',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 +\-]')),
            ],
            onSubmitted: (_) => widget.onSubmit(),
          ),
          const SizedBox(height: 14),
          _BigTextField(
            controller: widget.societe,
            hint: 'Société (optionnel)',
            icon: Icons.business_outlined,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => widget.onSubmit(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STEP 3 — adresse + email (optionnels)
// ============================================================================

class _StepLocation extends StatefulWidget {
  final TextEditingController adresse;
  final TextEditingController email;
  final VoidCallback onSubmit;

  const _StepLocation({
    required this.adresse,
    required this.email,
    required this.onSubmit,
  });

  @override
  State<_StepLocation> createState() => _StepLocationState();
}

class _StepLocationState extends State<_StepLocation> {
  late final FocusNode _adrFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _adrFocus.requestFocus());
  }

  @override
  void dispose() {
    _adrFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      eyebrow: 'ÉTAPE 3 SUR 3',
      question: 'Où le trouver ?',
      hint: 'Adresse et email — apparaîtront sous le nom du client. Optionnels.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BigTextField(
            controller: widget.adresse,
            focusNode: _adrFocus,
            hint: 'Quartier, ville…',
            icon: Icons.location_on_outlined,
            maxLines: 2,
            onSubmitted: (_) => widget.onSubmit(),
          ),
          const SizedBox(height: 14),
          _BigTextField(
            controller: widget.email,
            hint: 'email@exemple.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => widget.onSubmit(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BIG TEXT FIELD — input premium avec icône et fond doux
// ============================================================================

class _BigTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const _BigTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.onSubmitted,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.outlineSoft, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: p.inkMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              maxLines: maxLines,
              minLines: 1,
              onSubmitted: onSubmitted,
              inputFormatters: inputFormatters,
              textInputAction: maxLines == 1 ? TextInputAction.done : TextInputAction.newline,
              style: TextStyle(
                color: p.ink,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              cursorColor: p.accent,
              cursorWidth: 2,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: p.inkMuted.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
