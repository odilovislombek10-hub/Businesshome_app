/// A rent or secondary-market listing, as returned by `/api/market/rent` and
/// `/api/market/secondary`.
///
/// Unlike the project endpoints these answer in camelCase, so the keys here are not the
/// snake_case used elsewhere — that difference is in the backend, not a mistake.
class PropertyListing {
  const PropertyListing({
    required this.id,
    required this.title,
    this.type,
    this.price,
    this.currency,
    this.rooms,
    this.bathrooms,
    this.area,
    this.landArea,
    this.floor,
    this.totalFloors,
    this.city,
    this.district,
    this.address,
    this.lat,
    this.lng,
    this.images = const [],
    this.description,
    this.amenities = const [],
    this.status,
    this.hasVirtualTour = false,
    this.videoUrl,
    this.videoThumbnail,
    this.owner,
    this.createdAt,
  });

  final int id;
  final String title;
  final String? type;
  final num? price;
  final String? currency;
  final int? rooms;
  final int? bathrooms;
  final double? area;
  final double? landArea;
  final int? floor;
  final int? totalFloors;
  final String? city;
  final String? district;
  final String? address;
  final double? lat;
  final double? lng;
  final List<String> images;
  final String? description;
  final List<String> amenities;
  final String? status;
  final bool hasVirtualTour;
  final String? videoUrl;
  final String? videoThumbnail;
  final ListingOwner? owner;
  final DateTime? createdAt;

  String? get thumbnail => images.isEmpty ? null : images.first;

  /// Human-readable location, skipping the parts the backend left empty.
  String get locationLabel => [district, city]
      .where((s) => s != null && s.trim().isNotEmpty)
      .map((s) => s!.trim())
      .join(', ');

  factory PropertyListing.fromJson(Map<String, dynamic> json) => PropertyListing(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title']?.toString() ?? '',
        type: json['type']?.toString(),
        price: json['price'] as num?,
        currency: json['currency']?.toString(),
        rooms: (json['rooms'] as num?)?.toInt(),
        bathrooms: (json['bathrooms'] as num?)?.toInt(),
        area: (json['area'] as num?)?.toDouble(),
        landArea: (json['landArea'] as num?)?.toDouble(),
        floor: (json['floor'] as num?)?.toInt(),
        totalFloors: (json['totalFloors'] as num?)?.toInt(),
        city: json['city']?.toString(),
        district: json['district']?.toString(),
        address: json['address']?.toString(),
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        images: (json['images'] as List?)?.whereType<String>().toList() ?? const [],
        description: json['description']?.toString(),
        amenities: (json['amenities'] as List?)?.whereType<String>().toList() ?? const [],
        status: json['status']?.toString(),
        hasVirtualTour: json['hasVirtualTour'] == true,
        videoUrl: json['videoUrl']?.toString(),
        videoThumbnail: json['videoThumbnail']?.toString(),
        owner: json['owner'] is Map<String, dynamic>
            ? ListingOwner.fromJson(json['owner'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

class ListingOwner {
  const ListingOwner({this.name, this.phone, this.avatar, this.type});

  final String? name;
  final String? phone;
  final String? avatar;

  /// `owner`, `agent`, … — the site badges the listing differently for each.
  final String? type;

  factory ListingOwner.fromJson(Map<String, dynamic> json) => ListingOwner(
        name: json['name']?.toString(),
        phone: json['phone']?.toString(),
        avatar: json['avatar']?.toString(),
        type: json['type']?.toString(),
      );
}

/// The `{items, total, page, pages}` envelope the listing endpoints return.
class Paginated<T> {
  const Paginated({required this.items, required this.total, required this.page, required this.pages});

  const Paginated.empty()
      : items = const [],
        total = 0,
        page = 1,
        pages = 1;

  final List<T> items;
  final int total;
  final int page;
  final int pages;

  bool get hasMore => page < pages;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) =>
      Paginated(
        items: (json['items'] as List?)?.whereType<Map<String, dynamic>>().map(parse).toList() ??
            const [],
        total: (json['total'] as num?)?.toInt() ?? 0,
        page: (json['page'] as num?)?.toInt() ?? 1,
        pages: (json['pages'] as num?)?.toInt() ?? 1,
      );
}
