import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../core/database/hive_storage.dart';
import '../core/utils/app_routes.dart';

/// Splash éditorial — palette **noir profond + violet**.
///
/// Composition étudiée : un halo radial violet derrière un monogramme NG
/// (où le G est rouge brand), wordmark sous le logo, micro-loader discret.
/// Pas de mesh multicolore : on garde une seule direction de lumière.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // On laisse les animations se jouer ~2.0s avant de router.
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    final next = HiveStorage.isOnboardingSeen()
        ? AppRoutes.dashboard
        : AppRoutes.onboarding;
    Get.offAllNamed(next);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF06060C),
        // **extendBody/extendBodyBehindAppBar** : on s'assure que le body
        // couvre **vraiment** toute la fenêtre, status bar et nav bar incluses.
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: SizedBox(
          width: mq.size.width,
          height: mq.size.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Fond + halo : occupe TOUTE la surface, sous les bars système.
              const _HaloBackground(),
              // Contenu utile : en zone safe pour ne pas être masqué par les
              // bars système, mais le fond reste edge-to-edge derrière.
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 4),
                      const _LogoMark()
                          .animate()
                          .fadeIn(duration: 700.ms)
                          .scaleXY(
                            begin: 0.7,
                            end: 1.0,
                            duration: 900.ms,
                            curve: Curves.easeOutCubic,
                          ),
                      const SizedBox(height: 28),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'N',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.96),
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.4,
                                height: 1,
                              ),
                            ),
                            const TextSpan(
                              text: 'G',
                              style: TextStyle(
                                color: Color(0xFFE63946),
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.4,
                                height: 1,
                              ),
                            ),
                            TextSpan(
                              text: '   Devis',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.96),
                                fontSize: 36,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -1.0,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 700.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C5CFF).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: const Color(0xFF7C5CFF).withValues(alpha: 0.28),
                            width: 0.6,
                          ),
                        ),
                        child: const Text(
                          'DEVIS · FACTURES · PDF',
                          style: TextStyle(
                            color: Color(0xFFC2B3FF),
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                            letterSpacing: 3.2,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 500.ms)
                          .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
                      const Spacer(flex: 6),
                      const _LineLoader()
                          .animate()
                          .fadeIn(delay: 900.ms, duration: 400.ms),
                      const SizedBox(height: 18),
                      Text(
                        'Préparation de votre espace',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.46),
                          fontSize: 12,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 1100.ms, duration: 500.ms),
                      const SizedBox(height: 32),
                    ],
                  ),
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
// HALO BACKGROUND
// ============================================================================

class _HaloBackground extends StatefulWidget {
  const _HaloBackground();

  @override
  State<_HaloBackground> createState() => _HaloBackgroundState();
}

class _HaloBackgroundState extends State<_HaloBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) => CustomPaint(
        painter: _HaloPainter(t: _drift.value),
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  final double t;
  _HaloPainter({required this.t});

  static const _violet = Color(0xFF7C5CFF);
  static const _violetDeep = Color(0xFF3B1E9E);

  @override
  void paint(Canvas canvas, Size size) {
    // Fond uniforme très sombre
    final base = Paint()..color = const Color(0xFF06060C);
    canvas.drawRect(Offset.zero & size, base);

    // Gradient vertical : un soupçon de violet en haut, noir en bas
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _violetDeep.withValues(alpha: 0.32),
            const Color(0xFF06060C),
            const Color(0xFF06060C),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Offset.zero & size),
    );

    // Halo principal violet — centré, animé en douceur
    final cx = size.width * 0.5;
    final cy = size.height * (0.42 + 0.02 * math.sin(t * math.pi * 2));
    final radius = size.shortestSide * 0.85;
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            _violet.withValues(alpha: 0.38),
            _violet.withValues(alpha: 0.10),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius)),
    );

    // Petits éclats étoilés (très discrets)
    final rng = math.Random(7);
    final star = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (var i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.6 + rng.nextDouble() * 1.4,
        star,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HaloPainter old) => old.t != t;
}

// ============================================================================
// LOGO MARK
// ============================================================================

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  static const _accent = Color(0xFF7C5CFF);
  static const _accentDeep = Color(0xFF4A2DD8);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anneau de lumière pulsé
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x447C5CFF), Color(0x007C5CFF)],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.85, end: 1.15, duration: 1800.ms, curve: Curves.easeInOut),

          // Carré principal arrondi avec monogramme NG
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_accent, _accentDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.5),
                  blurRadius: 26,
                  spreadRadius: -2,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Center(
              child: Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(
                      text: 'N',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: 'G',
                      style: TextStyle(
                        color: Color(0xFFE63946),
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LINE LOADER — indéterminé, fin et discret
// ============================================================================

class _LineLoader extends StatefulWidget {
  const _LineLoader();

  @override
  State<_LineLoader> createState() => _LineLoaderState();
}

class _LineLoaderState extends State<_LineLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Stack(
          children: [
            Container(color: Colors.white.withValues(alpha: 0.08)),
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = _ctrl.value;
                // Petit segment lumineux qui glisse de gauche à droite
                return Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Container(
                    width: 40,
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xFF7C5CFF),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
