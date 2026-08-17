import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// GET javoblarini diskda saqlaydigan oddiy kesh.
///
/// Sabab: ilova har ochilganda hamma ma'lumotni noldan so'raydi — bosh sahifada o'n oltita
/// so'rov — va javob kelguncha ekranda hech narsa bo'lmaydi. Sekin internetda bu bir necha
/// soniya bo'sh ekran degani, ustiga server tomonda so'rovlar to'plami rate-limit'ga uriladi.
///
/// Har bir yozuv `{"at": <ms>, "body": <javob>}` ko'rinishida bitta faylda turadi.
class ResponseCache {
  ResponseCache._();
  static final ResponseCache instance = ResponseCache._();

  Directory? _dir;
  Future<Directory>? _opening;

  /// Diskka tegmaslik uchun oxirgi o'qilganlar xotirada ham turadi.
  final _memory = <String, CachedResponse>{};

  Future<Directory?> _directory() async {
    if (_dir != null) return _dir;
    try {
      return _dir = await (_opening ??= _open());
    } catch (_) {
      return null; // kesh ishlamasa ilova baribir ishlashi kerak
    } finally {
      _opening = null;
    }
  }

  Future<Directory> _open() async {
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/bh_api_cache');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Yo'l va so'rov parametrlaridan barqaror fayl nomi. Parametrlar tartibi so'rovdan so'rovga
  /// o'zgarishi mumkin, shuning uchun ular saralanadi.
  static String keyFor(String path, Map<String, dynamic>? query) {
    final parts = <String>[path];
    if (query != null && query.isNotEmpty) {
      final keys = query.keys.toList()..sort();
      for (final k in keys) {
        parts.add('$k=${query[k]}');
      }
    }
    final raw = parts.join('&');
    // Fayl tizimi uchun xavfsiz nom + to'qnashuvni oldini olish uchun xesh.
    final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final trimmed = safe.length <= 80 ? safe : safe.substring(0, 80);
    return '${trimmed}_${raw.hashCode.toUnsigned(32)}';
  }

  Future<CachedResponse?> read(String key) async {
    final inMemory = _memory[key];
    if (inMemory != null) return inMemory;

    final dir = await _directory();
    if (dir == null) return null;
    final file = File('${dir.path}/$key.json');
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      final at = (decoded['at'] as num?)?.toInt();
      if (at == null) return null;
      final entry = CachedResponse(
        body: decoded['body'],
        savedAt: DateTime.fromMillisecondsSinceEpoch(at),
      );
      _memory[key] = entry;
      return entry;
    } catch (_) {
      // Buzilgan yozuv — o'chirib tashlaymiz, keyingi so'rov tarmoqqa boradi.
      unawaited(file.delete().catchError((_) => file));
      return null;
    }
  }

  Future<void> write(String key, Object? body, {required DateTime at}) async {
    _memory[key] = CachedResponse(body: body, savedAt: at);
    final dir = await _directory();
    if (dir == null) return;
    try {
      final payload = jsonEncode({'at': at.millisecondsSinceEpoch, 'body': body});
      await File('${dir.path}/$key.json').writeAsString(payload);
    } catch (e) {
      // Diskka yozib bo'lmasa (joy yo'q, ruxsat yo'q) — xotiradagi nusxa yetadi.
      debugPrint('ResponseCache: yozib bo‘lmadi ($key): $e');
    }
  }

  /// Chiqishda chaqiriladi: boshqa hisobning ma'lumoti ekranda qolmasligi kerak.
  Future<void> clear() async {
    _memory.clear();
    final dir = await _directory();
    if (dir == null) return;
    try {
      if (dir.existsSync()) await dir.delete(recursive: true);
      _dir = null;
    } catch (_) {}
  }
}

class CachedResponse {
  const CachedResponse({required this.body, required this.savedAt});

  final Object? body;
  final DateTime savedAt;

  Duration get age => DateTime.now().difference(savedAt);
}
