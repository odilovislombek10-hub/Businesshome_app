import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

/// Ilovadan foydalanish belgisi — admin panelda "nechta odam ilovani ishlatyapti"
/// ko'rsatkichi uchun.
///
/// Saytdagi `app.businesshome.uz` faqat **yuklab olish tugmasi bosilishini** qayd etadi
/// (`/analytics/app-download`), ya'ni ilova o'rnatilgan-o'rnatilmagani noma'lum. Bu yerda
/// ilovaning o'zi ochilganda belgi yuboradi.
///
/// Yuboriladigan narsa: anonim o'rnatish identifikatori (qurilmada bir marta yaratiladi),
/// platforma va ilova versiyasi. Shaxsiy ma'lumot yo'q; foydalanuvchi kirgan bo'lsa,
/// so'rovdagi token orqali backend uni o'zi bog'lab qo'yadi.
class AppUsageService {
  AppUsageService._();

  static final AppUsageService instance = AppUsageService._();

  static const _installIdKey = 'bh_install_id';
  static const _lastPingKey = 'bh_install_last_ping';

  /// Saytdagi analytics singari ochiq endpoint — kirish shart emas.
  static const _endpoint = '/analytics/app-ping';

  /// Bir soatda bir martadan ko'p yuborilmaydi (ilova qayta ochilaverishi mumkin).
  static const _interval = Duration(hours: 1);

  bool _sending = false;

  /// Qurilmaga bir marta yoziladigan tasodifiy identifikator.
  Future<String> installId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installIdKey);
    if (existing != null && existing.length >= 16) return existing;
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await prefs.setString(_installIdKey, id);
    return id;
  }

  /// Ilova ochilganda va fonga chiqib qaytganda chaqiriladi.
  Future<void> ping() async {
    if (_sending) return;
    _sending = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_lastPingKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - last < _interval.inMilliseconds) return;

      final info = await PackageInfo.fromPlatform();
      await ApiClient.instance.post<dynamic>(
        _endpoint,
        data: {
          'install_id': await installId(),
          'platform': Platform.isIOS ? 'ios' : 'android',
          'app_version': '${info.version}+${info.buildNumber}',
        },
      );
      await prefs.setInt(_lastPingKey, now);
    } catch (_) {
      // Endpoint hali yo'q bo'lsa yoki tarmoq yo'q bo'lsa — ilovaga umuman ta'sir qilmaydi.
      if (kDebugMode) {
        // Jim o'tamiz: bu ko'rsatkich, funksiya emas.
      }
    } finally {
      _sending = false;
    }
  }
}
