import 'package:atom/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  ThemeController({ThemeMode initialMode = ThemeMode.system}) {
    mode = initialMode.obs;
  }

  static ThemeController get to => Get.find();

  late final Rx<ThemeMode> mode;

  Future<void> setMode(ThemeMode newMode) async {
    mode.value = newMode;
    Get.changeThemeMode(newMode);
    await StorageService.setThemeMode(_toString(newMode));
  }

  static ThemeMode modeFromString(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      default:
        return 'system';
    }
  }
}
