import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

/// Port of the site's `CurrencyService`.
///
/// Prices are stored in UZS. The user can switch the display to USD, in which case everything is
/// divided by the rate the backend publishes at `/market/currency/rate`. UZS is formatted with
/// spaces between thousands — `toLocaleString('uz-UZ')` with commas replaced — and USD with the
/// English grouping, which is what `format()` does on the site.
class CurrencyService extends ChangeNotifier {
  CurrencyService._();
  static final CurrencyService instance = CurrencyService._();

  static const _currencyKey = 'market_currency';
  static const _rateKey = 'market_currency_rate';

  String _display = 'uzs';
  double _rate = 0;

  String get display => _display;
  String get symbol => _display == 'usd' ? '\$' : "so'm";

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_currencyKey);
    if (stored == 'uzs' || stored == 'usd') _display = stored!;
    _rate = prefs.getDouble(_rateKey) ?? 0;
    notifyListeners();
    unawaited(_refreshRate());
  }

  Future<void> setDisplay(String value) async {
    if (value != 'uzs' && value != 'usd') return;
    _display = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, value);
  }

  Future<void> _refreshRate() async {
    try {
      final res = await ApiClient.instance.get<dynamic>('/market/currency/rate');
      final data = res.data;
      final rate = data is Map ? (data['rate'] as num?)?.toDouble() : null;
      if (rate != null && rate > 0) {
        _rate = rate;
        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_rateKey, rate);
      }
    } catch (_) {
      // A stale or missing rate just means prices stay in UZS — not worth surfacing.
    }
  }

  /// Convert then group. [from] is the currency the amount is stored in.
  String format(num amount, {String from = 'uzs'}) {
    final value = _convert(amount.toDouble(), from);
    final rounded = value.round();
    // Group by thousands: spaces for UZS, commas for USD.
    final digits = rounded.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(_display == 'usd' ? ',' : ' ');
      buffer.write(digits[i]);
    }
    return '${rounded < 0 ? '-' : ''}$buffer';
  }

  /// Amount with the currency symbol, the pairing every price on the site prints.
  String formatWithSymbol(num amount, {String from = 'uzs'}) =>
      '${format(amount, from: from)} $symbol';

  double _convert(double amount, String from) {
    // No published rate means no conversion is possible; show the stored amount as-is.
    if (_rate <= 0 || _display == from) return amount;
    return from == 'uzs' ? amount / _rate : amount * _rate;
  }
}

/// Local `unawaited` so this file does not pull in dart:async for one call.
void unawaited(Future<void> future) {
  future.ignore();
}
