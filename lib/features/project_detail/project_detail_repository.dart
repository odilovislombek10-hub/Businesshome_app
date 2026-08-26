import '../../core/api/api_client.dart';
import 'project_detail_models.dart';

/// Yangi qurilish loyihasi sahifasining ma'lumoti.
///
/// Sayt ikki xil kirishni qo'llaydi: `/property/:id` (id bo'yicha, avval ro'yxatdan
/// quruvchi kodi va slug topiladi) va `/:dev/:project` (to'g'ridan-to'g'ri).
class ProjectDetailRepository {
  const ProjectDetailRepository();

  Future<ProjectDetail?> byCode(String developerCode, String projectCode) async {
    try {
      final res = await ApiClient.instance.get<dynamic>(
        '/viewer/projects/$developerCode/$projectCode',
      );
      final data = res.data;
      if (res.statusCode != 200 || data is! Map<String, dynamic>) return null;
      return ProjectDetail.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// `/property/:id` — saytda ham avval loyihalar ro'yxati olinadi va `id` bo'yicha
  /// quruvchi kodi bilan slug topiladi.
  Future<ProjectDetail?> byId(int id) async {
    try {
      final res = await ApiClient.instance.get<dynamic>(
        // `/market/projects` sahifalamaydi — barcha faol loyihalarni qaytaradi
        // (backendda `per_page` degan parametr yo'q).
        '/market/projects',
      );
      final data = res.data;
      final items = data is Map ? data['items'] : data;
      if (items is! List) return null;
      for (final row in items) {
        if (row is! Map || row['id'] != id) continue;
        final developer = row['developer'];
        final code = developer is Map ? developer['code']?.toString() : null;
        final slug = row['slug']?.toString();
        if (code == null || slug == null) return null;
        return byCode(code, slug);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
