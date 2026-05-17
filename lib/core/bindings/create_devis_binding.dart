import 'package:get/get.dart';
import '../controllers/create_devis_controller.dart';
import '../controllers/devis_controller.dart';
import '../models/devis.dart';

/// Binding pour l'écran création/édition de devis.
/// Crée le CreateDevisController à l'entrée sur la route et l'initialise
/// selon les arguments : [Devis] ou Map (JSON) = édition, [List<String>] = nouvelles catégories, null = défaut.
class CreateDevisBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments;
    Get.put(CreateDevisController(), permanent: false);

    final c = Get.find<CreateDevisController>();
    if (args is Devis) {
      c.initForEdit(args);
    } else if (args is Map) {
      final m = Map<String, dynamic>.from(args);
      final devisId = m['devisId']?.toString();
      if (devisId != null && devisId.isNotEmpty) {
        final stored = Get.find<DevisController>().getById(devisId);
        if (stored != null) {
          c.initForEdit(stored);
          return;
        }
      }
      if (m['categories'] is List) {
        final cats = (m['categories'] as List).map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
        c.initForNewWithCategoriesAndClient(
          cats,
          clientNom: m['clientNom']?.toString() ?? '',
          clientSociete: m['clientSociete']?.toString() ?? '',
          clientTel: m['clientTel']?.toString() ?? '',
          clientAdresse: m['clientAdresse']?.toString() ?? '',
          clientEmail: m['clientEmail']?.toString() ?? '',
          asInvoice: m['asInvoice'] == true,
        );
      } else {
        try {
          c.initForEdit(Devis.fromJson(m));
        } catch (_) {
          c.initForNew();
        }
      }
    } else if (args is List<dynamic> && args.isNotEmpty) {
      final categories = args.map((e) => e.toString()).toList();
      c.initForNewWithCategories(categories);
    } else if (args is String && args.trim().isNotEmpty) {
      final stored = Get.find<DevisController>().getById(args.trim());
      if (stored != null) {
        c.initForEdit(stored);
      } else {
        c.initForNew();
      }
    } else {
      c.initForNew();
    }
  }
}
