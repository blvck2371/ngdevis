import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/devis.dart';
import '../models/client.dart';
import '../models/section_devis.dart';
import '../models/devis_item.dart';
import '../database/hive_storage.dart';
import '../services/pdf_service.dart';

class DevisController extends GetxController {
  final list = <Devis>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void load() {
    list.assignAll(HiveStorage.getDevisList());
  }

  Devis? getById(String id) => HiveStorage.getDevisById(id);

  /// Prochain numéro de devis (auto-incrémenté).
  String nextNumero() {
    final n = HiveStorage.getLastDevisNumber() + 1;
    return n.toString().padLeft(4, '0');
  }

  Future<void> saveDevis(Devis devis) async {
    final existing = HiveStorage.getDevisList().any((e) => e.id == devis.id);
    if (existing) {
      await HiveStorage.updateDevis(devis.id, devis);
    } else {
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
              telephone: devis.client!.telephone,
              adresse: devis.client!.adresse,
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
    );
    await saveDevis(copy);
  }

  Future<void> deleteDevis(String id) async {
    await HiveStorage.removeDevis(id);
    load();
  }

  Future<void> previewPdf(Devis devis) => PdfService.preview(devis);

  /// Partage le PDF et enregistre le devis dans l'historique s'il n'y est pas déjà.
  Future<void> sharePdf(Devis devis) async {
    await saveDevis(devis);
    await PdfService.share(devis);
  }
}
