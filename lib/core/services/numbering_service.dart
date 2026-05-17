import '../database/hive_storage.dart';

/// Service centralisé pour générer les **numéros pro** des devis et factures.
///
/// Format par défaut : `DEV-2026-0001` / `FAC-2026-0001`.
///
/// L'utilisateur peut configurer dans les réglages :
///   - le **préfixe** (`DEV-` / `FAC-`) ;
///   - l'inclusion de l'**année** ;
///   - le **reset annuel** (compteur remis à zéro chaque 1er janvier).
class NumberingService {
  NumberingService._();

  /// Type de document numéroté.
  static const String devisType = 'devis';
  static const String factureType = 'facture';

  /// Calcule le prochain numéro pour un type de document.
  /// Ne touche pas au compteur (purement lecture). Le compteur est avancé
  /// par [commit] une fois le document réellement enregistré.
  static String preview(String type) {
    final cfg = HiveStorage.getNumberingConfig();
    final now = DateTime.now();
    final year = now.year;

    // Gestion du reset annuel : si l'année courante diffère de l'année stockée
    // pour ce type, on repart à 1.
    final storedYear = HiveStorage.getNumberingLastYear(type);
    final shouldReset = cfg.resetAnnual && storedYear != null && storedYear != year;
    final lastCount = shouldReset ? 0 : HiveStorage.getNumberingLastCount(type);
    final nextCount = lastCount + 1;

    return _format(
      prefix: type == factureType ? cfg.facturePrefix : cfg.devisPrefix,
      includeYear: cfg.includeYear,
      year: year,
      count: nextCount,
      pad: cfg.padding,
    );
  }

  /// Réserve / consomme le prochain numéro et le persiste. À appeler **après**
  /// que le document a été sauvegardé.
  static Future<String> commit(String type) async {
    final cfg = HiveStorage.getNumberingConfig();
    final now = DateTime.now();
    final year = now.year;

    final storedYear = HiveStorage.getNumberingLastYear(type);
    final shouldReset = cfg.resetAnnual && storedYear != null && storedYear != year;
    final lastCount = shouldReset ? 0 : HiveStorage.getNumberingLastCount(type);
    final nextCount = lastCount + 1;

    final number = _format(
      prefix: type == factureType ? cfg.facturePrefix : cfg.devisPrefix,
      includeYear: cfg.includeYear,
      year: year,
      count: nextCount,
      pad: cfg.padding,
    );

    await HiveStorage.setNumberingLastCount(type, nextCount);
    await HiveStorage.setNumberingLastYear(type, year);
    return number;
  }

  static String _format({
    required String prefix,
    required bool includeYear,
    required int year,
    required int count,
    required int pad,
  }) {
    final paddedCount = count.toString().padLeft(pad.clamp(2, 8), '0');
    final yearPart = includeYear ? '$year-' : '';
    final cleanPrefix = prefix.trim();
    if (cleanPrefix.isEmpty) return '$yearPart$paddedCount';
    final sep = cleanPrefix.endsWith('-') ? '' : '-';
    return '$cleanPrefix$sep$yearPart$paddedCount';
  }
}

/// Configuration sérialisable de la numérotation.
class NumberingConfig {
  final String devisPrefix;
  final String facturePrefix;
  final bool includeYear;
  final bool resetAnnual;
  final int padding;

  const NumberingConfig({
    this.devisPrefix = 'DEV',
    this.facturePrefix = 'FAC',
    this.includeYear = true,
    this.resetAnnual = true,
    this.padding = 4,
  });

  NumberingConfig copyWith({
    String? devisPrefix,
    String? facturePrefix,
    bool? includeYear,
    bool? resetAnnual,
    int? padding,
  }) =>
      NumberingConfig(
        devisPrefix: devisPrefix ?? this.devisPrefix,
        facturePrefix: facturePrefix ?? this.facturePrefix,
        includeYear: includeYear ?? this.includeYear,
        resetAnnual: resetAnnual ?? this.resetAnnual,
        padding: padding ?? this.padding,
      );

  Map<String, dynamic> toJson() => {
        'devisPrefix': devisPrefix,
        'facturePrefix': facturePrefix,
        'includeYear': includeYear,
        'resetAnnual': resetAnnual,
        'padding': padding,
      };

  factory NumberingConfig.fromJson(Map<String, dynamic> json) => NumberingConfig(
        devisPrefix: (json['devisPrefix'] as String?) ?? 'DEV',
        facturePrefix: (json['facturePrefix'] as String?) ?? 'FAC',
        includeYear: json['includeYear'] as bool? ?? true,
        resetAnnual: json['resetAnnual'] as bool? ?? true,
        padding: (json['padding'] as num?)?.toInt() ?? 4,
      );
}
