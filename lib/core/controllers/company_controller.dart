import 'package:get/get.dart';
import '../database/hive_storage.dart';

class CompanyController extends GetxController {
  final nom = ''.obs;
  final telephone = ''.obs;
  final adresse = ''.obs;
  final logoPath = ''.obs;
  /// Ligne optionnelle sous le logo / nom sur le PDF (ex. slogan).
  final slogan = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void load() {
    final m = HiveStorage.getCompanySettings();
    nom.value = m['nom'] ?? '';
    telephone.value = m['telephone'] ?? '';
    adresse.value = m['adresse'] ?? '';
    logoPath.value = m['logoPath'] ?? '';
    slogan.value = m['slogan'] ?? '';
  }

  Future<void> save() async {
    await HiveStorage.saveCompanySettings({
      'nom': nom.value,
      'telephone': telephone.value,
      'adresse': adresse.value,
      'logoPath': logoPath.value,
      'slogan': slogan.value,
    });
  }

  void setLogo(String? path) {
    logoPath.value = path ?? '';
  }
}
