import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/database/hive_storage.dart';
import 'core/controllers/designation_controller.dart';
import 'core/controllers/devis_controller.dart';
import 'core/controllers/company_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_routes.dart';
import 'screens/dashboard_screen.dart';
import 'screens/choose_category_screen.dart';
import 'screens/categories_screen.dart';
import 'core/bindings/create_devis_binding.dart';
import 'screens/create_devis_screen.dart';
import 'screens/history_screen.dart';
import 'screens/designations_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.init();

  Get.put(DesignationController());
  Get.put(DevisController());
  Get.put(CompanyController());

  runApp(const NgDevisApp());
}


class NgDevisApp extends StatelessWidget {
  const NgDevisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'NG Devis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.dashboard,
      getPages: [
        GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen()),
        GetPage(name: AppRoutes.chooseCategory, page: () => const ChooseCategoryScreen()),
        GetPage(name: AppRoutes.categories, page: () => const CategoriesScreen()),
        GetPage(name: AppRoutes.categoryDesignations, page: () => const CategoryDesignationsScreen()),
        GetPage(
          name: AppRoutes.createDevis,
          page: () => const CreateDevisScreen(),
          binding: CreateDevisBinding(),
        ),
        GetPage(name: AppRoutes.history, page: () => const HistoryScreen()),
        GetPage(name: AppRoutes.designations, page: () => const DesignationsScreen()),
        GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
      ],
    );
  }
}
