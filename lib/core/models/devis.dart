import 'client.dart';
import 'section_devis.dart';

class Devis {
  String id;
  String numero;
  DateTime date;
  Client? client;
  List<SectionDevis> sections;
  String? titreDevis;
  String? noteNb;
  String? logoPath;
  String? nomEntreprise;
  String? telEntreprise;
  String? adresseEntreprise;

  Devis({
    required this.id,
    required this.numero,
    required this.date,
    this.client,
    List<SectionDevis>? sections,
    this.titreDevis,
    this.noteNb,
    this.logoPath,
    this.nomEntreprise,
    this.telEntreprise,
    this.adresseEntreprise,
  }) : sections = sections ?? [];

  double get total =>
      sections.fold(0.0, (sum, s) => sum + s.totalSection);

  Map<String, dynamic> toJson() => {
        'id': id,
        'numero': numero,
        'date': date.toIso8601String(),
        'client': client?.toJson(),
        'sections': sections.map((e) => e.toJson()).toList(),
        'titreDevis': titreDevis,
        'noteNb': noteNb,
        'logoPath': logoPath,
        'nomEntreprise': nomEntreprise,
        'telEntreprise': telEntreprise,
        'adresseEntreprise': adresseEntreprise,
      };

  factory Devis.fromJson(Map<String, dynamic> json) => Devis(
        id: json['id'] as String,
        numero: json['numero'] as String,
        date: DateTime.parse(json['date'] as String),
        client: json['client'] != null
            ? Client.fromJson(Map<String, dynamic>.from(json['client'] as Map))
            : null,
        sections: (json['sections'] as List<dynamic>?)
                ?.map((e) => SectionDevis.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        titreDevis: json['titreDevis'] as String?,
        noteNb: json['noteNb'] as String?,
        logoPath: json['logoPath'] as String?,
        nomEntreprise: json['nomEntreprise'] as String?,
        telEntreprise: json['telEntreprise'] as String?,
        adresseEntreprise: json['adresseEntreprise'] as String?,
      );
}
