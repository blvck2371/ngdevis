import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../core/database/hive_storage.dart';
import '../core/utils/app_currency.dart';
import '../core/utils/app_routes.dart';
import '../core/widgets/magnetic_button.dart';

/// Onboarding premium — version éditoriale.
///
/// Fond sombre unifié (deep purple-black + halo radial qui suit la teinte de
/// la page), une illustration unique par page (cartes empilées, unités
/// orbitales, mockup PDF avec sceau or), typographie display, animations
/// cinématiques (entrée elastic, flottement continu, parallax sur scroll).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;
  // Position fractionnaire (utilisée pour le parallax et la transition de halo)
  double _frac = 0;

  // Liste construite paresseusement (les pages contiennent des WidgetBuilders,
  // donc on ne peut pas la déclarer `const`).
  List<_PageData>? _pagesCache;
  List<_PageData> get _pages => _pagesCache ??= _buildPages();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      if (!_ctrl.hasClients) return;
      setState(() => _frac = _ctrl.page ?? _ctrl.initialPage.toDouble());
    });
  }

  List<_PageData> _buildPages() => [
        _PageData(
          eyebrow: 'RAPIDITÉ',
          title: 'Composez\nen quelques tapes.',
          description:
              'Sections, lignes, totaux — votre devis s’assemble en direct, depuis votre base de désignations.',
          accent: const Color(0xFF9B7BFF),
          haloA: const Color(0xFF6E4DFF),
          haloB: const Color(0xFF2A1A6E),
          sceneBuilder: (_) => const _SceneInvoiceStack(),
        ),
        _PageData(
          eyebrow: 'INTELLIGENCE',
          title: 'Toutes les unités\nde votre métier.',
          description:
              'Mètres, kilos, litres, m², m³, heures, forfait. Le moteur s’adapte au BTP, à l’électricité, à la plomberie.',
          accent: const Color(0xFFE9C46A),
          haloA: const Color(0xFFB78A2A),
          haloB: const Color(0xFF3D2A0A),
          sceneBuilder: (_) => const _SceneOrbitalUnits(),
        ),
        _PageData(
          eyebrow: 'PRESTIGE',
          title: 'Un PDF\nqui en impose.',
          description:
              'Page de couverture corporate, tableaux soignés, signatures. Vos clients reçoivent un devis de qualité agence.',
          accent: const Color(0xFF7AD8BE),
          haloA: const Color(0xFF1F8F75),
          haloB: const Color(0xFF0B3530),
          sceneBuilder: (_) => const _ScenePdfDocument(),
        ),
      ];

  void _next() {
    if (_page < 2) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await HiveStorage.markOnboardingSeen();
    if (mounted) Get.offAllNamed(AppRoutes.dashboard);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF06060C),
      body: Stack(
        children: [
          // 1) Halo de fond qui change de teinte selon la page (transition lerp)
          Positioned.fill(
            child: _AnimatedHaloBackground(
              pages: _pages,
              fraction: _frac,
            ),
          ),
          // 2) Pages
          SafeArea(
            child: Column(
              children: [
                // Top bar : monogramme + skip
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                  child: Row(
                    children: [
                      _BrandDot(color: _pages[_page].accent),
                      const SizedBox(width: 10),
                      Text(
                        'NG Devis',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.65),
                          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        child: const Text('Passer'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => _OnboardingPage(
                      data: _pages[i],
                      parallax: _frac - i,
                      key: ValueKey(i),
                    ),
                  ),
                ),
                // Bottom : indicator + CTA
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24, 0, 24, math.max(20, MediaQuery.paddingOf(context).bottom + 8),
                  ),
                  child: Column(
                    children: [
                      _PageIndicator(count: _pages.length, current: _page, accent: _pages[_page].accent),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 260),
                            opacity: _page == 0 ? 0 : 1,
                            child: IgnorePointer(
                              ignoring: _page == 0,
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: Material(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => _ctrl.previousPage(
                                      duration: const Duration(milliseconds: 420),
                                      curve: Curves.easeOutCubic,
                                    ),
                                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MagneticButton(
                              onPressed: _next,
                              label: isLast ? 'Démarrer NG Devis' : 'Continuer',
                              icon: isLast ? Icons.arrow_forward_rounded : null,
                              expand: true,
                              gradient: [_pages[_page].accent, _pages[_page].haloA],
                            ),
                          ),
                        ],
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

// ============================================================================
// DATA PER PAGE
// ============================================================================

class _PageData {
  final String eyebrow;
  final String title;
  final String description;
  /// Couleur accent (CTA gradient, dot indicator, halo central).
  final Color accent;
  /// Halo radial extérieur (teinte plus saturée).
  final Color haloA;
  /// Halo radial profond (en fond, très sombre).
  final Color haloB;
  final WidgetBuilder sceneBuilder;

  const _PageData({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.accent,
    required this.haloA,
    required this.haloB,
    required this.sceneBuilder,
  });
}

// ============================================================================
// ANIMATED HALO BACKGROUND
// ============================================================================

class _AnimatedHaloBackground extends StatefulWidget {
  final List<_PageData> pages;
  final double fraction;

  const _AnimatedHaloBackground({required this.pages, required this.fraction});

  @override
  State<_AnimatedHaloBackground> createState() => _AnimatedHaloBackgroundState();
}

class _AnimatedHaloBackgroundState extends State<_AnimatedHaloBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  Color _lerpBetweenPages(Color Function(_PageData) pick) {
    final f = widget.fraction.clamp(0.0, (widget.pages.length - 1).toDouble());
    final i = f.floor();
    final j = (i + 1).clamp(0, widget.pages.length - 1);
    final t = (f - i).clamp(0.0, 1.0);
    return Color.lerp(pick(widget.pages[i]), pick(widget.pages[j]), t)!;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _lerpBetweenPages((d) => d.accent);
    final haloA = _lerpBetweenPages((d) => d.haloA);
    final haloB = _lerpBetweenPages((d) => d.haloB);

    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        final t = _drift.value;
        return CustomPaint(
          painter: _HaloPainter(
            accent: accent,
            haloA: haloA,
            haloB: haloB,
            t: t,
          ),
        );
      },
    );
  }
}

class _HaloPainter extends CustomPainter {
  final Color accent;
  final Color haloA;
  final Color haloB;
  final double t;

  _HaloPainter({
    required this.accent,
    required this.haloA,
    required this.haloB,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fond pur (très sombre) : on évite le noir pur, on prend un violet-noir très deep.
    final base = const Color(0xFF06060C);
    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    // Gradient vertical subtil pour assombrir le bas et éclairer un peu le centre.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            haloB.withValues(alpha: 0.55),
            base,
            base,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    final cx = size.width * (0.5 + 0.04 * math.sin(t * math.pi * 2));
    final cy = size.height * (0.34 + 0.02 * math.cos(t * math.pi * 2));
    final radius = math.max(size.width, size.height) * 0.85;

    // Halo principal centré derrière l'illustration
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.35),
            haloA.withValues(alpha: 0.18),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius)),
    );

    // Deuxième halo plus petit décalé pour profondeur
    final c2 = Offset(
      size.width * (0.78 + 0.05 * math.sin(t * math.pi * 2 + 1.7)),
      size.height * (0.62 + 0.04 * math.cos(t * math.pi * 2 + 0.9)),
    );
    canvas.drawCircle(
      c2,
      radius * 0.6,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            haloA.withValues(alpha: 0.22),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c2, radius: radius * 0.6)),
    );

    // Grain dot : quelques points blancs subtils (étoiles)
    final rng = math.Random(42);
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    for (var i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.6 + rng.nextDouble() * 1.4;
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HaloPainter old) =>
      old.accent != accent || old.haloA != haloA || old.haloB != haloB || old.t != t;
}

