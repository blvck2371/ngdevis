import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../database/hive_storage.dart';
import '../models/client.dart';
import '../models/devis.dart';
import '../models/devis_item.dart';
import '../models/devis_status.dart';
import '../models/facture.dart';
import '../models/section_devis.dart';
import '../services/cover/cover_template.dart';
import '../services/numbering_service.dart';
import '../services/pdf_service.dart';
import 'facture_controller.dart';

class DevisController extends GetxController {
  final list = <Devis>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void load() {
    final all = HiveStorage.getDevisList();
    _autoExpireOutdated(all);
    list.assignAll(all);
  }

  /// Bascule en statut `expire` les devis dont la validité est dépassée,
  /// **sauf** ceux déjà acceptés / refusés / convertis (états terminaux).
  void _autoExpireOutdated(List<Devis> all) {
    var changed = false;
    for (final d in all) {
      if (d.isOverdue && d.status != DevisStatus.expire) {
        d.status = DevisStatus.expire;
        changed = true;
      }
    }
    if (changed) {
      HiveStorage.saveDevisList(all);
    }
  }

  Devis? getById(String id) => HiveStorage.getDevisById(id);

  /// **Prévisualisation pro** : numéro affiché dans les réglages
  /// (format DEV-2026-0001). Ne consomme pas le compteur.
  String previewNextNumeroPro() =>
      NumberingService.preview(NumberingService.devisType);

  /// Réserve définitivement un nouveau numéro au format pro et avance le
  /// compteur. Utiliser au moment d'enregistrer un devis qui doit suivre le
  /// nouveau schéma de numérotation.
  Future<String> commitNextNumeroPro() =>
      NumberingService.commit(NumberingService.devisType);

  /// **API historique (sync)** : prochain numéro 4-chiffres (`0001`).
  /// Conservée pour ne rien casser dans `create_devis_controller`.
  /// Les nouveaux flows peuvent utiliser [previewNextNumeroPro] /
  /// [commitNextNumeroPro] pour passer au format DEV-2026-0001.
  String nextNumero() {
    final n = HiveStorage.getLastDevisNumber() + 1;
    return n.toString().padLeft(4, '0');
  }

  Future<void> saveDevis(Devis devis) async {
    final existing = HiveStorage.getDevisList().any((e) => e.id == devis.id);
    if (existing) {
      await HiveStorage.updateDevis(devis.id, devis);
    } else {
      // Synchronise le compteur legacy pour ne pas casser les anciens écrans.
      final num = int.tryParse(devis.numero.replaceAll(RegExp(r'\D'), '')) ?? 0;
      if (num > 0) {
        final current = HiveStorage.getLastDevisNumber();
        if (num > current) await HiveStorage.setLastDevisNumber(num);
      }
      await HiveStorage.addDevis(devis);
    }
    load();
  }

  Future<void> duplicateDevis(Devis devis) async {
    final copy = Devis(
      id: const Uuid().v4(),
      numero: nextNumero(),
      date: DateTime.now(),
      client: devis.client != null
          ? Client(
              id: const Uuid().v4(),
              nom: devis.client!.nom,
              societe: devis.client!.societe,
              telephone: devis.client!.telephone,
              adresse: devis.client!.adresse,
              email: devis.client!.email,
            )
          : null,
      sections: devis.sections
          .map((s) => SectionDevis(
                titre: s.titre,
                items: s.items
                    .map((i) => DevisItem(
                          designation: i.designation,
                          quantite: i.quantite,
                          prixUnitaire: i.prixUnitaire,
                          designationId: i.designationId,
                          unite: i.unite,
                        ))
                    .toList(),
                mainOeuvrePercent: s.mainOeuvrePercent,
                mainOeuvreFixed: s.mainOeuvreFixed,
              ))
          .toList(),
      titreDevis: devis.titreDevis,
      noteNb: devis.noteNb,
      logoPath: devis.logoPath,
      nomEntreprise: devis.nomEntreprise,
      telEntreprise: devis.telEntreprise,
      adresseEntreprise: devis.adresseEntreprise,
      useManualMainOeuvre: devis.useManualMainOeuvre,
      manualMainOeuvre: devis.manualMainOeuvre,
      // Le duplicata repart en brouillon — c'est un nouveau cycle commercial.
      status: DevisStatus.brouillon,
    );
    await saveDevis(copy);
  }

  Future<void> deleteDevis(String id) async {
    await HiveStorage.removeDevis(id);
    load();
  }

  // ——— Transitions de statut —————————————————————————————————————————

