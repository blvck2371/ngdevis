import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thème premium NG Devis — version 2026.
///
/// Direction artistique :
///   - **Dark mode** principal : noir profond (`#06070C`) avec surfaces graphite
///     et accents violet (`#7C5CFF`) + or pâle (`#E9C46A`) pour les chiffres
///     premium (revenus, totaux).
///   - **Light mode** miroir : blanc cassé (`#F7F8FB`), surfaces nacrées,
///     mêmes accents pour une cohérence parfaite.
///   - Typographie **Plus Jakarta Sans** (Google Fonts) — lettrage moderne,
///     très lisible, dans la lignée des SaaS premium.
///   - Coins doux 18-24px (cards), boutons hauts en gamme 14-18px de rayon.
///
/// Toutes les couleurs sont exposées en [AppColors] pour être réutilisées
/// dans les composants glassmorphism / charts / illustrations.
class AppTheme {
  AppTheme._();

  // ----- LIGHT ---------------------------------------------------------------
  static ThemeData get light => _build(_lightColors, Brightness.light);

  // ----- DARK ----------------------------------------------------------------
  static ThemeData get dark => _build(_darkColors, Brightness.dark);

  static const _LightPalette _lightColors = _LightPalette();
  static const _DarkPalette _darkColors = _DarkPalette();

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: p.ink,
      displayColor: p.ink,
    );

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.accent,
        onPrimary: Colors.white,
        primaryContainer: p.accentSoft,
        onPrimaryContainer: p.ink,
        secondary: p.gold,
        onSecondary: const Color(0xFF1B1300),
        secondaryContainer: p.goldSoft,
        onSecondaryContainer: p.ink,
        tertiary: p.success,
        onTertiary: Colors.white,
        error: p.error,
        onError: Colors.white,
        surface: p.surface,
        onSurface: p.ink,
        onSurfaceVariant: p.inkMuted,
        surfaceContainerHighest: p.surfaceHigh,
        surfaceContainer: p.surface,
        surfaceContainerLow: p.surfaceLow,
        surfaceContainerLowest: p.background,
        surfaceContainerHigh: p.surfaceHigh,
        outline: p.outline,
        outlineVariant: p.outlineSoft,
        inverseSurface: isDark ? p.background : const Color(0xFF1A1B22),
        onInverseSurface: isDark ? p.ink : Colors.white,
        inversePrimary: p.accent,
        shadow: Colors.black.withValues(alpha: 0.16),
        scrim: Colors.black.withValues(alpha: 0.42),
        surfaceTint: Colors.transparent,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(letterSpacing: -1.2, fontWeight: FontWeight.w700, color: p.ink),
        displayMedium: textTheme.displayMedium?.copyWith(letterSpacing: -1.0, fontWeight: FontWeight.w700, color: p.ink),
        headlineLarge: textTheme.headlineLarge?.copyWith(letterSpacing: -0.6, fontWeight: FontWeight.w700, color: p.ink),
        headlineMedium: textTheme.headlineMedium?.copyWith(letterSpacing: -0.4, fontWeight: FontWeight.w700, color: p.ink),
        headlineSmall: textTheme.headlineSmall?.copyWith(letterSpacing: -0.2, fontWeight: FontWeight.w700, color: p.ink),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: p.ink),
        titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: p.ink),
        titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: p.ink),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: p.ink, height: 1.5),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: p.ink, height: 1.45),
        bodySmall: textTheme.bodySmall?.copyWith(color: p.inkMuted, height: 1.4),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: p.ink, letterSpacing: 0.1),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: p.ink,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: p.ink, letterSpacing: -0.2),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceLow,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.inkMuted.withValues(alpha: 0.65)),
        labelStyle: textTheme.bodyMedium?.copyWith(color: p.inkMuted, fontWeight: FontWeight.w500),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(color: p.accent, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.outlineSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.outlineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.error, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(80, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          side: BorderSide(color: p.outlineSoft),
          minimumSize: const Size(80, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceHigh,
        selectedColor: p.accentSoft,
        secondarySelectedColor: p.accent,
        labelStyle: textTheme.labelLarge?.copyWith(color: p.ink, fontWeight: FontWeight.w600),
        side: BorderSide(color: p.outlineSoft),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        iconColor: p.inkMuted,
        textColor: p.ink,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: p.ink),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.inkMuted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: p.outlineSoft,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.background, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: p.outlineSoft, thickness: 1, space: 1),
      tabBarTheme: TabBarThemeData(
        labelColor: p.ink,
        unselectedLabelColor: p.inkMuted,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        indicatorSize: TabBarIndicatorSize.label,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceHigh,
        circularTrackColor: p.surfaceHigh,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.outlineSoft),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: p.ink),
      ),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