// ============================================================================
// ONBOARDING PAGE
// ============================================================================

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  final double parallax;

  const _OnboardingPage({super.key, required this.data, required this.parallax});

  @override
  Widget build(BuildContext context) {
    final clampedParallax = parallax.clamp(-1.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Illustration centrale (avec parallax horizontal)
          Expanded(
            flex: 5,
            child: Center(
              child: Transform.translate(
                offset: Offset(clampedParallax * -36, 0),
                child: data.sceneBuilder(context),
              ),
            ),
          ),
          // Bloc texte
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _EyebrowTag(text: data.eyebrow, color: data.accent),
                const SizedBox(height: 18),
                _StaggeredTitle(text: data.title, key: ValueKey('t-${data.title}')),
                const SizedBox(height: 14),
                Text(
                  data.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 15.5,
                    height: 1.65,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 380.ms, duration: 600.ms)
                    .slideY(begin: 0.18, end: 0, curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EYEBROW TAG + TITLE
// ============================================================================

class _EyebrowTag extends StatelessWidget {
  final String text;
  final Color color;
  const _EyebrowTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 2.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Titre display — fade-in mot par mot avec léger slide pour effet cinématique.
class _StaggeredTitle extends StatelessWidget {
  final String text;
  const _StaggeredTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    // Tokenisation : on garde les retours à la ligne en élément séparé.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var li = 0; li < lines.length; li++)
          Wrap(
            spacing: 0,
            runSpacing: 0,
            children: () {
              final words = lines[li].split(' ');
              final widgets = <Widget>[];
              var idx = 0;
              for (var i = 0; i < words.length; i++) {
                widgets.add(
                  _WordAnim(
                    text: words[i] + (i == words.length - 1 ? '' : ' '),
                    delayMs: 140 + (li * 4 + idx) * 60,
                  ),
                );
                idx++;
              }
              return widgets;
            }(),
          ),
      ],
    );
  }
}

class _WordAnim extends StatelessWidget {
  final String text;
  final int delayMs;
  const _WordAnim({required this.text, required this.delayMs});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 38,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.6,
        height: 1.05,
      ),
    )
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 520.ms)
        .slideY(begin: 0.35, end: 0, curve: Curves.easeOutCubic, duration: 560.ms);
  }
}

