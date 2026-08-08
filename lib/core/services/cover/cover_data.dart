import '../../database/hive_storage.dart';
import '../../models/devis.dart';

/// Données nécessaires pour rendre n'importe quelle couverture.
class CoverData {
  final String documentLabel;
  final String numero;
  final DateTime date;
  final String? titre;

  final String clientNom;
  final String clientSociete;
  final String clientAdresse;
  final String clientTel;
  final String clientEmail;

  final String companyName;
  final String companyTel;
  final String companyAdresse;
  final String companyEmail;
  final String companyWebsite;
  final String companySlogan;
  final String? noteNb;

  const CoverData({
    required this.documentLabel,
    required this.numero,
    required this.date,
    this.titre,
    this.noteNb,
    this.clientNom = '',
    this.clientSociete = '',
    this.clientAdresse = '',
    this.clientTel = '',
    this.clientEmail = '',
    this.companyName = '',
    this.companyTel = '',
    this.companyAdresse = '',
    this.companyEmail = '',
    this.companyWebsite = '',
    this.companySlogan = '',
  });

  factory CoverData.fromDevis(Devis devis) {
    String company = (devis.nomEntreprise ?? '').trim();
    if (company.isEmpty) {
      company = (HiveStorage.getCompanySettings()['nom'] ?? '').trim();
    }
    String tel = (devis.telEntreprise ?? '').trim();
    if (tel.isEmpty) {
      tel = (HiveStorage.getCompanySettings()['telephone'] ?? '').trim();
    }
    String adresse = (devis.adresseEntreprise ?? '').trim();
    if (adresse.isEmpty) {
      adresse = (HiveStorage.getCompanySettings()['adresse'] ?? '').trim();
    }
    final settings = HiveStorage.getCompanySettings();
    return CoverData(
      documentLabel: 'DEVIS',
      numero: devis.numero,
      date: devis.date,
      titre: (devis.titreDevis ?? '').trim().isEmpty
          ? null
          : devis.titreDevis!.trim(),
      clientNom: (devis.client?.nom ?? '').trim(),
      clientSociete: (devis.client?.societe ?? '').trim(),
      clientAdresse: (devis.client?.adresse ?? '').trim(),
      clientTel: (devis.client?.telephone ?? '').trim(),
      clientEmail: (devis.client?.email ?? '').trim(),
      companyName: company,
      companyTel: tel,
      companyAdresse: adresse,
      companyEmail: (settings['email'] ?? '').trim(),
      companyWebsite:
          ((settings['site'] ?? '').toString().trim().isNotEmpty
                  ? settings['site']
                  : settings['siteweb'] ?? '')
              .toString()
              .trim(),
      companySlogan: (settings['slogan'] ?? '').toString().trim(),
      noteNb: (devis.noteNb ?? '').trim().isEmpty ? null : devis.noteNb!.trim(),
    );
  }
}
