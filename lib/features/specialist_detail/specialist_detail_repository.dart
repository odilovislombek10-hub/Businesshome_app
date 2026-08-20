import '../../core/api/api_client.dart';
import 'specialist_detail_models.dart';

/// Dizayner va usta tafsiloti — ikkalasi bir xil shakldagi endpointlar.
///
/// Diqqat: bu endpointlar prodda 2026-08-20 gacha 500 qaytarardi (serverda
/// `helpers/rating_stats.py` yo'q edi). Tuzatilgach ishlaydi.
class SpecialistDetailRepository {
  const SpecialistDetailRepository({required this.kind});

  /// `designers` yoki `masters`.
  final String kind;

  Future<SpecialistDetail?> byId(int id) async {
    try {
      final res = await ApiClient.instance.get<dynamic>('/market/$kind/$id');
      final data = res.data;
      if (res.statusCode != 200 || data is! Map<String, dynamic>) return null;
      return SpecialistDetail.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<SpecialistReview>> reviews(int id) async {
    try {
      final res = await ApiClient.instance.get<dynamic>('/market/$kind/$id/reviews');
      final data = res.data;
      if (res.statusCode != 200 || data is! List) return const [];
      return [
        for (final row in data)
          if (row is Map) SpecialistReview.fromJson(row),
      ];
    } catch (_) {
      return const [];
    }
  }
}
