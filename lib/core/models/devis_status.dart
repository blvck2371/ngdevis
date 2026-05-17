import 'package:flutter/material.dart';

/// Cycle de vie d'un devis.
///
/// `brouillon` → `envoye` → (`accepte` | `refuse`) → `converti` (en facture)
/// `expire` est automatique si `validUntil` est dépassé.
enum DevisStatus {
  brouillon,
  envoye,
  accepte,
  refuse,
  expire,
  converti,
}

extension DevisStatusX on DevisStatus {
  String get code {
    switch (this) {
      case DevisStatus.brouillon:
        return 'brouillon';
      case DevisStatus.envoye:
        return 'envoye';
      case DevisStatus.accepte:
        return 'accepte';
      case DevisStatus.refuse:
        return 'refuse';
      case DevisStatus.expire:
        return 'expire';
      case DevisStatus.converti:
        return 'converti';
    }
  }

  /// Libellé affiché à l'utilisateur (FR, court).
  String get label {
    switch (this) {
      case DevisStatus.brouillon:
        return 'Brouillon';
      case DevisStatus.envoye:
        return 'Envoyé';
      case DevisStatus.accepte:
        return 'Accepté';
      case DevisStatus.refuse:
        return 'Refusé';
      case DevisStatus.expire:
        return 'Expiré';
      case DevisStatus.converti:
        return 'Facturé';
    }
  }

  /// Icône proposée pour l'UI.
  IconData get icon {
    switch (this) {
      case DevisStatus.brouillon:
        return Icons.edit_note_rounded;
      case DevisStatus.envoye:
        return Icons.send_rounded;
      case DevisStatus.accepte:
        return Icons.check_circle_rounded;
      case DevisStatus.refuse:
        return Icons.cancel_rounded;
      case DevisStatus.expire:
        return Icons.hourglass_disabled_rounded;
      case DevisStatus.converti:
        return Icons.receipt_long_rounded;
    }
  }

  /// Couleur de teinte pour les badges (palette neutre, déclinée par l'UI).
  /// On retourne un code symbolique consommé par le widget _StatusBadge :
  ///  - `neutral`, `accent`, `success`, `error`, `warning`, `gold`.
  String get toneCode {
    switch (this) {
      case DevisStatus.brouillon:
        return 'neutral';
      case DevisStatus.envoye:
        return 'accent';
      case DevisStatus.accepte:
        return 'success';
      case DevisStatus.refuse:
        return 'error';
      case DevisStatus.expire:
        return 'warning';
      case DevisStatus.converti:
        return 'gold';
    }
  }

  /// Vrai si l'utilisateur peut encore éditer librement le contenu du devis.
  /// On verrouille à partir de "Accepté" et au-delà pour préserver l'intégrité
  /// commerciale (sinon, dupliquer pour faire un avenant).
  bool get isEditable =>
      this == DevisStatus.brouillon || this == DevisStatus.envoye;

  /// Vrai si on peut convertir ce devis en facture.
  bool get canConvertToFacture =>
      this == DevisStatus.accepte || this == DevisStatus.envoye;
}

/// Parse stable depuis Hive (string → enum), tolère les valeurs inconnues.
DevisStatus devisStatusFromCode(String? code) {
  switch (code) {
    case 'envoye':
      return DevisStatus.envoye;
    case 'accepte':
      return DevisStatus.accepte;
    case 'refuse':
      return DevisStatus.refuse;
    case 'expire':
      return DevisStatus.expire;
    case 'converti':
      return DevisStatus.converti;
    case 'brouillon':
    default:
      return DevisStatus.brouillon;
  }
}
