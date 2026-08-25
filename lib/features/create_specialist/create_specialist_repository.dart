import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';

/// Mutaxassis profili — saytdagi `/market/cabinet/specialist-profile` endpointlari.
///
/// Profil bo'lsa `PUT` (tahrirlash), bo'lmasa `POST` (yaratish) — saytda ham shunday.
class CreateSpecialistRepository {
  const CreateSpecialistRepository();

  static const _base = '/market/cabinet/specialist-profile';

  /// Mavjud profil; bo'lmasa `null`.
  Future<Map<String, dynamic>?> myProfile() async {
    try {
      final res = await ApiClient.instance.get<dynamic>('/market/cabinet/my-profile');
      final data = res.data;
      if (res.statusCode != 200 || data is! Map<String, dynamic>) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> save({
    required Map<String, dynamic> payload,
    required bool isEdit,
  }) async {
    final api = ApiClient.instance;
    final res = isEdit
        ? await api.put<dynamic>(_base, data: payload)
        : await api.post<dynamic>(_base, data: payload);
    final data = res.data;
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw SpecialistException(
        data is Map && data['detail'] != null ? data['detail'].toString() : 'Saqlashda xatolik',
      );
    }
    return data is Map<String, dynamic> ? data : null;
  }

  /// Portfolio rasmlari — bitta so'rovda, `files` maydoni bilan.
  Future<void> uploadPortfolio(List<File> files) async {
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
    final res = await ApiClient.instance.post<dynamic>('$_base/portfolio', data: form);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw const SpecialistException('Rasmlarni yuklab bo\'lmadi');
    }
  }
}

class SpecialistException implements Exception {
  const SpecialistException(this.message);

  final String message;

  @override
  String toString() => message;
}
