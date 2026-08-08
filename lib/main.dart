import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/database/hive_storage.dart';
import 'core/controllers/designation_controller.dart';
import 'core/controllers/devis_controller.dart';
import 'core/controllers/company_controller.dart';
import 'core/controllers/facture_controller.dart';
import 'core/controllers/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_currency.dart';
import 'core/utils/app_routes.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/choose_category_screen.dart';
import 'screens/devis_client_prep_screen.dart';
import 'screens/categories_screen.dart';
import 'core/bindings/create_devis_binding.dart';
import 'screens/create_devis_screen.dart';
import 'screens/history_screen.dart';
import 'screens/facture_detail_screen.dart';
import 'screens/designations_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/numbering_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.init();

  // **Edge-to-edge** : le contenu s'étend sous la status bar et la barre de
  // navigation système. Sans ça, on voit des bandes blanches/grises en haut
  // et en bas qui cassent l'esthétique premium (et donnent l'impression que
  // le splash n'occupe qu'une moitié d'écran sur Android).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
      statusBarBrightness: Brightness.dark,
    ),
  );

  Get.put(ThemeController());
  Get.put(CurrencyController());
  Get.put(DesignationController());
  // ⚠️ ORDRE IMPORTANT : FactureController doit exister AVANT DevisController
  // car `DevisController.convertToFacture` fait un `Get.find<FactureController>()`.
  Get.put(FactureController());
  Get.put(DevisController());
  Get.put(CompanyController());

  runApp(const NgDevisApp());
}

class NgDevisApp extends StatelessWidget {
  const NgDevisApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        title: 'NG Devis',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeCtrl.mode.value,
        initialRoute: AppRoutes.splash,
        defaultTransition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 320),
        getPages: [
          GetPage(name: AppRoutes.splash, page: () => const SplashScreen(), transition: Transition.fadeIn),
          GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen(), transition: Transition.fadeIn),
          GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen(), transition: Transition.fadeIn),
          GetPage(name: AppRoutes.chooseCategory, page: () => const ChooseCategoryScreen()),
          GetPage(name: AppRoutes.devisClientPrep, page: () => const DevisClientPrepScreen()),
          GetPage(name: AppRoutes.categories, page: () => const CategoriesScreen()),
          GetPage(name: AppRoutes.categoryDesignations, page: () => const CategoryDesignationsScreen()),
          GetPage(
            name: AppRoutes.createDevis,
            page: () => const CreateDevisScreen(),
            binding: CreateDevisBinding(),
          ),
          GetPage(name: AppRoutes.history, page: () => const HistoryScreen()),
          GetPage(name: AppRoutes.factureDetail, page: () => const FactureDetailScreen()),
          GetPage(name: AppRoutes.designations, page: () => const DesignationsScreen()),
          GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
          GetPage(name: AppRoutes.numbering, page: () => const NumberingSettingsScreen()),
        ],
      ),
    );
  }
}
