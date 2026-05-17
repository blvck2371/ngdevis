import 'package:flutter/material.dart';

/// Mode de paiement supporté.
enum PaymentMethod {
  especes,
  mobileMoney,
  virement,
  cheque,
  carte,
  autre,
}

extension PaymentMethodX on PaymentMethod {
  String get code {
    switch (this) {
      case PaymentMethod.especes:
        return 'especes';
      case PaymentMethod.mobileMoney:
        return 'mobile_money';
      case PaymentMethod.virement:
        return 'virement';
      case PaymentMethod.cheque:
        return 'cheque';
      case PaymentMethod.carte:
        return 'carte';
      case PaymentMethod.autre:
        return 'autre';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.especes:
        return 'Espèces';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.virement:
        return 'Virement';
      case PaymentMethod.cheque:
        return 'Chèque';
      case PaymentMethod.carte:
        return 'Carte';
      case PaymentMethod.autre:
        return 'Autre';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.especes:
        return Icons.payments_rounded;
      case PaymentMethod.mobileMoney:
        return Icons.phone_android_rounded;
      case PaymentMethod.virement:
        return Icons.account_balance_rounded;
      case PaymentMethod.cheque:
        return Icons.assignment_rounded;
      case PaymentMethod.carte:
        return Icons.credit_card_rounded;
      case PaymentMethod.autre:
        return Icons.more_horiz_rounded;
    }
  }
}

PaymentMethod paymentMethodFromCode(String? code) {
  switch (code) {
    case 'mobile_money':
      return PaymentMethod.mobileMoney;
    case 'virement':
      return PaymentMethod.virement;
    case 'cheque':
      return PaymentMethod.cheque;
    case 'carte':
      return PaymentMethod.carte;
    case 'autre':
      return PaymentMethod.autre;
    case 'especes':
    default:
      return PaymentMethod.especes;
  }
}

/// Un encaissement enregistré sur une facture (peut être partiel).
class Payment {
  String id;
  DateTime date;
  double amount;
  PaymentMethod method;

  /// Référence externe (n° transaction Mobile Money, n° de chèque, etc.).
  String reference;

  /// Note libre.
  String note;

  Payment({
    required this.id,
    required this.date,
    required this.amount,
    this.method = PaymentMethod.especes,
    this.reference = '',
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'method': method.code,
        'reference': reference,
        'note': note,
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num).toDouble(),
        method: paymentMethodFromCode(json['method'] as String?),
        reference: (json['reference'] as String?) ?? '',
        note: (json['note'] as String?) ?? '',
      );
}
