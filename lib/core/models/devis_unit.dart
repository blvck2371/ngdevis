/// Moteur d'unités pour les lignes de devis.
///
/// Une [DevisUnit] représente une unité de mesure (longueur, surface, volume,
/// masse, temps, ...) avec :
///   * un [code] stable utilisé pour la persistance (Hive / JSON),
///   * un [symbole] court pour l'affichage (tableaux, PDF),
///   * un [label] long pour les menus déroulants,
///   * une [categorie] logique pour grouper les unités.
///
/// Le code est volontairement ASCII pour rester lisible dans le JSON
/// (ex. `m2` plutôt que `m²`). Le symbole, lui, est le rendu utilisateur.
library;

enum DevisUnitCategory {
  generique,
  longueur,
  surface,
  volume,
  masse,
  temps,
}

class DevisUnit {
  final String code;
  final String symbole;
  final String label;
  final DevisUnitCategory categorie;

  const DevisUnit({
    required this.code,
    required this.symbole,
    required this.label,
    required this.categorie,
  });

  // -- Générique --------------------------------------------------------------
  static const unite = DevisUnit(
    code: 'u',
    symbole: 'u',
    label: 'Unité (pièce)',
    categorie: DevisUnitCategory.generique,
  );
  static const forfait = DevisUnit(
    code: 'forfait',
    symbole: 'forfait',
    label: 'Forfait',
    categorie: DevisUnitCategory.generique,
  );
  static const ens = DevisUnit(
    code: 'ens',
    symbole: 'ens',
    label: 'Ensemble',
    categorie: DevisUnitCategory.generique,
  );

  // -- Longueur ---------------------------------------------------------------
  static const m = DevisUnit(
    code: 'm',
    symbole: 'm',
    label: 'Mètre',
    categorie: DevisUnitCategory.longueur,
  );
  static const ml = DevisUnit(
    code: 'ml',
    symbole: 'ml',
    label: 'Mètre linéaire',
    categorie: DevisUnitCategory.longueur,
  );
  static const cm = DevisUnit(
    code: 'cm',
    symbole: 'cm',
    label: 'Centimètre',
    categorie: DevisUnitCategory.longueur,
  );
  static const mm = DevisUnit(
    code: 'mm',
    symbole: 'mm',
    label: 'Millimètre',
    categorie: DevisUnitCategory.longueur,
  );

  // -- Surface ---------------------------------------------------------------
  static const m2 = DevisUnit(
    code: 'm2',
    symbole: 'm²',
    label: 'Mètre carré',
    categorie: DevisUnitCategory.surface,
  );

  // -- Volume ----------------------------------------------------------------
  static const m3 = DevisUnit(
    code: 'm3',
    symbole: 'm³',
    label: 'Mètre cube',
    categorie: DevisUnitCategory.volume,
  );
  static const litre = DevisUnit(
    code: 'L',
    symbole: 'L',
    label: 'Litre',
    categorie: DevisUnitCategory.volume,
  );
  static const millilitre = DevisUnit(
    code: 'mL',
    symbole: 'mL',
    label: 'Millilitre',
    categorie: DevisUnitCategory.volume,
  );

  // -- Masse -----------------------------------------------------------------
  static const kg = DevisUnit(
    code: 'kg',
    symbole: 'kg',
    label: 'Kilogramme',
    categorie: DevisUnitCategory.masse,
  );
  static const g = DevisUnit(
    code: 'g',
    symbole: 'g',
    label: 'Gramme',
    categorie: DevisUnitCategory.masse,
  );

  // -- Temps -----------------------------------------------------------------
  static const h = DevisUnit(
    code: 'h',
    symbole: 'h',
    label: 'Heure',
    categorie: DevisUnitCategory.temps,
  );
  static const j = DevisUnit(
    code: 'j',
    symbole: 'j',
    label: 'Jour',
    categorie: DevisUnitCategory.temps,
  );

  /// Liste ordonnée pour les menus : générique d'abord, puis longueur, surface,
  /// volume, masse, temps. Cet ordre est utilisé par les sélecteurs UI.
  static const List<DevisUnit> all = <DevisUnit>[
    unite,
    forfait,
    ens,
    m,
    ml,
    cm,
    mm,
    m2,
    m3,
    litre,
    millilitre,
    kg,
    g,
    h,
    j,
  ];

  /// Libellé court pour les groupes du menu déroulant.
  static String categoryLabel(DevisUnitCategory cat) {
    switch (cat) {
      case DevisUnitCategory.generique:
        return 'Général';
      case DevisUnitCategory.longueur:
        return 'Longueur';
      case DevisUnitCategory.surface:
        return 'Surface';
      case DevisUnitCategory.volume:
        return 'Volume';
      case DevisUnitCategory.masse:
        return 'Masse';
      case DevisUnitCategory.temps:
        return 'Temps';
    }
  }

  /// Retourne l'unité correspondant au [code] (insensible à la casse), ou
  /// [unite] par défaut. Tolérant aux codes inconnus ou aux saisies historiques
  /// (rétrocompat Hive / CSV / imports humains).
  static DevisUnit fromCode(String? code) {
    final c = (code ?? '').trim();
    if (c.isEmpty) return unite;
    for (final u in all) {
      if (u.code.toLowerCase() == c.toLowerCase()) return u;
    }
    // Alias usuels (saisies libres anciennes ou imports tiers).
    switch (c.toLowerCase()) {
      case 'm²':
      case 'm^2':
      case 'metre carre':
      case 'mètre carré':
        return m2;
      case 'm³':
      case 'm^3':
      case 'metre cube':
      case 'mètre cube':
        return m3;
      case 'l':
      case 'litres':
      case 'litre':
        return litre;
      case 'millilitre':
      case 'millilitres':
        return millilitre;
      case 'heure':
      case 'heures':
        return h;
      case 'jour':
      case 'jours':
        return j;
      case 'piece':
      case 'pièce':
      case 'pieces':
      case 'pièces':
      case 'unite':
      case 'unité':
      case 'unites':
      case 'unités':
        return unite;
      case 'fft':
      case 'fft.':
      case 'forfait':
        return forfait;
      case 'ensemble':
        return ens;
      default:
        return unite;
    }
  }

  /// Formate une quantité avec son unité pour affichage (PDF, tableau, listes).
  ///
  /// Règles :
  ///   * [unite] (u)         → seulement le nombre, ex. `10` ou `2,5` (tableau plus propre).
  ///   * [forfait]           → toujours `Forfait` (la quantité n'a pas de sens).
  ///   * autres unités       → `<nombre> <symbole>`, ex. `10 m`, `2,5 m²`, `5 kg`.
  static String formatQuantity(DevisUnit unit, double quantite) {
    if (unit.code == forfait.code) return forfait.symbole;
    final qty = formatNumber(quantite);
    if (unit.code == unite.code) return qty;
    return '$qty ${unit.symbole}';
  }

  /// Formate uniquement la valeur numérique : entier si entier, sinon
  /// deux décimales maximum avec virgule (locale FR).
  static String formatNumber(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    final fixed = v.toStringAsFixed(2);
    // Retirer les zéros décimaux non significatifs (2,50 -> 2,5)
    final trimmed = fixed.endsWith('0')
        ? fixed.substring(0, fixed.length - 1)
        : fixed;
    return trimmed.replaceAll('.', ',');
  }

  @override
  bool operator ==(Object other) => other is DevisUnit && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'DevisUnit($code)';
}
