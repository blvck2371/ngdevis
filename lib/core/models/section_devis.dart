import 'devis_item.dart';

class SectionDevis {
  String titre;
  List<DevisItem> items;
  /// Pourcentage de main d'œuvre appliqué au total matériel (ex. 15 = 15%). Si > 0, mainOeuvre est calculé.
  double mainOeuvrePercent;
  /// Montant fixe (utilisé si mainOeuvrePercent == 0, rétrocompatibilité).
  double mainOeuvreFixed;

  SectionDevis({
    required this.titre,
    List<DevisItem>? items,
    this.mainOeuvrePercent = 0,
    this.mainOeuvreFixed = 0,
  }) : items = items ?? [];

  double get totalMateriel =>
      items.fold(0.0, (sum, item) => sum + item.total);

  /// Main d'œuvre : pourcentage du total matériel si mainOeuvrePercent > 0, sinon montant fixe.
  double get mainOeuvre =>
      mainOeuvrePercent > 0
          ? totalMateriel * (mainOeuvrePercent / 100)
          : mainOeuvreFixed;

  double get totalSection => totalMateriel + mainOeuvre;

  Map<String, dynamic> toJson() => {
        'titre': titre,
        'items': items.map((e) => e.toJson()).toList(),
        'mainOeuvrePercent': mainOeuvrePercent,
        'mainOeuvre': mainOeuvre,
      };

  factory SectionDevis.fromJson(Map<String, dynamic> json) {
    final percent = (json['mainOeuvrePercent'] as num?)?.toDouble() ?? 0;
    final fixed = (json['mainOeuvre'] as num?)?.toDouble() ?? 0;
    return SectionDevis(
      titre: json['titre'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => DevisItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      mainOeuvrePercent: percent,
      mainOeuvreFixed: percent > 0 ? 0 : fixed,
    );
  }
}
