import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../database/hive_storage.dart';

/// Contrôleur global de thème : permet de basculer entre système / clair / sombre
/// et persiste le choix en Hive (`HiveKeys.themeMode`).
class ThemeController extends GetxController {
  final Rx<ThemeMode> mode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    final stored = HiveStorage.getThemeMode();
    mode.value = _parse(stored);
  }

  Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    await HiveStorage.setThemeMode(_serialize(m));
    Get.changeThemeMode(m);
  }

  Future<void> cycle() async {
    final next = switch (mode.value) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setMode(next);
  }

  static ThemeMode _parse(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _serialize(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  /// Libellé court pour l'UI.
  String label() => switch (mode.value) {
        ThemeMode.light => 'Clair',
        ThemeMode.dark => 'Sombre',
        ThemeMode.system => 'Auto',
      };

  IconData icon() => switch (mode.value) {
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
        ThemeMode.system => Icons.auto_mode_rounded,
      };
}
