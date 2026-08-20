import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'create_listing_form.dart';

/// Formani avtomatik saqlash — saytdagi `bh_listing_draft_v1` qoralamasi.
///
/// Sayt har ikki sekundda `localStorage` ga yozadi va sahifa qayta ochilganda tiklaydi;
/// tahrirlash rejimida esa umuman saqlamaydi. Ilovada `SharedPreferences` shu vazifani
/// bajaradi — forma olti bo'limdan iborat, ilova qulasa hammasini qaytadan to'ldirish og'ir.
abstract final class ListingDraft {
  static const _key = 'bh_listing_draft_v1';

  /// Saytdagidek — bir haftadan eski qoralama tiklanmaydi.
  static const _maxAge = Duration(days: 7);

  /// Qoralamani o'qiydi va [form] ga yozadi. Qaytadigan qiymat — saqlangan vaqt.
  static Future<DateTime?> restore(ListingForm form) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return null;

      final savedAt = DateTime.fromMillisecondsSinceEpoch(
        (data['__savedAt'] as num?)?.toInt() ?? 0,
      );
      if (DateTime.now().difference(savedAt) > _maxAge) {
        await prefs.remove(_key);
        return null;
      }

      form.applyJson(data);
      return savedAt;
    } catch (_) {
      return null;
    }
  }

  /// Bo'sh formani saqlamaydi — saytdagi shart.
  static Future<DateTime?> save(ListingForm form) async {
    if (form.title.trim().isEmpty &&
        form.description.trim().isEmpty &&
        form.price == null &&
        form.city.isEmpty) {
      return null;
    }
    try {
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({...form.toJson(), '__savedAt': now.millisecondsSinceEpoch}),
      );
      return now;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Qoralamani o'chira olmaslik ish oqimini to'xtatmaydi.
    }
  }
}
