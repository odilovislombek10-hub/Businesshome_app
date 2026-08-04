import '../api/api_client.dart';
import '../models/region.dart';

/// `/api/market/regions` — the region/district list every filter and the registration form use.
///
/// The list changes about never, so it is fetched once per app run and reused.
class RegionsService {
  RegionsService._();
  static final RegionsService instance = RegionsService._();

  List<Region>? _cache;
  Future<List<Region>>? _inFlight;

  Future<List<Region>> regions() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    // Several screens can ask at once on a cold start; share the one request between them.
    return _inFlight ??= _fetch();
  }

  Future<List<Region>> _fetch() async {
    try {
      final res = await ApiClient.instance.get<dynamic>('/market/regions');
      final data = res.data;
      if (data is! List) return const [];
      final regions = data.whereType<Map<String, dynamic>>().map(Region.fromJson).toList();
      _cache = regions;
      return regions;
    } catch (_) {
      return const [];
    } finally {
      _inFlight = null;
    }
  }
}
