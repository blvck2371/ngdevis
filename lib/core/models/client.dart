class Client {
  String id;
  String nom;
  /// Raison sociale ou société du client (optionnel).
  String societe;
  String telephone;
  String adresse;
  String email;

  Client({
    required this.id,
    required this.nom,
    this.societe = '',
    required this.telephone,
    required this.adresse,
    this.email = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'societe': societe,
        'telephone': telephone,
        'adresse': adresse,
        'email': email,
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] as String,
        nom: json['nom'] as String,
        societe: json['societe'] as String? ?? '',
        telephone: json['telephone'] as String,
        adresse: json['adresse'] as String,
        email: json['email'] as String? ?? '',
      );
}
