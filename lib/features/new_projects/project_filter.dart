import '../../core/models/project.dart';

/// `/new-projects` filtri.
///
/// **Hammasi mijoz tomonida.** Sayt `/api/viewer/projects` dan barcha loyihalarni bir marta
/// oladi va qidiruv, filtr, saralash va sahifalashni `filteredProjects()` computed'ida o'zi
/// bajaradi — endpoint bu parametrlarni bilmaydi.
class ProjectFilter {
  const ProjectFilter({
    this.search = '',
    this.city = '',
    this.priceMin = 0,
    this.priceMax = 0,
    this.completion = '',
    this.sort = 'newest',
    this.page = 1,
  });

  final String search;
  final String city;
  final num priceMin;
  final num priceMax;

  /// Topshirish yili (`2026`) — loyihaning tugash sanasidan olingan yil bilan solishtiriladi.
  final String completion;

  /// `newest` | `price_asc` | `price_desc` | `area_desc`
  final String sort;
  final int page;

  /// Saytda bir sahifada to'qqizta.
  static const perPage = 9;

  /// Saytdagi `hasActiveFilters` — qidiruv va saralash bunga kirmaydi.
  bool get hasActive => city.isNotEmpty || priceMin > 0 || priceMax > 0 || completion.isNotEmpty;

  ProjectFilter copyWith({
    String? search,
    String? city,
    num? priceMin,
    num? priceMax,
    String? completion,
    String? sort,
    int? page,
  }) => ProjectFilter(
    search: search ?? this.search,
    city: city ?? this.city,
    priceMin: priceMin ?? this.priceMin,
    priceMax: priceMax ?? this.priceMax,
    completion: completion ?? this.completion,
    sort: sort ?? this.sort,
    page: page ?? this.page,
  );

  /// Bazadagi shahar nomi filtr qiymatiga to'g'ri kelishini tekshiradi.
  ///
  /// Saytdagi `cityMatchesFilter` — baza goh kodni (`tashkent_city`), goh nomni (`Toshkent`,
  /// `Samarqand`) saqlaydi, shuning uchun har bir kod uchun taxalluslar ro'yxati bor.
  static Map<String, List<String>> get _cityAliases => <String, List<String>>{
    'tashkent_city': ['tashkent_city', 'tashkent', 'toshkent'],
    'samarkand': ['samarkand', 'samarqand'],
    'bukhara': ['bukhara', 'buxoro'],
    'andijan': ['andijan', 'andijon'],
    'fergana': ['fergana', 'fargona', "farg'ona"],
    'namangan': ['namangan'],
    'navoiy': ['navoiy', 'navoi'],
    'karshi': ['karshi', 'qarshi', 'kashkadarya', 'qashqadaryo'],
    'urgench': ['urgench', 'xorazm', 'khorezm'],
    'surxondaryo': ['surxondaryo', 'surkhandarya', 'termez'],
    'jizzakh': ['jizzakh', 'jizzax'],
    'sirdaryo': ['sirdaryo', 'syrdarya', 'guliston'],
    'nukus': ['nukus', 'karakalpakstan', "qoraqalpog'iston"],
  };

  static bool _cityMatches(String? dbCity, String filterCity) {
    if (dbCity == null || dbCity.isEmpty) return false;
    final db = dbCity.trim().toLowerCase();
    final filter = filterCity.trim().toLowerCase();
    if (db == filter) return true;
    return (_cityAliases[filter] ?? [filter]).contains(db);
  }

  /// Saytdagi `filteredProjects()` — filtrlash va saralash, sahifalashsiz.
  List<Project> apply(List<Project> projects) {
    var result = [...projects];

    if (search.isNotEmpty) {
      final query = search.toLowerCase();
      result = [
        for (final p in result)
          if (p.name.toLowerCase().contains(query) ||
              p.locationLabel.toLowerCase().contains(query) ||
              (p.developer?.name ?? '').toLowerCase().contains(query))
            p,
      ];
    }
    if (city.isNotEmpty) {
      result = [
        for (final p in result)
          if (_cityMatches(p.city, city)) p,
      ];
    }
    if (priceMin > 0) {
      result = [
        for (final p in result)
          if ((p.minPrice ?? 0) >= priceMin) p,
      ];
    }
    if (priceMax > 0) {
      result = [
        for (final p in result)
          if ((p.minPrice ?? 0) <= priceMax) p,
      ];
    }
    if (completion.isNotEmpty) {
      result = [
        for (final p in result)
          if (p.completionYear == completion) p,
      ];
    }

    switch (sort) {
      case 'price_asc':
        result.sort((a, b) => ((a.minPrice ?? 0) - (b.minPrice ?? 0)).sign.toInt());
      case 'price_desc':
        result.sort((a, b) => ((b.minPrice ?? 0) - (a.minPrice ?? 0)).sign.toInt());
      case 'area_desc':
        result.sort((a, b) => ((b.totalArea ?? 0) - (a.totalArea ?? 0)).sign.toInt());
      default:
        result.sort((a, b) => b.id - a.id);
    }
    return result;
  }

  /// Joriy sahifadagi to'qqiztasi.
  List<Project> pageOf(List<Project> filtered) {
    final start = (page - 1) * perPage;
    if (start >= filtered.length) return const [];
    return filtered.sublist(start, (start + perPage).clamp(0, filtered.length));
  }
}
