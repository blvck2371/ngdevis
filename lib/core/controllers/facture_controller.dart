import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../database/hive_storage.dart';
import '../models/facture.dart';
import '../models/facture_status.dart';
import '../models/payment.dart';
import '../services/facture_pdf_service.dart';
import '../services/numbering_service.dart';

/// Contrôleur GetX des factures : CRUD, paiements, transitions de statut.
class FactureController extends GetxController {
  final list = <Facture>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void load() {
    final all = HiveStorage.getFactureList();
    _autoFlagOverdue(all);
    list.assignAll(all);
  }

  /// Marque automatiquement en `enRetard` les factures dont la dueDate est
  /// dépassée et qui restent dues.
  void _autoFlagOverdue(List<Facture> all) {
    var changed = false;
    for (final f in all) {
      if (f.isOverdue && f.status != FactureStatus.enRetard) {
        f.status = FactureStatus.enRetard;
        changed = true;
      }
    }
    if (changed) {
      HiveStorage.saveFactureList(all);
    }
  }

  Facture? getById(String id) => HiveStorage.getFactureById(id);

  /// Prévisualise le prochain numéro sans le consommer.
  String previewNextNumero() => NumberingService.preview(NumberingService.factureType);

  /// Réserve et persiste le prochain numéro de facture.
  Future<String> nextNumero() =>
      NumberingService.commit(NumberingService.factureType);

  /// Enregistre une facture (création ou mise à jour) avec recalcul du statut.
  Future<void> saveFacture(Facture f) async {
    _recomputeStatus(f);
    final existing = HiveStorage.getFactureList().any((e) => e.id == f.id);
    if (existing) {
      await HiveStorage.updateFacture(f.id, f);
    } else {
      await HiveStorage.addFacture(f);
    }
    load();
  }

  Future<void> deleteFacture(String id) async {
    await HiveStorage.removeFacture(id);
    load();
  }

  // ——— Transitions de statut —————————————————————————————————————————

  Future<void> markSent(String id) async {
    final f = HiveStorage.getFactureById(id);
    if (f == null) return;
    f.status = FactureStatus.envoyee;
    f.sentAt ??= DateTime.now();
    await HiveStorage.updateFacture(id, f);
    load();
  }

  Future<void> markCancelled(String id) async {
    final f = HiveStorage.getFactureById(id);
    if (f == null) return;
    f.status = FactureStatus.annulee;
    await HiveStorage.updateFacture(id, f);
    load();
  }

  /// Marque comme entièrement payée (crée un paiement complémentaire si besoin).
  Future<void> markFullyPaid(
    String id, {
    PaymentMethod method = PaymentMethod.especes,
    String reference = '',
  }) async {
    final f = HiveStorage.getFactureById(id);
    if (f == null) return;
    final missing = f.remaining;
    if (missing > 0.0001) {
      f.payments.add(Payment(
        id: const Uuid().v4(),
        date: DateTime.now(),
        amount: missing,
        method: method,
        reference: reference,
      ));
    }
    f.status = FactureStatus.payee;
    f.paidAt = DateTime.now();
    await HiveStorage.updateFacture(id, f);
    load();
  }

  // ——— Paiements ——————————————————————————————————————————————————————

  Future<void> addPayment(String factureId, Payment payment) async {
    final f = HiveStorage.getFactureById(factureId);
    if (f == null) return;
    f.payments.add(payment);
    _recomputeStatus(f);
    await HiveStorage.updateFacture(factureId, f);
    load();
  }

  Future<void> removePayment(String factureId, String paymentId) async {
    final f = HiveStorage.getFactureById(factureId);
    if (f == null) return;
    f.payments.removeWhere((p) => p.id == paymentId);
    _recomputeStatus(f);
    await HiveStorage.updateFacture(factureId, f);
    load();
  }

  /// Recalcule le statut en fonction des paiements et de la due date.
  void _recomputeStatus(Facture f) {
    if (f.status == FactureStatus.annulee) return;
    if (f.totalPaid >= f.total - 0.0001 && f.total > 0) {
      f.status = FactureStatus.payee;
      f.paidAt ??= DateTime.now();
      return;
    }
    if (f.totalPaid > 0) {
      f.status = FactureStatus.partiellementPayee;
      return;
    }
    // Pas encore de paiement
    if (f.isOverdue) {
      f.status = FactureStatus.enRetard;
      return;
    }
    if (f.status == FactureStatus.brouillon) return;
    f.status = FactureStatus.envoyee;
  }

  // ——— PDF ——————————————————————————————————————————————————————————

  Future<void> previewPdf(Facture f) => FacturePdfService.preview(f);
  Future<void> sharePdf(Facture f) async {
    await saveFacture(f);
    await FacturePdfService.share(f);
  }

  // ——— Agrégats / stats ————————————————————————————————————————————

  /// Restant dû total (toutes factures non payées / non annulées).
  double get totalOutstanding =>
      list.where((f) => f.status.isOpen).fold(0.0, (s, f) => s + f.remaining);

  /// Total encaissé sur l'année courante.
  double get totalCollectedThisYear {
    final now = DateTime.now();
    return list.fold(0.0, (s, f) {
      final paid = f.payments
          .where((p) => p.date.year == now.year)
          .fold(0.0, (a, p) => a + p.amount);
      return s + paid;
    });
  }

  /// Nombre de factures en retard.
  int get overdueCount =>
      list.where((f) => f.status == FactureStatus.enRetard).length;
}
