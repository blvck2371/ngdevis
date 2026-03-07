/// Une ligne du tableau devis : Désignation, Quantité, PU, PT (calculé).
class DevisItem {
  String designation;
  double quantite;
  double prixUnitaire;
  String? designationId;

  DevisItem({
    required this.designation,
    required this.quantite,
    required this.prixUnitaire,
    this.designationId,
  });

  double get total => quantite * prixUnitaire;

  Map<String, dynamic> toJson() => {
        'designation': designation,
        'quantite': quantite,
        'prixUnitaire': prixUnitaire,
        'designationId': designationId,
      };

  factory DevisItem.fromJson(Map<String, dynamic> json) => DevisItem(
        designation: json['designation'] as String,
        quantite: (json['quantite'] as num).toDouble(),
        prixUnitaire: (json['prixUnitaire'] as num).toDouble(),
        designationId: json['designationId'] as String?,
      );
}
