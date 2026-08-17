import '../../core/api/api_client.dart';
import 'my_home_models.dart';

/// `/api/market/cabinet/my-home` — "Mening uyim" ma'lumotlari.
///
/// Sayt avval `/auto` ni so'raydi (CRM'dan avtomatik topilgan shartnomalar), u bo'sh bo'lsa
/// qo'lda kiritilgan yozuvga tushadi.
class MyHomeRepository {
  const MyHomeRepository();

  ApiClient get _api => ApiClient.instance;

  /// Bo'sh ro'yxat — foydalanuvchida hali xonadon yo'q degani.
  Future<List<MyHomeItem>> load() async {
    final auto = await _fetch('/market/cabinet/my-home/auto');
    if (auto.isNotEmpty) return auto;
    return _fetch('/market/cabinet/my-home');
  }

  Future<List<MyHomeItem>> _fetch(String path) async {
    final res = await _api.get<dynamic>(path);
    final data = res.data;
    if (data is! Map<String, dynamic>) return const [];

    // Javob ikki xil kelishi mumkin: `properties` ro'yxati yoki bitta mulkning o'zi.
    final properties = data['properties'];
    if (properties is List) {
      return properties
          .whereType<Map<String, dynamic>>()
          .map(MyHomeItem.fromJson)
          .where((item) => item.property != null || item.contract != null)
          .toList();
    }

    final single = MyHomeItem.fromJson(data);
    return single.property == null && single.contract == null ? const [] : [single];
  }

  /// Pasport yoki telefon orqali CRM'dagi shartnomani topib bog'lash.
  ///
  /// Backend `{linked, contract_number}` qaytaradi; bog'lanmasa `linked: false`.
  Future<(bool, String?)> linkContract({
    String? passportSeries,
    String? passportNumber,
    String? phone,
  }) async {
    final res = await _api.post<dynamic>(
      '/market/cabinet/my-home/link',
      data: {
        'passport_series': ?passportSeries,
        'passport_number': ?passportNumber,
        'phone': ?phone,
      },
    );
    final data = res.data;
    if (data is! Map) return (false, null);
    return (data['linked'] == true, data['contract_number']?.toString());
  }
}
