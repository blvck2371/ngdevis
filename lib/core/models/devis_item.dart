import 'devis_unit.dart';

/// Une ligne du tableau devis : Désignation, Quantité, Unité, PU, PT (calculé).
///
/// Le champ [unite] stocke le **code** de l'unité (cf. [DevisUnit.code]).
/// La rétrocompatibilité avec les anciens devis (sans unité) est assurée :
/// [DevisItem.fromJson] retourne `'u'` quand la clé est absente.
class DevisItem {
  String designation;
  double quantite;
  double prixUnitaire;
  String? designationId;

  /// Code stable de l'unité de mesure (voir [DevisUnit]). `'u'` par défaut.
  String unite;

  DevisItem({
    required this.designation,
    required this.quantite,
    required this.prixUnitaire,
    this.designationId,
    String? unite,
  }) : unite = DevisUnit.fromCode(unite).code;

  /// Représentation enrichie de l'unité (symbole, label, catégorie).
  DevisUnit get unit => DevisUnit.fromCode(unite);

  /// Total ligne. La formule `quantite * prixUnitaire` reste identique quelle
  /// que soit l'unité — pour un « Forfait » l'utilisateur met simplement
  /// quantité = 1, ce qui donne `prixUnitaire`. Aucun changement de
  /// sémantique par rapport aux devis existants.
  double get total => quantite * prixUnitaire;

  Map<String, dynamic> toJson() => {
        'designation': designation,
        'quantite': quantite,
        'prixUnitaire': prixUnitaire,
        'designationId': designationId,
        'unite': unite,
      };

  factory DevisItem.fromJson(Map<String, dynamic> json) => DevisItem(
        designation: json['designation'] as String,
        quantite: (json['quantite'] as num).toDouble(),
        prixUnitaire: (json['prixUnitaire'] as num).toDouble(),
        designationId: json['designationId'] as String?,
        unite: json['unite'] as String?,
      );
}