/// Palette accessible partout (composants custom, peintres, charts, PDF UI).
/// Récupère la bonne variante via `AppColors.of(context)`.
class AppColors {
  AppColors._();
  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppTheme._darkColors
          : AppTheme._lightColors;
}

/// Contrat de palette publique — partagé entre dark & light.
abstract class AppPalette {
  Color get background;
  Color get surface;
  Color get surfaceLow;
  Color get surfaceHigh;
  Color get ink;
  Color get inkMuted;
  Color get outline;
  Color get outlineSoft;
  Color get accent;
  Color get accentSoft;
  Color get accentDeep;
  Color get gold;
  Color get goldSoft;
  Color get success;
  Color get error;
  Color get warning;

  /// Couleurs de gradient mesh pour l'arrière-plan premium (3 blobs).
  List<Color> get meshBlobs;
  /// Couleurs des barres de graphique (revenus mensuels).
  List<Color> get chartBars;
}

class _DarkPalette implements AppPalette {
  const _DarkPalette();
  @override final Color background = const Color(0xFF06070C);
  @override final Color surface = const Color(0xFF111219);
  @override final Color surfaceLow = const Color(0xFF0B0C12);
  @override final Color surfaceHigh = const Color(0xFF1B1D26);
  @override final Color ink = const Color(0xFFF2F3F7);
  @override final Color inkMuted = const Color(0xFF8A8D9B);
  @override final Color outline = const Color(0xFF2A2D38);
  @override final Color outlineSoft = const Color(0xFF1F2230);
  @override final Color accent = const Color(0xFF7C5CFF);
  @override final Color accentSoft = const Color(0xFF231C45);
  @override final Color accentDeep = const Color(0xFF5736E6);
  @override final Color gold = const Color(0xFFE9C46A);
  @override final Color goldSoft = const Color(0xFF3A2E10);
  @override final Color success = const Color(0xFF22D39A);
  @override final Color error = const Color(0xFFFF5C7A);
  @override final Color warning = const Color(0xFFFFB454);

  @override
  List<Color> get meshBlobs => const [
        Color(0xFF7C5CFF),
        Color(0xFFE9C46A),
        Color(0xFF22D39A),
      ];
  @override
  List<Color> get chartBars => const [
        Color(0xFF7C5CFF),
        Color(0xFFA48BFF),
      ];
}

class _LightPalette implements AppPalette {
  const _LightPalette();
  @override final Color background = const Color(0xFFF7F8FB);
  @override final Color surface = const Color(0xFFFFFFFF);
  @override final Color surfaceLow = const Color(0xFFF1F2F7);
  @override final Color surfaceHigh = const Color(0xFFEDEFF5);
  @override final Color ink = const Color(0xFF0F1115);
  @override final Color inkMuted = const Color(0xFF5C616D);
  @override final Color outline = const Color(0xFFD7DBE5);
  @override final Color outlineSoft = const Color(0xFFE6E9F0);
  @override final Color accent = const Color(0xFF6C4DF6);
  @override final Color accentSoft = const Color(0xFFEAE3FE);
  @override final Color accentDeep = const Color(0xFF4A2DD8);
  @override final Color gold = const Color(0xFFB7892F);
  @override final Color goldSoft = const Color(0xFFFBF1D8);
  @override final Color success = const Color(0xFF12A26F);
  @override final Color error = const Color(0xFFE03853);
  @override final Color warning = const Color(0xFFC97A1A);

  @override
  List<Color> get meshBlobs => const [
        Color(0xFF6C4DF6),
        Color(0xFFB7892F),
        Color(0xFF12A26F),
      ];
  @override
  List<Color> get chartBars => const [
        Color(0xFF6C4DF6),
        Color(0xFF9F84FB),
      ];
}
