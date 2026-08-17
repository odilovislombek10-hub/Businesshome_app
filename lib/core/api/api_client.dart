import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'response_cache.dart';

/// Single entry point to the BusinessHome market API.
///
/// The backend already serves the website at businesshome.uz, so the app talks to exactly the same
/// endpoints the Angular marketplace uses — no separate backend, no duplicated business logic.
///
/// Auth: market users get a JWT with `type=market` (phone + password, or phone + SMS OTP). The
/// token is attached to every request and survives restarts in SharedPreferences.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// The site's `environment.apiUrl` is `/api`, and paths below it carry their own prefix —
  /// `/market/...` for the marketplace and `/viewer/...` for new-build projects. Keeping the base
  /// at `/api` (rather than baking in `/market`) is what lets both be reached.
  static const String baseUrl = 'https://businesshome.uz/api';
  static const String _tokenKey = 'market_token';
  static const String _refreshKey = 'market_refresh_token';

  late final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 30),
            // Don't throw on 4xx: the API answers with structured errors (e.g. {"detail": "..."}) that
            // the UI shows to the user, and turning those into exceptions loses the message.
            validateStatus: (status) => status != null && status < 500,
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await _readToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
          ),
        );

  String? _cachedToken;

  Future<String?> _readToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    return _cachedToken = prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token, {String? refreshToken}) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (refreshToken != null) await prefs.setString(_refreshKey, refreshToken);
  }

  Future<String?> readRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
  }

  Future<bool> get isLoggedIn async => (await _readToken())?.isNotEmpty ?? false;

  // ── kesh va so'rovlar oqimi ────────────────────────────────────────────────

  /// Shu muddat ichidagi nusxa "yangi" hisoblanadi — tarmoqqa umuman chiqilmaydi.
  static const _freshFor = Duration(minutes: 5);

  /// Bundan eskisi ishlatilmaydi (faqat tarmoq yiqilsa zaxira sifatida).
  static const _keepFor = Duration(days: 7);

  /// Bir vaqtda ochiladigan ulanishlar soni. Bosh sahifa o'n oltita so'rovni birdan yuboradi;
  /// hammasini bir zumda otish serverning rate-limit qoidasini qo'zg'atadi va IP bloklanadi.
  static const _maxConcurrent = 5;

  int _active = 0;
  final _waiting = <Completer<void>>[];

  /// Ayni damda fonda yangilanayotgan kalitlar — bir xil so'rov ikki marta ketmasligi uchun.
  final _revalidating = <String>{};

  Future<T> _gated<T>(Future<T> Function() send) async {
    if (_active >= _maxConcurrent) {
      final waiter = Completer<void>();
      _waiting.add(waiter);
      await waiter.future;
    }
    _active++;
    try {
      return await send();
    } finally {
      _active--;
      if (_waiting.isNotEmpty) _waiting.removeAt(0).complete();
    }
  }

  /// Faqat ochiq ma'lumot keshlanadi. Kabinet va auth javoblari foydalanuvchiga bog'liq va
  /// o'zgarishi bilanoq ko'rinishi kerak (e'lon o'chirilgach ro'yxat eskirib qolmasin).
  static bool _isCacheable(String path) =>
      !path.startsWith('/market/cabinet') &&
      !path.startsWith('/market/auth') &&
      !path.startsWith('/market/ai');

  Response<T> _cachedResponse<T>(String path, Map<String, dynamic>? query, CachedResponse hit) =>
      Response<T>(
        requestOptions: RequestOptions(path: path, queryParameters: query, baseUrl: baseUrl),
        statusCode: 200,
        data: hit.body as T,
      );

  /// [refresh] — keshni chetlab o'tish (masalan "tortib yangilash").
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    bool refresh = false,
  }) async {
    if (!_isCacheable(path)) {
      return _gated(() => _dio.get<T>(path, queryParameters: query));
    }

    final key = ResponseCache.keyFor(path, query);
    final cached = refresh ? null : await ResponseCache.instance.read(key);

    if (cached != null && cached.age < _keepFor) {
      // Eskirgan bo'lsa ham darrov ko'rsatiladi, yangisi fonda olinadi.
      if (cached.age >= _freshFor) unawaited(_revalidate(path, query, key));
      return _cachedResponse<T>(path, query, cached);
    }

    try {
      final res = await _gated(() => _dio.get<T>(path, queryParameters: query));
      if (res.statusCode == 200) {
        unawaited(ResponseCache.instance.write(key, res.data, at: DateTime.now()));
      }
      return res;
    } on DioException {
      // Tarmoq yo'q yoki server javob bermayapti — eski nusxa bo'sh ekrandan yaxshiroq.
      final fallback = cached ?? await ResponseCache.instance.read(key);
      if (fallback != null) return _cachedResponse<T>(path, query, fallback);
      rethrow;
    }
  }

  Future<void> _revalidate(String path, Map<String, dynamic>? query, String key) async {
    if (!_revalidating.add(key)) return;
    try {
      final res = await _gated(() => _dio.get<dynamic>(path, queryParameters: query));
      if (res.statusCode == 200) {
        await ResponseCache.instance.write(key, res.data, at: DateTime.now());
      }
    } catch (_) {
      // Fon yangilanishi jimgina yiqiladi — ekranda eski ma'lumot qolaveradi.
    } finally {
      _revalidating.remove(key);
    }
  }

  /// [headers] carries the per-request extras the API expects, such as the AI assistant's
  /// `X-Anon-Key` for signed-out visitors.
  Future<Response<T>> post<T>(String path, {Object? data, Map<String, String>? headers}) => _gated(
    () => _dio.post<T>(
      path,
      data: data,
      options: Options(headers: headers),
    ),
  );

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _gated(() => _dio.put<T>(path, data: data));

  /// [data] — ba'zi endpointlar o'chirish uchun tanada qiymat kutadi (portfolio rasmi).
  Future<Response<T>> delete<T>(String path, {Object? data}) =>
      _gated(() => _dio.delete<T>(path, data: data));
}
