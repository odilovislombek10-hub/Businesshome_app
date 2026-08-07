import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
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

  /// Restore the session on launch: if a stored token still resolves to an account, the user
  /// stays signed in; anything else (expired, revoked, account deleted) clears it silently.
  Future<void> restore() async {
    if (!await _api.isLoggedIn) return;

    // Ilova sovuq ishga tushganda bir vaqtda o'nlab so'rov ketadi va `me` shulardan biri sifatida
    // yiqilib qolishi mumkin. Bitta urinish bilan cheklansak, token joyida turgani holda ilova
    // butun sessiya davomida "kirilmagan" bo'lib qoladi — shuning uchun bir necha marta uriniladi.
    const delays = [Duration(seconds: 1), Duration(seconds: 3)];
    for (var attempt = 0; attempt <= delays.length; attempt++) {
      try {
        final res = await _api.get<dynamic>('$_base/me');
        if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
          _user = MarketUser.fromJson(res.data as Map<String, dynamic>);
          notifyListeners();
          return;
        }
        // 200 emas, lekin javob keldi — token yaroqsiz, tozalanadi.
        await logout();
        return;
      } on DioException catch (e) {
        // 401/403 — token haqiqatan ham yaroqsiz; qolgani (tarmoq, timeout) qayta uriniladi.
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          await logout();
          return;
        }
        if (attempt == delays.length) return; // urinishlar tugadi, token saqlanadi
        await Future<void>.delayed(delays[attempt]);
      }
    }
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
    _user = null;
    notifyListeners();
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
    _user = user;
    notifyListeners();
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
