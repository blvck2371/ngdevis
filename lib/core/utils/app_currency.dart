import 'package:get/get.dart';

import '../database/hive_storage.dart';

/// Devises supportées dans toute l'application (UI + PDF).
enum AppCurrencyCode {
  fcfa,
  usd,
  eur;

  String get code {
    switch (this) {
      case AppCurrencyCode.fcfa:
        return 'FCFA';
      case AppCurrencyCode.usd:
        return 'USD';
      case AppCurrencyCode.eur:
        return 'EUR';
    }
  }

  /// Libellé court affiché dans l'UI.
  String get label {
    switch (this) {
      case AppCurrencyCode.fcfa:
        return 'FCFA';
      case AppCurrencyCode.usd:
        return '\$';
      case AppCurrencyCode.eur:
        return '€';
    }
  }

  /// Libellé sûr pour Helvetica PDF (Latin-1) : pas de symbole €.
  String get pdfLabel {
    switch (this) {
      case AppCurrencyCode.fcfa:
        return 'FCFA';
      case AppCurrencyCode.usd:
        return 'USD';
      case AppCurrencyCode.eur:
        return 'EUR';
    }
  }

  String get fullName {
    switch (this) {
      case AppCurrencyCode.fcfa:
        return 'Franc CFA (FCFA)';
      case AppCurrencyCode.usd:
        return 'Dollar américain (\$)';
      case AppCurrencyCode.eur:
        return 'Euro (€)';
    }
  }

  static AppCurrencyCode fromStorage(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'USD':
      case '\$':
      case 'DOLLAR':
        return AppCurrencyCode.usd;
      case 'EUR':
      case 'EURO':
      case '€':
        return AppCurrencyCode.eur;
      case 'FCFA':
      case 'XAF':
      case 'XOF':
      default:
        return AppCurrencyCode.fcfa;
    }
  }
}

/// Accès centralisé à la devise courante (persistée Hive).
abstract final class AppCurrency {
  static AppCurrencyCode load() =>
      AppCurrencyCode.fromStorage(HiveStorage.getCurrencyCode());

  static Future<void> save(AppCurrencyCode code) =>
      HiveStorage.setCurrencyCode(code.code);

  static String get label {
    if (Get.isRegistered<CurrencyController>()) {
      return Get.find<CurrencyController>().label;
    }
    return load().label;
  }

  static String get pdfLabel {
    if (Get.isRegistered<CurrencyController>()) {
      return Get.find<CurrencyController>().pdfLabel;
    }
    return load().pdfLabel;
  }
}

/// Contrôleur GetX : changement de devise réactif dans toute l'app.
class CurrencyController extends GetxController {
  final code = AppCurrencyCode.fcfa.obs;

  @override
  void onInit() {
    code.value = AppCurrency.load();
    super.onInit();
  }

  String get label => code.value.label;
  String get pdfLabel => code.value.pdfLabel;

  Future<void> setCurrency(AppCurrencyCode next) async {
    if (code.value == next) return;
    code.value = next;
    await AppCurrency.save(next);
    // Force le rebuild des écrans qui lisent [kCurrencyLabel] hors Obx.
    Get.forceAppUpdate();
  }
}

/// Rétrocompatibilité : tous les `$kCurrencyLabel` existants suivent la devise choisie.
String get kCurrencyLabel => AppCurrency.label;

/// Devise pour les PDF / contrats (Helvetica-safe).
String get kCurrencyPdfLabel => AppCurrency.pdfLabel;
