import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _dio.get<T>(path, queryParameters: query);

  /// [headers] carries the per-request extras the API expects, such as the AI assistant's
  /// `X-Anon-Key` for signed-out visitors.
  Future<Response<T>> post<T>(String path, {Object? data, Map<String, String>? headers}) =>
      _dio.post<T>(
        path,
        data: data,
        options: Options(headers: headers),
      );

  Future<Response<T>> put<T>(String path, {Object? data}) => _dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}
