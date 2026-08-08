/// Liste des couvertures (page de garde A4) disponibles pour les documents
/// (devis, facture). Chaque entrée est un *style visuel unique* — l'image
/// d'arrière‑plan est dessinée pleine page et les informations utilisateur
/// (titre, numéro, date, client, société) viennent se placer dans les
/// **zones blanches** prévues par le designer du template.
///
/// L'ordre du `enum` est l'ordre d'affichage dans le sélecteur.
library;

enum CoverTemplate {
  /// Modèle d'origine, totalement vectoriel — bâtiment + triangles
  /// navy/rouge, "NG DEVIS" en filigrane, footer NAVY plein. Ce modèle est
  /// dessiné en code (pas une image PNG) pour des raisons historiques.
  classic,

  /// Couverture orientale : tons orange + gold, arabesques + silhouette
  /// de mosquée. Élégant, festif.
  orientalOrange,

  /// Couverture corporate premium : bleu navy profond, lignes or, bâtiment
  /// moderne, footer 3 colonnes contact.
  corporateNavyGold,

  /// Couverture luxe minimaliste : coins noirs arrondis, accents or, marbre.
  /// Très sobre, hautement professionnel.
  blackGoldLuxe,

  /// Géométrique navy + or : grand bâtiment diagonal, triangles navy.
  navyGeometric,

  /// Arabesque haut de gamme : courbes navy + or, mosquée filigranée.
  navyArabesque,

  /// Minimaliste noir & or : coins noirs, lignes or fines, beaucoup d'air.
  minimalistGold,

  /// Couverture vectorielle — ardoise & teal, typographie éditoriale (design NG).
  studioSlate,

  /// Couverture vectorielle — émeraude profond & or, prestige artisan / BTP haut de gamme.
  prestigeEmerald,
}

extension CoverTemplateMeta on CoverTemplate {
  /// Libellé court affiché dans la liste / picker.
  String get label {
    switch (this) {
      case CoverTemplate.classic:
        return 'Classique';
      case CoverTemplate.orientalOrange:
        return 'Oriental Or';
      case CoverTemplate.corporateNavyGold:
        return 'Corporate Navy';
      case CoverTemplate.blackGoldLuxe:
        return 'Black & Gold';
      case CoverTemplate.navyGeometric:
        return 'Navy Géométrique';
      case CoverTemplate.navyArabesque:
        return 'Navy Arabesque';
      case CoverTemplate.minimalistGold:
        return 'Minimaliste Or';
      case CoverTemplate.studioSlate:
        return 'Studio Ardoise';
      case CoverTemplate.prestigeEmerald:
        return 'Prestige Émeraude';
    }
  }

  /// Description marketing pour la fiche du picker.
  String get description {
    switch (this) {
      case CoverTemplate.classic:
        return 'Le modèle historique de l\'app : bâtiment, triangles navy/rouge, signature NG.';
      case CoverTemplate.orientalOrange:
        return 'Tons orange et or, arabesques sublimes — pour un rendu chaleureux et raffiné.';
      case CoverTemplate.corporateNavyGold:
        return 'Bleu profond + or, design d\'entreprise, footer 3 colonnes contact.';
      case CoverTemplate.blackGoldLuxe:
        return 'Coins noirs, marbre et accents or — l\'élégance discrète d\'un cabinet de luxe.';
      case CoverTemplate.navyGeometric:
        return 'Architecture moderne, triangles navy, lignes or — épuré et masculin.';
      case CoverTemplate.navyArabesque:
        return 'Courbes navy, arabesques or, silhouette de mosquée — premium et solennel.';
      case CoverTemplate.minimalistGold:
        return 'Très peu d\'ornements, beaucoup d\'air — pour les designs ultra‑modernes.';
      case CoverTemplate.studioSlate:
        return 'Design épuré ardoise & teal — typographie nette, zones client structurées.';
      case CoverTemplate.prestigeEmerald:
        return 'Émeraude profond et or discret — élégance premium pour devis haut de gamme.';
    }
  }

  /// Modèles dessinés entièrement en vectoriel (pas de PNG de fond).
  bool get isVectorCover =>
      this == CoverTemplate.studioSlate ||
      this == CoverTemplate.prestigeEmerald;

  /// Chemin de l'asset PNG plein page (null pour le modèle classique
  /// qui est dessiné en code).
  String? get assetPath {
    switch (this) {
      case CoverTemplate.classic:
        return null;
      case CoverTemplate.orientalOrange:
        return 'assets/f1bd15ce-23c8-493a-ba04-4ffff74bd765.png';
      case CoverTemplate.corporateNavyGold:
        return 'assets/navygold.png';
      case CoverTemplate.blackGoldLuxe:
        return 'assets/c091b6e3-1f41-4e0a-b6df-e33e6f41e622.png';
      case CoverTemplate.navyGeometric:
        return 'assets/ac8f1c49-feca-4b4d-9b8f-dd02cb29aa10.png';
      case CoverTemplate.navyArabesque:
        return 'assets/267d2250-8a3e-45ab-8334-13e0f24ebf8b.png';
      case CoverTemplate.minimalistGold:
        return 'assets/0d1b09be-94ec-4c0b-a7c4-5f83e9125441.png';
      case CoverTemplate.studioSlate:
      case CoverTemplate.prestigeEmerald:
        return null;
    }
  }

  /// Image de prévisualisation côté Flutter (sans branding utilisateur).
  /// Pour le moment on réutilise le PNG plein page ; le modèle "classic"
  /// utilise sa propre image historique.
  String? get thumbnailAsset {
    if (this == CoverTemplate.classic) {
      return 'assets/e175b1a5-7eef-4403-a781-493ba464ba89.png';
    }
    if (isVectorCover) return null;
    return assetPath!;
  }

  /// Gabarit designer (px) — tous les PNG couverture sont calés sur l’A4.
  static const double designWidth = 1055;
  static const double designHeight = 1491;

  /// Couleur dominante utilisée pour les badges dans le picker.
  /// Codée en `int` pour ne pas imposer de dépendance Flutter dans ce fichier.
  int get accentColor {
    switch (this) {
      case CoverTemplate.classic:
        return 0xFFC62828; // rouge NG
      case CoverTemplate.orientalOrange:
        return 0xFFE07C24; // orange terracotta
      case CoverTemplate.corporateNavyGold:
        return 0xFFB7892F; // or
      case CoverTemplate.blackGoldLuxe:
        return 0xFFB7892F;
      case CoverTemplate.navyGeometric:
        return 0xFF001B4E; // navy
      case CoverTemplate.navyArabesque:
        return 0xFF1A2F66;
      case CoverTemplate.minimalistGold:
        return 0xFFB7892F;
      case CoverTemplate.studioSlate:
        return 0xFF00897B;
      case CoverTemplate.prestigeEmerald:
        return 0xFF0B4F4A;
    }
  }
}

/// Convertit l'id (persistance) en `CoverTemplate`. Robuste : retombe sur
/// [CoverTemplate.classic] si la valeur est inconnue (ex. ancien id supprimé).
CoverTemplate coverTemplateFromId(String? id) {
  if (id == null || id.isEmpty) return CoverTemplate.classic;
  for (final t in CoverTemplate.values) {
    if (t.name == id) return t;
  }
  return CoverTemplate.classic;
}
