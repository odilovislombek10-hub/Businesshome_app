import 'secondary_texts.dart';

/// What differs between `/secondary` and `/rent`.
///
/// The two pages are the same component on the site down to the class names — same hero, same
/// search card, same filter panel, same sort options. Only the copy, the hero photo and the
/// endpoint change, so they share one screen here and differ by this config.
class ListingsConfig {
  const ListingsConfig({
    required this.path,
    required this.endpoint,
    required this.propertyType,
    required this.heroTitle,
    required this.heroDesc,
    required this.heroImage,
    required this.searchPlaceholder,
    required this.noResultsDesc,
    required this.detailPathPrefix,
    required this.hasPaymentFilter,
  });

  /// Where the screen lives, used when resetting the URL.
  final String path;
  final String endpoint;

  /// `secondary` or `rent` — the favourites key and the card's deal type.
  final String propertyType;

  final String heroTitle;
  final String heroDesc;
  final String heroImage;
  final String searchPlaceholder;
  final String noResultsDesc;

  /// `/property/secondary` or `/property/rent`.
  final String detailPathPrefix;

  /// Only the secondary page filters by payment method — `rent.component.ts` has no such field.
  final bool hasPaymentFilter;

  static const secondary = ListingsConfig(
    path: '/secondary',
    endpoint: '/market/secondary',
    propertyType: 'secondary',
    heroTitle: SecondaryTexts.heroTitle,
    heroDesc: SecondaryTexts.heroDesc,
    heroImage: SecondaryTexts.heroImage,
    searchPlaceholder: SecondaryTexts.searchPlaceholder,
    noResultsDesc: SecondaryTexts.noResultsDesc,
    detailPathPrefix: '/property/secondary',
    hasPaymentFilter: true,
  );

  static const rent = ListingsConfig(
    path: '/rent',
    endpoint: '/market/rent',
    propertyType: 'rent',
    heroTitle: "Ijara e'lonlari",
    heroDesc:
        "Kvartira, hovli uy, ofis, do'kon va boshqa mulklarni qisqa yoki uzoq muddatga "
        "ijaraga olish",
    // The site's rent hero photo, hard-coded in `rent.component.ts`.
    heroImage: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1920&q=80',
    searchPlaceholder: "Tuman, ko'cha yoki bino nomi...",
    noResultsDesc: "Boshqa filterlarni tanlang yoki qidiruv so'zini o'zgartiring",
    detailPathPrefix: '/property/rent',
    hasPaymentFilter: false,
  );
}