  Future<void> markSent(String id) async {
    final d = HiveStorage.getDevisById(id);
    if (d == null) return;
    d.status = DevisStatus.envoye;
    d.sentAt ??= DateTime.now();
    await HiveStorage.updateDevis(id, d);
    load();
  }

  Future<void> markAccepted(String id) async {
    final d = HiveStorage.getDevisById(id);
    if (d == null) return;
    d.status = DevisStatus.accepte;
    d.acceptedAt ??= DateTime.now();
    await HiveStorage.updateDevis(id, d);
    load();
  }

  Future<void> markRefused(String id) async {
    final d = HiveStorage.getDevisById(id);
    if (d == null) return;
    d.status = DevisStatus.refuse;
    d.refusedAt ??= DateTime.now();
    await HiveStorage.updateDevis(id, d);
    load();
  }

  Future<void> setStatus(String id, DevisStatus status) async {
    switch (status) {
      case DevisStatus.envoye:
        return markSent(id);
      case DevisStatus.accepte:
        return markAccepted(id);
      case DevisStatus.refuse:
        return markRefused(id);
      case DevisStatus.brouillon:
        final d = HiveStorage.getDevisById(id);
        if (d == null) return;
        d.status = DevisStatus.brouillon;
        await HiveStorage.updateDevis(id, d);
        load();
        break;
      case DevisStatus.expire:
        final d = HiveStorage.getDevisById(id);
        if (d == null) return;
        d.status = DevisStatus.expire;
        await HiveStorage.updateDevis(id, d);
        load();
        break;
      case DevisStatus.converti:
        // Ne pas forcer manuellement : utiliser convertToFacture.
        break;
    }
  }

  /// **Conversion Devis → Facture**.
  ///
  /// - Crée une nouvelle facture en **brouillon** avec snapshot du contenu.
  /// - Pose `devisSourceId` sur la facture, `convertedFactureId` sur le devis.
  /// - Marque le devis comme `converti`.
  /// - Retourne la facture créée pour permettre une navigation immédiate.
  Future<Facture> convertToFacture(
    String devisId, {
    DateTime? dueDate,
    String paymentTerms = '',
  }) async {
    final d = HiveStorage.getDevisById(devisId);
    if (d == null) {
      throw StateError('Devis introuvable : $devisId');
    }
    final factureCtrl = Get.find<FactureController>();
    final numero = await factureCtrl.nextNumero();

    final facture = Facture(
      id: const Uuid().v4(),
      numero: numero,
      date: DateTime.now(),
      client: d.client != null
          ? Client(
              id: const Uuid().v4(),
              nom: d.client!.nom,
              societe: d.client!.societe,
              telephone: d.client!.telephone,
              adresse: d.client!.adresse,
              email: d.client!.email,
            )
          : null,
      sections: d.sections
          .map((s) => SectionDevis(
                titre: s.titre,
                items: s.items
                    .map((i) => DevisItem(
                          designation: i.designation,
                          quantite: i.quantite,
                          prixUnitaire: i.prixUnitaire,
                          designationId: i.designationId,
                          unite: i.unite,
                        ))
                    .toList(),
                mainOeuvrePercent: s.mainOeuvrePercent,
                mainOeuvreFixed: s.mainOeuvreFixed,
              ))
          .toList(),
      titreFacture: d.titreDevis,
      noteNb: d.noteNb,
      logoPath: d.logoPath,
      nomEntreprise: d.nomEntreprise,
      telEntreprise: d.telEntreprise,
      adresseEntreprise: d.adresseEntreprise,
      useManualMainOeuvre: d.useManualMainOeuvre,
      manualMainOeuvre: d.manualMainOeuvre,
      devisSourceId: d.id,
      dueDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
      paymentTerms: paymentTerms,
    );
    await factureCtrl.saveFacture(facture);

    // Mise à jour du devis source : verrouillage en "converti".
    d.status = DevisStatus.converti;
    d.convertedAt = DateTime.now();
    d.convertedFactureId = facture.id;
    await HiveStorage.updateDevis(d.id, d);
    load();

    return facture;
  }

  // ——— PDF ——————————————————————————————————————————————————————————

  /// Aperçu PDF avec le template de couverture demandé.
  /// Par défaut → modèle classique (rétrocompat des appelants existants).
  Future<void> previewPdf(
    Devis devis, {
    CoverTemplate template = CoverTemplate.classic,
  }) =>
      PdfService.preview(devis, template: template);

  /// Partage le PDF (avec couverture choisie) et enregistre le devis dans
  /// l'historique s'il n'y est pas déjà.
  Future<void> sharePdf(
    Devis devis, {
    CoverTemplate template = CoverTemplate.classic,
  }) async {
    await saveDevis(devis);
    await PdfService.share(devis, template: template);
  }
}