// ============================================================================
// PAGE INDICATOR
// ============================================================================

class _PageIndicator extends StatelessWidget {
  final int count;
  final int current;
  final Color accent;

  const _PageIndicator({required this.count, required this.current, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: active ? 28 : 6,
          decoration: BoxDecoration(
            color: active ? accent : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(99),
            boxShadow: active
                ? [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 10)]
                : null,
          ),
        );
      }),
    );
  }
}

// ============================================================================
// BRAND DOT
// ============================================================================

class _BrandDot extends StatelessWidget {
  final Color color;
  const _BrandDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: const Center(
        child: Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: -0.4,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SCENE 1 — INVOICE STACK
// ============================================================================
//
// Trois "cartes devis" empilées avec rotation, glow violet, badge check.

class _SceneInvoiceStack extends StatefulWidget {
  const _SceneInvoiceStack();

  @override
  State<_SceneInvoiceStack> createState() => _SceneInvoiceStackState();
}

class _SceneInvoiceStackState extends State<_SceneInvoiceStack> with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 5400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_float.value);
        final dy = -6 + 12 * t;
        return Transform.translate(
          offset: Offset(0, dy),
          child: SizedBox(
            width: 280,
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Carte arrière 1
                _InvoiceCard(
                  rotation: -0.12,
                  offset: const Offset(-38, 24),
                  accent: const Color(0xFF6E4DFF),
                  opacity: 0.55,
                  scale: 0.92,
                  delayMs: 280,
                ),
                // Carte arrière 2
                _InvoiceCard(
                  rotation: 0.10,
                  offset: const Offset(36, 14),
                  accent: const Color(0xFF8E72FF),
                  opacity: 0.75,
                  scale: 0.95,
                  delayMs: 160,
                ),
                // Carte principale
                _InvoiceCard(
                  rotation: 0.0,
                  offset: Offset.zero,
                  accent: const Color(0xFF9B7BFF),
                  opacity: 1,
                  scale: 1.0,
                  showCheck: true,
                  delayMs: 0,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final double rotation;
  final Offset offset;
  final Color accent;
  final double opacity;
  final double scale;
  final bool showCheck;
  final int delayMs;

  const _InvoiceCard({
    required this.rotation,
    required this.offset,
    required this.accent,
    required this.opacity,
    required this.scale,
    this.showCheck = false,
    required this.delayMs,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 210,
              height: 270,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF15131E), Color(0xFF0E0C18)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 28,
                    spreadRadius: -4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Center(
                                child: Text('N',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        letterSpacing: -0.4)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('DEVIS',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: 2)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _LineBlock(width: 130, opacity: 0.86),
                        const SizedBox(height: 8),
                        _LineBlock(width: 90, opacity: 0.55),
                        const SizedBox(height: 22),
                        // Lignes du tableau (3)
                        for (var i = 0; i < 3; i++) ...[
                          Row(
                            children: [
                              Expanded(child: _LineBlock(width: double.infinity, opacity: 0.32 + i * 0.06)),
                              const SizedBox(width: 6),
                              _LineBlock(width: 28, opacity: 0.5),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        const Spacer(),
                        // Total
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TOTAL',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9.5,
                                      letterSpacing: 1.4)),
                              Text('245 000 $kCurrencyLabel',
                                  style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: -0.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showCheck)
                    Positioned(
                      top: -10,
                      right: -10,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.75)]),
                          boxShadow: [
                            BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 16, spreadRadius: -2),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                      )
                          .animate()
                          .scaleXY(begin: 0, end: 1, delay: 700.ms, duration: 520.ms, curve: Curves.elasticOut)
                          .fadeIn(delay: 700.ms, duration: 280.ms),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 560.ms)
        .scaleXY(begin: 0.7, end: 1.0, delay: delayMs.ms, duration: 760.ms, curve: Curves.easeOutBack);
  }
}

class _LineBlock extends StatelessWidget {
  final double width;
  final double opacity;
  const _LineBlock({required this.width, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity * 0.18),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

// ============================================================================
// SCENE 2 — ORBITAL UNITS
// ============================================================================
//
// Orbe central qui pulse, 6 chips d'unités qui orbitent à vitesse variable.

class _SceneOrbitalUnits extends StatefulWidget {
  const _SceneOrbitalUnits();

  @override
  State<_SceneOrbitalUnits> createState() => _SceneOrbitalUnitsState();
}

class _SceneOrbitalUnitsState extends State<_SceneOrbitalUnits> with SingleTickerProviderStateMixin {
  late final AnimationController _orbit;
  static const _units = ['m²', 'kg', 'L', 'h', 'm³', 'ml'];
  static const _accent = Color(0xFFE9C46A);

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: AnimatedBuilder(
        animation: _orbit,
        builder: (context, _) {
          final t = _orbit.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Anneaux décoratifs
              for (final ringRadius in const [140.0, 110.0])
                Container(
                  width: ringRadius * 2,
                  height: ringRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
                  ),
                ),
              // Orbites des chips
              for (var i = 0; i < _units.length; i++) ...[
                _orbitalChip(
                  label: _units[i],
                  radius: i.isEven ? 130 : 100,
                  angle: (i / _units.length) * math.pi * 2 + t * math.pi * 2 * (i.isEven ? 1 : -1) * 0.4,
                  i: i,
                ),
              ],
              // Orbe central
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFD97A), Color(0xFFB78A2A)],
                  ),
                  boxShadow: [
                    BoxShadow(color: _accent.withValues(alpha: 0.55), blurRadius: 40, spreadRadius: -4),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF15131E), Color(0xFF0E0C18)],
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.8),
                    ),
                    child: const Center(
                      child: Icon(Icons.architecture_rounded, color: _accent, size: 32),
                    ),
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.97, end: 1.04, duration: 2400.ms, curve: Curves.easeInOut),
            ],
          );
        },
      ),
    )
        .animate()
        .fadeIn(duration: 700.ms)
        .scaleXY(begin: 0.85, end: 1.0, duration: 800.ms, curve: Curves.easeOutCubic);
  }

  Widget _orbitalChip({required String label, required double radius, required double angle, required int i}) {
    final dx = radius * math.cos(angle);
    final dy = radius * math.sin(angle);
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: _accent.withValues(alpha: 0.32), width: 0.6),
          boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.18), blurRadius: 14)],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
      )
          .animate()
          .fadeIn(delay: (200 + i * 80).ms, duration: 500.ms)
          .scaleXY(begin: 0.4, end: 1.0, delay: (200 + i * 80).ms, duration: 600.ms, curve: Curves.easeOutBack),
    );
  }
}

