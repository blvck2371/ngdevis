import 'devis_unit.dart';

/// Modèle pour une désignation (matériau / prestation) dans la base.
///
/// [uniteDefaut] (optionnelle) est le code d'unité suggéré à l'ajout d'une
/// ligne de devis utilisant cette désignation (ex. câble électrique → `m`,
/// ciment → `kg`, prestation → `h`).
class Designation {
  String id;
  String nom;
  double prixUnitaire;
  String categorie;
  String uniteDefaut;

  Designation({
    required this.id,
    required this.nom,
    required this.prixUnitaire,
    required this.categorie,
    String? uniteDefaut,
  }) : uniteDefaut = DevisUnit.fromCode(uniteDefaut).code;

  /// Représentation enrichie de l'unité par défaut.
  DevisUnit get unit => DevisUnit.fromCode(uniteDefaut);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'prixUnitaire': prixUnitaire,
        'categorie': categorie,
        'uniteDefaut': uniteDefaut,
      };

  factory Designation.fromJson(Map<String, dynamic> json) => Designation(
        id: (json['id'] as String?) ?? '',
        nom: (json['nom'] as String?) ?? '',
        prixUnitaire: ((json['prixUnitaire'] as num?) ?? 0).toDouble(),
        categorie: (json['categorie'] as String?) ?? '',
        uniteDefaut: json['uniteDefaut'] as String?,
      );
}
