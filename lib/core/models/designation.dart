/// Modèle pour une désignation (matériau) dans la base.
class Designation {
  String id;
  String nom;
  double prixUnitaire;
  String categorie;

  Designation({
    required this.id,
    required this.nom,
    required this.prixUnitaire,
    required this.categorie,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'prixUnitaire': prixUnitaire,
        'categorie': categorie,
      };

  factory Designation.fromJson(Map<String, dynamic> json) => Designation(
        id: (json['id'] as String?) ?? '',
        nom: (json['nom'] as String?) ?? '',
        prixUnitaire: ((json['prixUnitaire'] as num?) ?? 0).toDouble(),
        categorie: (json['categorie'] as String?) ?? '',
      );
}
