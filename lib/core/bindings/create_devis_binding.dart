import 'package:get/get.dart';
import '../controllers/create_devis_controller.dart';
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
      try {
        c.initForEdit(Devis.fromJson(Map<String, dynamic>.from(args)));
      } catch (_) {
        c.initForNew();
      }
    } else if (args is List<dynamic> && args.isNotEmpty) {
      final categories = args.map((e) => e.toString()).toList();
      c.initForNewWithCategories(categories);
    } else {
      c.initForNew();
    }
  }
}
