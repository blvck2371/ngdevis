import 'package:flutter/material.dart';

/// Seuils de largeur pour le layout responsive.
class Breakpoints {
  static const double compact = 600;   // téléphone portrait
  static const double medium = 840;   // téléphone paysage / petite tablette
  static const double expanded = 1200; // tablette / desktop
  /// À partir de cette largeur, formulaire et aperçu PDF côte à côte (sans scroller pour voir l’aperçu).
  static const double sideBySide = 900;
}

/// Utilitaires pour des layouts responsives et intuitifs.
class Responsive {
  final BuildContext context;
  const Responsive(this.context);

  MediaQueryData get _media => MediaQuery.of(context);
  double get width => _media.size.width;
  double get height => _media.size.height;
  EdgeInsets get padding => _media.padding;
  bool get isCompact => width < Breakpoints.compact;
  bool get isMedium => width >= Breakpoints.compact && width < Breakpoints.medium;
  bool get isExpanded => width >= Breakpoints.medium;
  bool get isTabletOrWider => width >= Breakpoints.compact;
  /// True sur tablette / PC : formulaire à gauche, aperçu PDF à droite (toujours visible).
  bool get isSideBySide => width >= Breakpoints.sideBySide;

  /// Padding horizontal adapté à la largeur d'écran.
  double get horizontalPadding {
    if (isCompact) return 16;
    if (isMedium) return 24;
    return 32;
  }

  /// Espacement vertical entre sections.
  double get sectionSpacing => isCompact ? 16 : 24;

  /// Nombre de colonnes pour une grille (dashboard, formulaires).
  int get gridColumns {
    if (width < Breakpoints.compact) return 1;
    if (width < Breakpoints.medium) return 2;
    return 3;
  }

  /// Largeur max pour le contenu (lisibilité sur grand écran).
  double get maxContentWidth => isExpanded ? 800 : double.infinity;

  /// Zone sûre (encoche, barre de statut).
  EdgeInsets get safePadding => padding;
}

extension ResponsiveContext on BuildContext {
  Responsive get responsive => Responsive(this);
}
