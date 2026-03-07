class Client {
  String id;
  String nom;
  String telephone;
  String adresse;

  Client({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.adresse,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'telephone': telephone,
        'adresse': adresse,
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] as String,
        nom: json['nom'] as String,
        telephone: json['telephone'] as String,
        adresse: json['adresse'] as String,
      );
}
