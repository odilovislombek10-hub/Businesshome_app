import '../../core/api/api_client.dart';
import '../../core/models/project.dart';

class ProjectsRepository {
  final _api = ApiClient.instance;

  /// New-build projects — the same `/viewer/projects` endpoint the website's `getProjects()` uses.
  ///
  /// It answers with a bare JSON array today but the site also handles a paginated envelope, so
  /// both shapes are accepted here. Paging is by `page`/`per_page`, matching the site's filter.
  Future<List<Project>> fetchProjects({int page = 1, int perPage = 20}) async {
    final res = await _api.get<dynamic>(
      '/viewer/projects',
      query: {'page': page, 'per_page': perPage},
    );
    final data = res.data;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(Project.fromJson).toList();
    }
    // Some endpoints wrap results; accept that shape too rather than failing on it.
    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['results'] ?? data['data'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().map(Project.fromJson).toList();
      }
    }
    return const [];
  }
}
