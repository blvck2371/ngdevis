import 'client.dart';
import 'devis_status.dart';
import 'section_devis.dart';

/// Modèle Devis — étendu en 2026 avec un cycle de vie commercial
/// (brouillon → envoyé → accepté/refusé → converti en facture).
///
/// Rétrocompatibilité : tous les nouveaux champs sont optionnels et ont une
/// valeur par défaut sûre dans [fromJson] — les anciens devis Hive sont lus
/// sans modification ni perte de données.
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
  List<Map<String, dynamic>> deletedHistory;
  bool useManualMainOeuvre;
  double manualMainOeuvre;

  // ——— Nouveau cycle de vie ———————————————————————————————————————————

  /// Statut courant du devis (brouillon par défaut).
  DevisStatus status;

  /// Date jusqu'à laquelle l'offre est valable. Si nulle → pas d'expiration.
  DateTime? validUntil;

  /// Horodatages de transition (consignés à titre d'audit / d'historique).
  DateTime? sentAt;
  DateTime? acceptedAt;
  DateTime? refusedAt;
  DateTime? convertedAt;

  /// Identifiant de la facture générée à partir de ce devis (si converti).
  String? convertedFactureId;

  /// Notes commerciales internes (privées, non imprimées sur le PDF).
  String? internalNotes;

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
    List<Map<String, dynamic>>? deletedHistory,
    this.useManualMainOeuvre = false,
    this.manualMainOeuvre = 0,
    this.status = DevisStatus.brouillon,
    this.validUntil,
    this.sentAt,
    this.acceptedAt,
    this.refusedAt,
    this.convertedAt,
    this.convertedFactureId,
    this.internalNotes,
  })  : sections = sections ?? [],
        deletedHistory = deletedHistory ?? [];

  double get total =>
      sections.fold(0.0, (sum, s) => sum + s.totalSection) +
      (useManualMainOeuvre ? manualMainOeuvre : 0);

  /// Vrai si le devis est dépassé (validUntil < aujourd'hui).
  /// Ne mute pas [status] (c'est le rôle du service d'expiration).
  bool get isOverdue {
    final v = validUntil;
    if (v == null) return false;
    final today = DateTime.now();
    final endOfDay = DateTime(v.year, v.month, v.day, 23, 59, 59);
    return endOfDay.isBefore(today) &&
        status != DevisStatus.accepte &&
        status != DevisStatus.converti &&
        status != DevisStatus.refuse;
  }

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
        'deletedHistory': deletedHistory,
        'useManualMainOeuvre': useManualMainOeuvre,
        'manualMainOeuvre': manualMainOeuvre,
        'status': status.code,
        'validUntil': validUntil?.toIso8601String(),
        'sentAt': sentAt?.toIso8601String(),
        'acceptedAt': acceptedAt?.toIso8601String(),
        'refusedAt': refusedAt?.toIso8601String(),
        'convertedAt': convertedAt?.toIso8601String(),
        'convertedFactureId': convertedFactureId,
        'internalNotes': internalNotes,
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
        deletedHistory: (json['deletedHistory'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        useManualMainOeuvre: json['useManualMainOeuvre'] as bool? ?? false,
        manualMainOeuvre: (json['manualMainOeuvre'] as num?)?.toDouble() ?? 0,
        status: devisStatusFromCode(json['status'] as String?),
        validUntil: _parseDate(json['validUntil']),
        sentAt: _parseDate(json['sentAt']),
        acceptedAt: _parseDate(json['acceptedAt']),
        refusedAt: _parseDate(json['refusedAt']),
        convertedAt: _parseDate(json['convertedAt']),
        convertedFactureId: json['convertedFactureId'] as String?,
        internalNotes: json['internalNotes'] as String?,
      );

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
