import '../../core/i18n/translate.dart';
import '../../core/api/media_url.dart';
import '../../core/models/project.dart';
import '../../core/models/property_listing.dart';

/// The shape `app-property-card` takes on the site (its `Property` interface).
///
/// New-build projects, rent listings and secondary listings all come from different endpoints with
/// different field names, and the site normalises them into this one view model before rendering.
/// Doing the same here keeps a single card widget instead of one per source.
class PropertyView {
  const PropertyView({
    required this.id,
    required this.name,
    required this.location,
    required this.images,
    this.developer,
    this.developerLogo,
    this.developerCode,
    this.projectCode,
    this.projectLogo,
    this.rooms,
    this.bathrooms,
    this.area,
    this.floor,
    this.totalFloors,
    this.totalBlocks,
    this.totalApartments,
    this.totalArea,
    this.minPrice,
    this.minPricePerM2,
    this.price,
    this.segment,
    this.hasTour = false,
    this.tier,
    this.verified = false,
    this.status,
    this.completion,
    this.payment,
    this.isTop = false,
    this.dealType = 'buy',
    this.propertyType = 'secondary',
    this.priceCurrency = 'uzs',
  });

  final int id;
  final String name;
  final String location;

  /// Already absolute — the card never has to resolve paths itself.
  final List<String> images;

  final String? developer;
  final String? developerLogo;
  final String? developerCode;
  final String? projectCode;
  final String? projectLogo;

  final int? rooms;
  final int? bathrooms;
  final double? area;
  final int? floor;
  final int? totalFloors;
  final int? totalBlocks;
  final int? totalApartments;
  final double? totalArea;

  final num? minPrice;
  final num? minPricePerM2;
  final num? price;

  /// `elite` | `business` | `standart` | `economy`
  final String? segment;
  final bool hasTour;

  /// `pro` | `ultra`
  final String? tier;
  final bool verified;

  final String? status;
  final String? completion;
  final String? payment;
  final bool isTop;

  /// `buy` or `rent` — decides which detail route the card links to.
  final String dealType;

  /// `new-project` | `rent` | `secondary` — the favourites key the site uses.
  final String propertyType;

  /// The currency the listing's own price is stored in. The site passes this to
  /// `currency.format(price, property.currency)` rather than assuming UZS.
  final String priceCurrency;

  /// Rent prices are printed per month — the site appends the tail of `rent.perMonth`
  /// ("so'm/oy") to the symbol.
  bool get isMonthly => dealType == 'rent';

  /// Where tapping the card goes, matching the site's `detailLink` getter: a project with both
  /// codes uses its vanity URL, everything else the id route.
  String get detailPath {
    if (developerCode != null && projectCode != null) return '/$developerCode/$projectCode';
    return dealType == 'rent' ? '/property/rent/$id' : '/property/$id';
  }

  /// Uzbek labels for `segment`, from `rent.segment*` in the site's translations.
  String? get segmentLabel => switch (segment) {
    'elite' => t('rent.segmentElite'),
    'business' => t('rent.segmentBusiness'),
    'standart' => t('designerDetail.standardPkg'),
    'economy' => t('rent.segmentEconomy'),
    _ => null,
  };

  factory PropertyView.fromProject(Project project) {
    // `absoluteMediaUrl` yields null for empty/missing paths, so the `?` marker drops them.
    final images = <String>[
      for (final candidate in [project.cardImage, project.coverImage, ...project.cardImages])
        ?absoluteMediaUrl(candidate),
    ];
    return PropertyView(
      id: project.id,
      name: project.name,
      location: project.locationLabel,
      images: images.isEmpty ? const [_fallbackImage] : images,
      developer: project.developer?.name,
      developerLogo: absoluteMediaUrl(project.developer?.logo),
      developerCode: project.developer?.code,
      projectCode: project.slug.isEmpty ? null : project.slug,
      projectLogo: absoluteMediaUrl(project.projectLogo),
      totalBlocks: project.totalBlocks,
      totalApartments: project.totalApartments,
      totalArea: project.totalArea,
      minPrice: project.minPrice,
      isTop: project.isTop,
      completion: project.endDate,
      dealType: 'buy',
      propertyType: 'new-project',
    );
  }

  factory PropertyView.fromListing(PropertyListing listing, {required String propertyType}) {
    final images = <String>[for (final image in listing.images) ?absoluteMediaUrl(image)];
    return PropertyView(
      id: listing.id,
      name: listing.title,
      location: listing.locationLabel,
      images: images.isEmpty ? [_fallbackForType(listing.type)] : images,
      rooms: listing.rooms,
      bathrooms: listing.bathrooms,
      area: listing.area,
      floor: listing.floor,
      totalFloors: listing.totalFloors,
      price: listing.price,
      hasTour: listing.hasVirtualTour,
      status: listing.status,
      priceCurrency: listing.currency ?? 'uzs',
      dealType: propertyType == 'rent' ? 'rent' : 'buy',
      propertyType: propertyType,
    );
  }

  static const _fallbackImage =
      'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=600&q=80';

  /// The site's `fallbackByType` — a stock photo per listing type when none was uploaded.
  static String _fallbackForType(String? type) => switch (type) {
    'apartment' => 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600&q=80',
    'house' => 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600&q=80',
    'office' => 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=600&q=80',
    'shop' => 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=600&q=80',
    'parking' => 'https://images.unsplash.com/photo-1545179605-1296651e9d43?w=600&q=80',
    'building' => 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=600&q=80',
    'land' => 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=600&q=80',
    _ => _fallbackImage,
  };
}
