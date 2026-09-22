import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:image_picker_android/image_picker_android.dart';

import 'app/app.dart';
import 'core/services/app_usage_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/currency_service.dart';
import 'core/services/language_service.dart';
import 'core/services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android 13+ dagi tizim "Photo Picker" — galereyaga to'liq ruxsat
  // (`READ_MEDIA_IMAGES`/`READ_MEDIA_VIDEO`) so'ramasdan rasm tanlash imkonini beradi.
  // Play'ning "Photo and Video Permissions" siyosati bo'yicha keng ruxsat so'ragan ilova
  // rad etiladi — bh_apps aynan shu sabab qaytarilgan edi. Bu faqat Android'ga tegishli,
  // iOS'da o'z tanlagichi ishlaydi.
  final picker = ImagePickerPlatform.instance;
  if (picker is ImagePickerAndroid) {
    picker.useAndroidPhotoPicker = true;
  }

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

  // Til tanlovi — birinchi kadrdayoq to'g'ri so'z chiqishi uchun kutiladi.
  await LanguageService.instance.load();

  // Restoring the session is deliberately not awaited: it needs a network round trip, and the
  // catalogue is browsable signed-out. Screens that care listen to AuthService instead.
  final authService = AuthService();
  unawaited(authService.restore());

  // Ilovadan foydalanish belgisi (admin paneldagi "nechta odam ishlatyapti" uchun).
  // Kutilmaydi va xatosi yutiladi — ko'rsatkich ilovaning ishiga ta'sir qilmaydi.
  unawaited(AppUsageService.instance.ping());

  // Currency preference and the USD rate — prices render in UZS until the rate arrives.
  unawaited(CurrencyService.instance.load());

  runApp(BusinessHomeApp(themeController: themeController, authService: authService));
}
