import 'package:flutter/material.dart';

/// Cycle de vie d'une facture.
///
/// `brouillon` → `envoyee` → (`partiellement_payee` → `payee`) | `en_retard`
/// `annulee` est un état terminal alternatif (geste commercial).
enum FactureStatus {
  brouillon,
  envoyee,
  partiellementPayee,
  payee,
  enRetard,
  annulee,
}

extension FactureStatusX on FactureStatus {
  String get code {
    switch (this) {
      case FactureStatus.brouillon:
        return 'brouillon';
      case FactureStatus.envoyee:
        return 'envoyee';
      case FactureStatus.partiellementPayee:
        return 'partiellement_payee';
      case FactureStatus.payee:
        return 'payee';
      case FactureStatus.enRetard:
        return 'en_retard';
      case FactureStatus.annulee:
        return 'annulee';
    }
  }

  String get label {
    switch (this) {
      case FactureStatus.brouillon:
        return 'Brouillon';
      case FactureStatus.envoyee:
        return 'Envoyée';
      case FactureStatus.partiellementPayee:
        return 'Partielle';
      case FactureStatus.payee:
        return 'Payée';
      case FactureStatus.enRetard:
        return 'En retard';
      case FactureStatus.annulee:
        return 'Annulée';
    }
  }

  IconData get icon {
    switch (this) {
      case FactureStatus.brouillon:
        return Icons.edit_note_rounded;
      case FactureStatus.envoyee:
        return Icons.send_rounded;
      case FactureStatus.partiellementPayee:
        return Icons.donut_small_rounded;
      case FactureStatus.payee:
        return Icons.verified_rounded;
      case FactureStatus.enRetard:
        return Icons.warning_amber_rounded;
      case FactureStatus.annulee:
        return Icons.block_rounded;
    }
  }

  /// Codes de teinte consommés par les badges UI :
  /// `neutral`, `accent`, `success`, `error`, `warning`, `gold`.
  String get toneCode {
    switch (this) {
      case FactureStatus.brouillon:
        return 'neutral';
      case FactureStatus.envoyee:
        return 'accent';
      case FactureStatus.partiellementPayee:
        return 'warning';
      case FactureStatus.payee:
        return 'success';
      case FactureStatus.enRetard:
        return 'error';
      case FactureStatus.annulee:
        return 'neutral';
    }
  }

  /// Vrai si on peut encore enregistrer un paiement (pas de paiement
  /// sur une facture annulée ou déjà soldée).
  bool get canRecordPayment =>
      this != FactureStatus.annulee && this != FactureStatus.payee;

  /// Vrai si la facture est dans un état "ouvert" comptablement (créance).
  bool get isOpen =>
      this == FactureStatus.envoyee ||
      this == FactureStatus.partiellementPayee ||
      this == FactureStatus.enRetard;
}

FactureStatus factureStatusFromCode(String? code) {
  switch (code) {
    case 'envoyee':
      return FactureStatus.envoyee;
    case 'partiellement_payee':
      return FactureStatus.partiellementPayee;
    case 'payee':
      return FactureStatus.payee;
    case 'en_retard':
      return FactureStatus.enRetard;
    case 'annulee':
      return FactureStatus.annulee;
    case 'brouillon':
    default:
      return FactureStatus.brouillon;
  }
}
