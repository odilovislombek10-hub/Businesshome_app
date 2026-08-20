import '../../core/api/api_client.dart';
import '../../shared/widgets/yandex_map.dart';

/// Xarita nuqtalari uchun so'rov chegaralari — saytdagi `MapViewportFilter`.
class MapViewport {
  const MapViewport({
    required this.latMin,
    required this.latMax,
    required this.lngMin,
    required this.lngMax,
    required this.zoom,
  });

  final double latMin;
  final double latMax;
  final double lngMin;
  final double lngMax;
  final double zoom;

  Map<String, dynamic> toQuery() => {
    'lat_min': latMin,
    'lat_max': latMax,
    'lng_min': lngMin,
    'lng_max': lngMax,
    'zoom': zoom.round(),
  };
}

/// Bitta e'lon nuqtasi — `MapPoint`.
class MapPoint {
  const MapPoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.price,
    required this.title,
    required this.rent,
  });

  final int id;
  final double lat;
  final double lng;
  final num price;
  final String title;
  final bool rent;

  static MapPoint? fromJson(Object? json, {required bool rent}) {
    if (json is! Map) return null;
    final lat = json['lat'], lng = json['lng'];
    if (lat is! num || lng is! num) return null;
    return MapPoint(
      id: (json['id'] as num?)?.toInt() ?? 0,
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      price: json['price'] is num ? json['price'] as num : 0,
      title: json['title']?.toString() ?? '',
      rent: rent,
    );
  }
}

/// Bir chaqiruvning natijasi — alohida nuqtalar va klasterlar.
class MapPoints {
  const MapPoints({this.points = const [], this.clusters = const []});

  final List<MapPoint> points;
  final List<MapCluster> clusters;
}

/// Saytdagi `/map` sahifasining ma'lumot qatlami.
///
/// Javob uch xil bo'lishi mumkin (`mode`): `points` — hammasi alohida, `clusters` — faqat
/// agregat, `mixed` — ikkalasi ham. Sayt ham aynan shu uch holatni ajratadi.
class MapSearchRepository {
  const MapSearchRepository();

  Future<MapPoints> points({required bool rent, required Map<String, dynamic> filters}) async {
    try {
      final res = await ApiClient.instance.get<dynamic>(
        rent ? '/market/rent/map/points' : '/market/secondary/map/points',
        query: filters,
      );
      final data = res.data;
      if (res.statusCode != 200) return const MapPoints();

      // Eski versiyada javob oddiy ro'yxat ham bo'lishi mumkin.
      if (data is List) {
        return MapPoints(points: _points(data, rent: rent));
      }
      if (data is! Map) return const MapPoints();

      return switch (data['mode']) {
        'points' => MapPoints(points: _points(data['items'], rent: rent)),
        'clusters' => MapPoints(clusters: _clusters(data['items'])),
        'mixed' => MapPoints(
          points: _points(data['points'], rent: rent),
          clusters: _clusters(data['clusters']),
        ),
        _ => const MapPoints(),
      };
    } catch (_) {
      return const MapPoints();
    }
  }

  static List<MapPoint> _points(Object? raw, {required bool rent}) {
    if (raw is! List) return const [];
    return [for (final row in raw) ?MapPoint.fromJson(row, rent: rent)];
  }

  static List<MapCluster> _clusters(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final row in raw)
        if (row is Map && row['lat'] is num && row['lng'] is num)
          MapCluster(
            lat: (row['lat'] as num).toDouble(),
            lng: (row['lng'] as num).toDouble(),
            count: (row['count'] as num?)?.toInt() ?? 0,
          ),
    ];
  }
}
