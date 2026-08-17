import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/response_cache.dart';
import '../models/market_user.dart';

/// Raised when the API answers a 4xx with a message meant for the user.
///
/// The client is configured not to throw on 4xx (structured errors carry the text the UI shows),
/// so the repositories turn those bodies into this instead of a bare `DioException`.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Port of the site's `AuthService` — phone + password, phone + SMS OTP, registration and
/// password reset, all against `/api/market/auth/*`.
class AuthService extends ChangeNotifier {
  AuthService();

  static const _base = '/market/auth';

  final _api = ApiClient.instance;

  MarketUser? _user;
  MarketUser? get user => _user;
  bool get isLoggedIn => _user != null;

  /// Saqlangan hisob — saytdagi `localStorage['bh_user']` ning o'rni.
  static const _userKey = 'market_user';

  /// Ilova ochilganda sessiyani tiklaydi.
  ///
  /// Saytdagi `loadFromStorage()` foydalanuvchini **darrov** localStorage'dan oladi va faqat
  /// keyin serverdan tekshiradi. Ilovada ham shunday: aks holda sekin tarmoqda `/auth/me`
  /// javobi kelguncha odam "kirilmagan" bo'lib ko'rinadi va ilova qayta ochilganda har safar
  /// login so'raydi.
  Future<void> restore() async {
    if (!await _api.isLoggedIn) return;

    // 1) Diskdagi nusxa — ekran shu zahoti to'g'ri holatda chiziladi.
    final stored = await _readStoredUser();
    if (stored != null) {
      _user = stored;
      notifyListeners();
    }

    // 2) Fonda tekshirish. Faqat 401/403 da chiqariladi — tarmoq xatosi sessiyani buzmaydi.
    unawaited(_verifySession(hadStoredUser: stored != null));
  }

