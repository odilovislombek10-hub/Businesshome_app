import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

/// Saytdagi `favorites.service.ts` ning o'rni.
///
/// Sevimlilar serverda saqlanadi: kirishda ro'yxat bir marta yuklanadi, keyin
/// har bosilishda avval ekran yangilanadi (`optimistic update`), so'ng so'rov
/// ketadi; xatolik bo'lsa holat qaytariladi. Chiqishda ro'yxat tozalanadi.
class FavoritesService extends ChangeNotifier {
  FavoritesService._();

  static final FavoritesService instance = FavoritesService._();

  final _keys = <String>{};
  final _toggling = <String>{};
  bool _loaded = false;

  /// `toKey()` — loyihalarda bir xil `id` turli quruvchilarda uchraydi.
  static String _key(int id, String type, [String? developerCode]) =>
      developerCode == null || developerCode.isEmpty ? '$id:$type' : '$id:$type:$developerCode';

  bool isFavorite(int id, String type, [String? developerCode]) =>
      _keys.contains(_key(id, type, developerCode));

  bool isToggling(int id, String type, [String? developerCode]) =>
      _toggling.contains(_key(id, type, developerCode));

  /// Kirgan foydalanuvchi uchun barcha sevimli kalitlarni oladi.
  Future<void> load() async {
    if (!await ApiClient.instance.isLoggedIn) return;
    try {
      final res = await ApiClient.instance.get<dynamic>('/market/cabinet/favorites/ids');
      final data = res.data;
      if (data is! List) return;
      _keys
        ..clear()
        ..addAll([
          for (final row in data)
            if (row is Map)
              _key(
                (row['property_id'] as num?)?.toInt() ?? 0,
                row['property_type']?.toString() ?? '',
                row['developer_code']?.toString(),
              ),
        ]);
      _loaded = true;
      notifyListeners();
    } catch (_) {
      // Saytda ham xatolik jim yutiladi — bu kritik emas.
    }
  }

  /// Chiqishda tozalanadi.
  void clear() {
    _keys.clear();
    _toggling.clear();
    _loaded = false;
    notifyListeners();
  }

  /// Qaytadi: yangi holat. Kirmagan bo'lsa `null` — chaqiruvchi login sahifasiga
  /// yuboradi (saytda auth oynasi ochiladi).
  Future<bool?> toggle(
    int id,
    String type, {
    String? developerCode,
    Map<String, dynamic>? metadata,
  }) async {
    if (!await ApiClient.instance.isLoggedIn) return null;
    if (!_loaded) await load();

    final key = _key(id, type, developerCode);
    if (_toggling.contains(key)) return _keys.contains(key);
    _toggling.add(key);

    final was = _keys.contains(key);
    was ? _keys.remove(key) : _keys.add(key);
    notifyListeners();

    try {
      if (was) {
        await ApiClient.instance.delete<dynamic>(
          '/market/cabinet/favorites/$type/$id',
          query: {'developer_code': ?developerCode},
        );
      } else {
        await ApiClient.instance.post<dynamic>(
          '/market/cabinet/favorites',
          data: {
            'property_id': id,
            'property_type': type,
            'developer_code': developerCode,
            'metadata': metadata,
          },
        );
      }
      return !was;
    } catch (_) {
      // Xatolikda oldingi holatga qaytamiz.
      was ? _keys.add(key) : _keys.remove(key);
      notifyListeners();
      return was;
    } finally {
      _toggling.remove(key);
      notifyListeners();
    }
  }
}
