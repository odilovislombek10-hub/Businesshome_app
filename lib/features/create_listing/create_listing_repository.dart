import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';

/// E'lon yaratish/tahrirlash — saytdagi `/market/my-listings` endpointlari.
///
/// Yangi e'lon `is_active=false` bilan yaratiladi va modaratsiyaga tushadi, ya'ni darrov
/// saytda ko'rinmaydi (backend: `market_user_listings_router.py`).
class CreateListingRepository {
  const CreateListingRepository();

  static const _base = '/market/my-listings';

  /// Yangi e'lon yaratadi va `id` sini qaytaradi.
  Future<int> create({required String kind, required Map<String, dynamic> payload}) async {
    final res = await ApiClient.instance.post<dynamic>('$_base/$kind', data: payload);
    final data = res.data;
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw ListingException(_detail(data) ?? 'Saqlashda xatolik', status: res.statusCode);
    }
    final id = data is Map ? data['id'] : null;
    if (id is! int) throw const ListingException('Saqlashda xatolik');
    return id;
  }

  Future<void> update({
    required String kind,
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final res = await ApiClient.instance.put<dynamic>('$_base/$kind/$id', data: payload);
    if (res.statusCode != 200) {
      throw ListingException(_detail(res.data) ?? 'Saqlashda xatolik', status: res.statusCode);
    }
  }

  /// Rasmlar bitta so'rovda, `files` maydoni bilan ketadi — saytdagi kabi.
  Future<void> uploadImages({
    required String kind,
    required int id,
    required List<File> files,
  }) async {
    if (files.isEmpty) return;
    final form = FormData();
    for (final file in files) {
      form.files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
        ),
      );
    }
    final res = await ApiClient.instance.post<dynamic>('$_base/$kind/$id/images', data: form);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ListingException(
        _detail(res.data) ?? "Ba'zi media yuklanmadi — cabinet'dan qaytadan yuklashingiz mumkin.",
        status: res.statusCode,
      );
    }
  }

  /// Tahrirlash uchun mavjud e'lonni oladi.
  Future<Map<String, dynamic>?> byId({required String kind, required int id}) async {
    final res = await ApiClient.instance.get<dynamic>('$_base/me');
    if (res.statusCode != 200) return null;
    final data = res.data;
    if (data is! List) return null;
    for (final row in data) {
      if (row is Map<String, dynamic> && row['id'] == id && row['kind'] == kind) return row;
    }
    return null;
  }

  static String? _detail(Object? data) {
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    return null;
  }
}

class ListingException implements Exception {
  const ListingException(this.message, {this.status});

  final String message;
  final int? status;

  @override
  String toString() => message;
}