// ============================================================================
// SCENE 3 — PDF DOCUMENT
// ============================================================================
//
// Mockup d'un PDF avec sceau or, signature, tilt 3D.

class _ScenePdfDocument extends StatefulWidget {
  const _ScenePdfDocument();

  @override
  State<_ScenePdfDocument> createState() => _ScenePdfDocumentState();
}

class _ScenePdfDocumentState extends State<_ScenePdfDocument> with SingleTickerProviderStateMixin {
  late final AnimationController _float;
  static const _gold = Color(0xFFE9C46A);
  static const _teal = Color(0xFF7AD8BE);

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 5400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 340,
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_float.value);
          final dy = -8 + 16 * t;
          final rot = -0.06 + 0.04 * t;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Lueur sous le document
              Positioned(
                bottom: 16,
                child: Container(
                  width: 230,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [_teal.withValues(alpha: 0.4), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, dy),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateZ(rot)
                    ..rotateY(0.08),
                  child: Container(
                    width: 220,
                    height: 290,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBFAF6),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: _teal.withValues(alpha: 0.25),
                          blurRadius: 40,
                          spreadRadius: -6,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo + brand
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF001B4E), Color(0xFF002766)],
                                  ),
                                ),
                                child: const Center(
                                  child: Text('NG',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 8.5)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('NG DEVIS',
                                  style: TextStyle(
                                      color: Color(0xFF001B4E),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                      letterSpacing: 1.2)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Bandeau DEVIS
                          const Text(
                            'DEVIS',
                            style: TextStyle(
                              color: Color(0xFF0E1019),
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                              height: 1,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 50,
                            height: 3,
                            color: const Color(0xFFE30613),
                          ),
                          const SizedBox(height: 14),
                          // Lignes de tableau
                          for (var i = 0; i < 5; i++) ...[
                            Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Container(
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0E1019).withValues(alpha: 0.10 + i * 0.04),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 18,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0E1019).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                          ],
                          const Spacer(),
                          // Total
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF001B4E).withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TOTAL',
                                    style: TextStyle(
                                        color: Color(0xFF001B4E),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 8.5,
                                        letterSpacing: 1.6)),
                                Text('1 245 000 $kCurrencyLabel',
                                    style: const TextStyle(
                                        color: Color(0xFFE30613),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        letterSpacing: -0.3)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Sceau or animé
              Positioned(
                top: 26,
                right: 22,
                child: Transform.rotate(
                  angle: -0.18,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFFE39B), Color(0xFFB78A2A)],
                      ),
                      boxShadow: [
                        BoxShadow(color: _gold.withValues(alpha: 0.5), blurRadius: 24, spreadRadius: -2),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF7E5510), width: 1.4),
                        ),
                        child: const Center(
                          child: Icon(Icons.workspace_premium_rounded, color: Color(0xFF5A3A05), size: 24),
                        ),
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 0.96, end: 1.04, duration: 2200.ms, curve: Curves.easeInOut),
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 360.ms)
                  .scaleXY(begin: 0.4, end: 1, delay: 600.ms, duration: 700.ms, curve: Curves.elasticOut),
            ],
          );
        },
      ),
    )
        .animate()
        .fadeIn(duration: 700.ms)
        .slideY(begin: 0.1, end: 0, duration: 700.ms, curve: Curves.easeOutCubic);
  }
}
