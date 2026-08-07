import '../../core/api/api_client.dart';
import '../../core/models/brief.dart';

/// `/api/market/birja` filtri.
///
/// Backend `target`, `specialization`, `project_type`, `city`, `budget_min`, `budget_max`,
/// `page`, `per_page` ni oladi. Sayt ulardan faqat uchtasini yuboradi — qolganlariga boshqaruv
/// yo'q, shu bois bu yerda ham yo'q.
///
/// **Saralash serverda emas:** sayt `budget_desc` ni kelgan ro'yxat ustida o'zi tartiblaydi,
/// chunki endpoint `sort` parametrini bilmaydi. Shu xatti-harakat [sortItems] da saqlangan.
class BriefFilter {
  const BriefFilter({this.target = '', this.projectType = '', this.city = '', this.sort = 'new'});

  /// `''` | `designer` | `master`
  final String target;

  /// `''` | `apartment` | `house` | `office` | `shop`
  final String projectType;
  final String city;

  /// `new` | `budget_desc`
  final String sort;

  bool get hasActive => target.isNotEmpty || projectType.isNotEmpty || city.isNotEmpty;

  BriefFilter copyWith({String? target, String? projectType, String? city, String? sort}) =>
      BriefFilter(
        target: target ?? this.target,
        projectType: projectType ?? this.projectType,
        city: city ?? this.city,
        sort: sort ?? this.sort,
      );

  Map<String, dynamic> toQuery() => {
    if (target.isNotEmpty) 'target': target,
    if (projectType.isNotEmpty) 'project_type': projectType,
    if (city.isNotEmpty) 'city': city,
  };

  /// Saytdagi mijoz tomonidagi tartiblash: eng katta byudjet tepada.
  List<Brief> sortItems(List<Brief> items) {
    if (sort != 'budget_desc') return items;
    final sorted = [...items];
    int weight(Brief b) => b.budgetTo ?? b.budgetFrom ?? 0;
    sorted.sort((a, b) => weight(b) - weight(a));
    return sorted;
  }
}

class BirjaRepository {
  const BirjaRepository();

  ApiClient get _api => ApiClient.instance;

  Future<List<Brief>> list(BriefFilter filter) async {
    final res = await _api.get<dynamic>('/market/birja', query: filter.toQuery());
    final data = res.data;
    final items = data is Map ? data['items'] : null;
    if (items is! List) return const [];
    return filter.sortItems(items.whereType<Map<String, dynamic>>().map(Brief.fromJson).toList());
  }

  /// Yangi buyurtma joylash. Tana `BirjaCreateSheet` dan tayyor holda keladi.
  Future<void> create(Map<String, dynamic> body) async {
    await _api.post<dynamic>('/market/birja', data: body);
  }

  /// Javob yuborish — muvaffaqiyatli bo'lsa ochilgan suhbat id'sini qaytaradi.
  Future<int?> respond(int briefId, String message) async {
    final res = await _api.post<dynamic>(
      '/market/birja/$briefId/respond',
      data: {'message': message},
    );
    final data = res.data;
    return data is Map ? (data['conversation_id'] as num?)?.toInt() : null;
  }
}
