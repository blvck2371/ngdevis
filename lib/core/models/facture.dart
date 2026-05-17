import 'client.dart';
import 'facture_status.dart';
import 'payment.dart';
import 'section_devis.dart';

/// Modèle Facture — réutilise la structure d'un devis (sections + items) et
/// ajoute la couche **financière** (échéance, paiements, statut).
///
/// La facture peut être créée :
///   - depuis zéro (saisie manuelle) ;
///   - depuis un devis accepté (conversion via [Facture.fromDevisSnapshot]).
class Facture {
  String id;
  String numero;
  DateTime date;
  Client? client;
  List<SectionDevis> sections;
  String? titreFacture;
  String? noteNb;
  String? logoPath;
  String? nomEntreprise;
  String? telEntreprise;
  String? adresseEntreprise;
  bool useManualMainOeuvre;
  double manualMainOeuvre;

  /// Devis d'origine si la facture a été convertie depuis un devis.
  String? devisSourceId;

  /// Statut de paiement / cycle de vie.
  FactureStatus status;

  /// Date d'échéance (paiement attendu pour…).
  DateTime? dueDate;

  /// Acompte demandé à la création (montant indicatif, déduit du restant dû).
  double acompteDemande;

  /// Historique des encaissements.
  List<Payment> payments;

  /// Conditions de paiement (mentions imprimées).
  String paymentTerms;

  /// Notes internes (privées).
  String? internalNotes;

  DateTime? sentAt;
  DateTime? paidAt;

  Facture({
    required this.id,
    required this.numero,
    required this.date,
    this.client,
    List<SectionDevis>? sections,
    this.titreFacture,
    this.noteNb,
    this.logoPath,
    this.nomEntreprise,
    this.telEntreprise,
    this.adresseEntreprise,
    this.useManualMainOeuvre = false,
    this.manualMainOeuvre = 0,
    this.devisSourceId,
    this.status = FactureStatus.brouillon,
    this.dueDate,
    this.acompteDemande = 0,
    List<Payment>? payments,
    this.paymentTerms = '',
    this.internalNotes,
    this.sentAt,
    this.paidAt,
  })  : sections = sections ?? [],
        payments = payments ?? [];

  /// Total TTC de la facture (matériel + main d'œuvre).
  double get total =>
      sections.fold(0.0, (sum, s) => sum + s.totalSection) +
      (useManualMainOeuvre ? manualMainOeuvre : 0);

  /// Somme des paiements encaissés (espèces, virement, etc.).
  double get totalPaid => payments.fold(0.0, (s, p) => s + p.amount);

  /// Restant dû (jamais négatif).
  double get remaining {
    final r = total - totalPaid;
    return r < 0 ? 0 : r;
  }

  /// Pourcentage encaissé sur le total (0..1). Renvoie 0 si total nul.
  double get paidRatio {
    if (total <= 0) return 0;
    final r = totalPaid / total;
    if (r < 0) return 0;
    if (r > 1) return 1;
    return r;
  }

  /// Vrai si on dépasse la due date sans paiement complet.
  bool get isOverdue {
    final d = dueDate;
    if (d == null) return false;
    if (status == FactureStatus.payee || status == FactureStatus.annulee) {
      return false;
    }
    final endOfDay = DateTime(d.year, d.month, d.day, 23, 59, 59);
    return endOfDay.isBefore(DateTime.now()) && remaining > 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'numero': numero,
        'date': date.toIso8601String(),
        'client': client?.toJson(),
        'sections': sections.map((e) => e.toJson()).toList(),
        'titreFacture': titreFacture,
        'noteNb': noteNb,
        'logoPath': logoPath,
        'nomEntreprise': nomEntreprise,
        'telEntreprise': telEntreprise,
        'adresseEntreprise': adresseEntreprise,
        'useManualMainOeuvre': useManualMainOeuvre,
        'manualMainOeuvre': manualMainOeuvre,
        'devisSourceId': devisSourceId,
        'status': status.code,
        'dueDate': dueDate?.toIso8601String(),
        'acompteDemande': acompteDemande,
        'payments': payments.map((p) => p.toJson()).toList(),
        'paymentTerms': paymentTerms,
        'internalNotes': internalNotes,
        'sentAt': sentAt?.toIso8601String(),
        'paidAt': paidAt?.toIso8601String(),
      };

  factory Facture.fromJson(Map<String, dynamic> json) => Facture(
        id: json['id'] as String,
        numero: json['numero'] as String,
        date: DateTime.parse(json['date'] as String),
        client: json['client'] != null
            ? Client.fromJson(Map<String, dynamic>.from(json['client'] as Map))
            : null,
        sections: (json['sections'] as List<dynamic>?)
                ?.map((e) =>
                    SectionDevis.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        titreFacture: json['titreFacture'] as String?,
        noteNb: json['noteNb'] as String?,
        logoPath: json['logoPath'] as String?,
        nomEntreprise: json['nomEntreprise'] as String?,
        telEntreprise: json['telEntreprise'] as String?,
        adresseEntreprise: json['adresseEntreprise'] as String?,
        useManualMainOeuvre: json['useManualMainOeuvre'] as bool? ?? false,
        manualMainOeuvre: (json['manualMainOeuvre'] as num?)?.toDouble() ?? 0,
        devisSourceId: json['devisSourceId'] as String?,
        status: factureStatusFromCode(json['status'] as String?),
        dueDate: _parseDate(json['dueDate']),
        acompteDemande: (json['acompteDemande'] as num?)?.toDouble() ?? 0,
        payments: (json['payments'] as List<dynamic>?)
                ?.map((e) =>
                    Payment.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        paymentTerms: (json['paymentTerms'] as String?) ?? '',
        internalNotes: json['internalNotes'] as String?,
        sentAt: _parseDate(json['sentAt']),
        paidAt: _parseDate(json['paidAt']),
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
