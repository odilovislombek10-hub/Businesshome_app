import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/auth_service.dart';
import 'core/services/currency_service.dart';
import 'core/services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dekodlangan rasmlar xotirasi. Sukut bo'yicha 100 MB / 1000 ta rasm; ro'yxatni pastga surib
  // qaytganda kartalar keshdan chiqib ketib, rasm qaytadan dekodlanardi va bu "qaytadan
  // yuklanyapti" bo'lib ko'rinardi. Rasmlar `AppImage` da ekran o'lchamiga qarab dekodlanadi,
  // shuning uchun bu chegara bilan ancha ko'p karta xotirada saqlanadi.
  PaintingBinding.instance.imageCache
    ..maximumSizeBytes = 200 << 20
    ..maximumSize = 3000;

  // Read the stored light/dark choice before the first frame so the app never flashes the
  // wrong theme on launch.
  final themeController = ThemeController();
  await themeController.load();

  // Restoring the session is deliberately not awaited: it needs a network round trip, and the
  // catalogue is browsable signed-out. Screens that care listen to AuthService instead.
  final authService = AuthService();
  unawaited(authService.restore());

  // Currency preference and the USD rate — prices render in UZS until the rate arrives.
  unawaited(CurrencyService.instance.load());

  runApp(BusinessHomeApp(themeController: themeController, authService: authService));
}