  Future<void> _verifySession({required bool hadStoredUser}) async {
    const delays = [Duration(seconds: 2), Duration(seconds: 5)];
    for (var attempt = 0; attempt <= delays.length; attempt++) {
      try {
        final res = await _api.get<dynamic>('$_base/me');
        if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
          await _acceptUser(MarketUser.fromJson(res.data as Map<String, dynamic>));
          return;
        }
        if (res.statusCode == 401 || res.statusCode == 403) {
          await logout();
          return;
        }
        return; // boshqa javob — hozircha tegilmaydi
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          await logout();
          return;
        }
        if (attempt == delays.length) return; // tarmoq yiqildi — saqlangan hisob qoladi
        await Future<void>.delayed(delays[attempt]);
      }
    }
  }

  Future<MarketUser?> _readStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return MarketUser.fromJson(decoded);
    } catch (_) {}
    return null;
  }

  Future<void> _acceptUser(MarketUser user) async {
    _user = user;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Phone + password. Pass [role] when the number holds more than one account and the user has
  /// already picked which to enter (see [availableRoles]).
  Future<MarketUser> login({
    required String phone,
    required String password,
    MarketRole? role,
  }) async {
    final res = await _api.post<dynamic>(
      '$_base/login',
      data: {'phone': phone, 'password': password, if (role != null) 'role': role.wire},
    );
    return _acceptAuth(res);
  }

  /// The roles this phone+password pair can sign in as. The site calls this first and only shows
  /// a picker when more than one comes back.
  Future<List<AvailableRole>> availableRoles({
    required String phone,
    required String password,
  }) async {
    final res = await _api.post<dynamic>(
      '$_base/login/available-roles',
      data: {'phone': phone, 'password': password},
    );
    final data = _ok(res);
    final roles = data is Map<String, dynamic> ? data['roles'] : null;
    if (roles is! List) return const [];
    return roles.whereType<Map<String, dynamic>>().map(AvailableRole.fromJson).toList();
  }

  /// Send an SMS code. [purpose] is one of `register`, `login`, `reset` — the backend keys the
  /// stored code by it, so a registration code will not verify a password reset.
  Future<void> sendOtp({
    required String phone,
    String purpose = 'register',
    MarketRole? role,
  }) async {
    final res = await _api.post<dynamic>(
      '$_base/send-otp',
      data: {'phone': phone, 'purpose': purpose, if (role != null) 'role': role.wire},
    );
    _ok(res);
  }

  Future<void> verifyOtp({
    required String phone,
    required String code,
    String purpose = 'register',
  }) async {
    final res = await _api.post<dynamic>(
      '$_base/verify-otp',
      data: {'phone': phone, 'code': code, 'purpose': purpose},
    );
    _ok(res);
  }

  /// Sign in with an SMS code instead of a password.
  Future<MarketUser> loginWithOtp({required String phone, required String code}) async {
    final res = await _api.post<dynamic>('$_base/login-otp', data: {'phone': phone, 'code': code});
    return _acceptAuth(res);
  }

  /// Create an account. The code must come from a `purpose: 'register'` OTP.
  Future<MarketUser> register({
    required String phone,
    required String code,
    required String fullName,
    String? password,
    String? region,
    String? district,
    MarketRole role = MarketRole.user,
    Map<String, dynamic>? developer,
  }) async {
    final res = await _api.post<dynamic>(
      '$_base/register',
      data: {
        'phone': phone,
        'code': code,
        'full_name': fullName,
        'role': role.wire,
        if (password != null && password.isNotEmpty) 'password': password,
        'region': ?region,
        'district': ?district,
        // Quruvchi rolida kompaniya yuridik ma'lumoti ham ketadi — backend uni
        // `developers` jadvaliga `is_approved=false` bilan yozadi.
        if (role == MarketRole.developer && developer != null) 'developer': developer,
      },
    );
    return _acceptAuth(res);
  }

  /// Set a new password after a `purpose: 'reset'` code has been issued.
  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    final res = await _api.post<dynamic>(
      '$_base/reset-password',
      data: {'phone': phone, 'code': code, 'new_password': newPassword},
    );
    _ok(res);
  }

  Future<void> logout() async {
    await _api.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    // Keshda ochiq ma'lumot yotadi, lekin boshqa hisob bilan kirilganda eskisi ko'rinmasin.
    await ResponseCache.instance.clear();
    _user = null;
    notifyListeners();
  }

  /// Ism, viloyat va tumanni yangilaydi — `PUT /market/auth/profile`.
  ///
  /// Backend yangilangan foydalanuvchini qaytaradi; shu javob bilan `user` almashtiriladi,
  /// shuning uchun kabinet va header darrov yangi ismni ko'rsatadi.
  Future<void> updateProfile({String? fullName, String? region, String? district}) async {
    final res = await _api.put<dynamic>(
      '$_base/profile',
      data: {'full_name': ?fullName, 'region': ?region, 'district': ?district},
    );
    final data = res.data;
    if (res.statusCode == 200 && data is Map<String, dynamic>) {
      await _acceptUser(MarketUser.fromJson(data));
      return;
    }
    throw AuthException(_message(data) ?? "Profilni saqlab bo'lmadi");
  }

  /// `PUT /market/auth/change-password`. Joriy parol noto'g'ri bo'lsa backend 400 qaytaradi.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _api.put<dynamic>(
      '$_base/change-password',
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
    if (res.statusCode == 200) return;
    throw AuthException(_message(res.data) ?? "Parolni o'zgartirib bo'lmadi");
  }

  /// `POST /market/auth/avatar` — multipart `file` (jpg/png/webp, 5 MB gacha).
  ///
  /// Backend yangilangan foydalanuvchini qaytaradi, shuning uchun javob bilan `user` almashtiriladi
  /// va yangi rasm kabinet banneri bilan header'da darrov ko'rinadi.
  Future<void> uploadAvatar(String path) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(path)});
    final res = await _api.post<dynamic>('$_base/avatar', data: form);
    final data = res.data;
    if (res.statusCode == 200 && data is Map<String, dynamic>) {
      await _acceptUser(MarketUser.fromJson(data));
      return;
    }
    throw AuthException(_message(data) ?? "Rasmni yuklab bo'lmadi");
  }

  /// Backend xatoni `{"detail": "..."}` ko'rinishida qaytaradi.
  static String? _message(dynamic data) {
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    return null;
  }

  /// Store the tokens from an `AuthResponse` and publish the signed-in user.
  Future<MarketUser> _acceptAuth(Response<dynamic> res) async {
    final data = _ok(res);
    if (data is! Map<String, dynamic>) {
      throw const AuthException('Serverdan kutilmagan javob keldi');
    }
    await _api.saveToken(
      data['token']?.toString() ?? '',
      refreshToken: data['refresh_token']?.toString(),
    );
    final user = MarketUser.fromJson(data['user'] as Map<String, dynamic>);
    await _acceptUser(user);
    return user;
  }

  /// Turn a non-2xx body into an [AuthException] carrying the backend's own message.
  Object? _ok(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return res.data;
    final data = res.data;
    final detail = data is Map ? data['detail'] : null;
    throw AuthException(detail?.toString() ?? 'Xatolik yuz berdi ($status)');
  }
}
