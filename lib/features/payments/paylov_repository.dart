import '../../core/api/api_client.dart';

/// `/api/market/payments/*` — Paylov orqali to'lov va saqlangan kartalar.
///
/// Backend uch rejimda ishlaydi: `production`, `sandbox` va `simulator`. Oxirgi ikkisida pul
/// yechilmaydi va OTP javob bilan birga qaytadi (`sim_otp`) — sayt uni ekranda ko'rsatadi.
class PaylovRepository {
  const PaylovRepository();

  ApiClient get _api => ApiClient.instance;

  Future<List<SavedCard>> cards() async {
    final res = await _api.get<dynamic>('/market/payments/cards');
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(SavedCard.fromJson).toList();
  }

  /// Karta qo'shishning birinchi qadami — javobda tasdiqlash uchun `card_id` keladi.
  ///
  /// `already_active` bo'lsa karta Paylov'da avval faollashtirilgan va OTP so'ralmaydi.
  Future<AddCardResult> addCard({
    required String cardNumber,
    required String expireDate,
    String? label,
  }) async {
    final res = await _api.post<dynamic>(
      '/market/payments/cards/add',
      data: {
        'card_number': cardNumber,
        'expire_date': expireDate,
        'label': label == null || label.isEmpty ? null : label,
      },
    );
    _ensureOk(res.statusCode, res.data);
    final data = res.data as Map<String, dynamic>;
    return AddCardResult(
      cardId: (data['card_id'] as num?)?.toInt() ?? 0,
      otpPhone: data['otp_phone']?.toString(),
      simOtp: data['sim_otp']?.toString(),
      alreadyActive: data['already_active'] == true,
    );
  }

  Future<void> confirmCard({required int cardId, required String otp}) async {
    final res = await _api.post<dynamic>(
      '/market/payments/cards/add/confirm',
      data: {'card_id': cardId, 'otp': otp},
    );
    _ensureOk(res.statusCode, res.data);
  }

  Future<void> deleteCard(int id) async {
    await _api.delete<dynamic>('/market/payments/cards/$id');
  }

  /// To'lovni boshlash — saqlangan karta (`cardId`) yoki yangi karta ma'lumoti bilan.
  Future<PayResult> pay({
    required num amount,
    int? cardId,
    String? cardNumber,
    String? expireDate,
    String? devCode,
    int? contractId,
  }) async {
    final res = await _api.post<dynamic>(
      '/market/payments/pay',
      data: {
        'amount': amount,
        'card_id': ?cardId,
        'card_number': ?cardNumber,
        'expire_date': ?expireDate,
        'dev_code': ?devCode,
        'contract_id': ?contractId,
      },
    );
    _ensureOk(res.statusCode, res.data);
    return PayResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PayResult> confirmPayment({required int txnId, required String otp}) async {
    final res = await _api.post<dynamic>(
      '/market/payments/confirm',
      data: {'txn_id': txnId, 'otp': otp},
    );
    _ensureOk(res.statusCode, res.data);
    return PayResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// Backend xatoni `{"detail": "..."}` bilan qaytaradi; `ApiClient` 4xx da otmaydi.
  void _ensureOk(int? status, dynamic data) {
    if (status != null && status >= 200 && status < 300 && data is Map<String, dynamic>) return;
    final detail = data is Map ? data['detail']?.toString() : null;
    throw PaylovException(detail ?? 'Xatolik yuz berdi');
  }
}

class PaylovException implements Exception {
  const PaylovException(this.message);
  final String message;

  @override
  String toString() => message;
}

class SavedCard {
  const SavedCard({
    required this.id,
    required this.last4,
    required this.expireDate,
    required this.isDefault,
    this.label,
    this.bin,
    this.bankName,
    this.vendor,
  });

  final int id;
  final String last4;
  final String expireDate;
  final bool isDefault;
  final String? label;
  final String? bin;
  final String? bankName;
  final String? vendor;

  /// Saytdagi `maskedNumber` — `8600 ••** **** 1234`.
  String get masked {
    final prefix = (bin ?? '').length >= 4 ? bin!.substring(0, 4) : '••••';
    return '$prefix ••** **** $last4';
  }

  String get title => bankName ?? vendor ?? 'Karta';

  factory SavedCard.fromJson(Map<String, dynamic> json) => SavedCard(
    id: (json['id'] as num?)?.toInt() ?? 0,
    last4: json['card_last4']?.toString() ?? '',
    expireDate: json['expire_date']?.toString() ?? '',
    isDefault: json['is_default'] == true,
    label: _text(json['label']),
    bin: _text(json['card_bin']),
    bankName: _text(json['bank_name']),
    vendor: _text(json['vendor']),
  );
}

class AddCardResult {
  const AddCardResult({
    required this.cardId,
    this.otpPhone,
    this.simOtp,
    this.alreadyActive = false,
  });

  final int cardId;
  final String? otpPhone;

  /// Test rejimida OTP javob bilan qaytadi va ekranda ko'rsatiladi.
  final String? simOtp;
  final bool alreadyActive;
}

class PayResult {
  const PayResult({
    required this.txnId,
    required this.status,
    required this.amount,
    this.otpPhone,
    this.simOtp,
    this.mode,
    this.chargeAmount,
    this.cardLast4,
    this.bankName,
    this.payerName,
    this.paidAt,
    this.receiptUrl,
  });

  final int txnId;

  /// `waiting_otp` bo'lsa tasdiqlash kerak; `success` — to'lov o'tdi.
  final String status;
  final num amount;
  final String? otpPhone;
  final String? simOtp;

  /// `production` bo'lmasa ekranda "pul yechilmaydi" ogohlantirishi chiqadi.
  final String? mode;
  final num? chargeAmount;
  final String? cardLast4;
  final String? bankName;
  final String? payerName;
  final String? paidAt;
  final String? receiptUrl;

  bool get needsOtp => status != 'success' && status != 'paid';

  factory PayResult.fromJson(Map<String, dynamic> json) => PayResult(
    txnId: (json['txn_id'] as num?)?.toInt() ?? 0,
    status: json['status']?.toString() ?? '',
    amount: (json['amount'] as num?) ?? 0,
    otpPhone: _text(json['otp_phone']),
    simOtp: _text(json['sim_otp']),
    mode: _text(json['mode']),
    chargeAmount: json['charge_amount'] as num?,
    cardLast4: _text(json['card_last4']),
    bankName: _text(json['bank_name']),
    payerName: _text(json['payer_name']),
    paidAt: _text(json['paid_at']),
    receiptUrl: _text(json['receipt_url']),
  );
}

String? _text(dynamic value) {
  final s = value?.toString().trim();
  return s == null || s.isEmpty || s == 'null' ? null : s;
}
