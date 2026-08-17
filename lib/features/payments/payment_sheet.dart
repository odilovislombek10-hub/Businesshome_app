import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import 'payment_fields.dart';
import 'paylov_repository.dart';

/// To'lov oynasi — saytdagi `app-payment-modal`.
///
/// To'rt qadam: saqlangan kartani tanlash → (yoki) yangi karta → OTP → chek. Telefonda pastdan
/// chiqadi (`items-end`, `rounded-t-3xl`).
///
/// `true` qaytarsa to'lov o'tgan — chaqiruvchi ma'lumotni qayta yuklashi kerak.
class PaymentSheet extends StatefulWidget {
  const PaymentSheet({
    super.key,
    required this.amount,
    required this.outstanding,
    this.devCode,
    this.contractId,
  });

  /// Taklif qilinadigan summa — keyingi to'lov miqdori.
  final num amount;

  /// Shartnoma bo'yicha qoldiq — summa maydoni ostida ko'rsatiladi.
  final num outstanding;
  final String? devCode;
  final int? contractId;

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

enum _Step { select, card, otp, success }

class _PaymentSheetState extends State<PaymentSheet> {
  final _repo = const PaylovRepository();

  late final Future<List<SavedCard>> _cards = _repo.cards();
  late final _amount = TextEditingController(text: widget.amount.round().toString());
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _otp = TextEditingController();

  _Step _step = _Step.select;
  int? _selectedCardId;
  bool _loading = false;
  String _error = '';
  PayResult? _result;

  @override
  void dispose() {
    _amount.dispose();
    _number.dispose();
    _expiry.dispose();
    _otp.dispose();
    super.dispose();
  }

  num get _amountValue => num.tryParse(_amount.text.replaceAll(' ', '')) ?? 0;

  Future<void> _start({int? cardId, String? cardNumber, String? expireDate}) async {
    if (_amountValue <= 0) {
      setState(() => _error = "To'lov summasini kiriting");
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final result = await _repo.pay(
        amount: _amountValue,
        cardId: cardId,
        cardNumber: cardNumber,
        expireDate: expireDate,
        devCode: widget.devCode,
        contractId: widget.contractId,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _step = result.needsOtp ? _Step.otp : _Step.success;
      });
    } on PaylovException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = "To'lovni amalga oshirib bo'lmadi");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitOtp() async {
    final txnId = _result?.txnId;
    if (txnId == null) return;
    if (_otp.text.length < 4) {
      setState(() => _error = 'OTP kodini kiriting');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final result = await _repo.confirmPayment(txnId: txnId, otp: _otp.text);
      if (!mounted) return;
      setState(() {
        _result = result;
        _step = _Step.success;
      });
    } on PaylovException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Tasdiqlashda xatolik');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // px-6 py-4
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _step == _Step.success ? "To'lov qabul qilindi" : "To'lovni amalga oshirish",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18, // text-lg
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                Pressable(
                  onTap: () => Navigator.of(context).pop(_step == _Step.success),
                  child: const SiteIcon(SiteIcons.close, size: 20),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: [
                if (_result?.mode case final mode? when mode != 'production') ...[
                  PaymentModeBadge(mode),
                  const SizedBox(height: 20),
                ],
                ...switch (_step) {
                  _Step.select => _selectStep(theme),
                  _Step.card => _cardStep(theme),
                  _Step.otp => _otpStep(theme),
                  _Step.success => _successStep(theme),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Summa maydoni — saytda katta raqam bilan, ostida qoldiq.
  Widget _amountBox(ThemeData theme) => Container(
    padding: const EdgeInsets.all(16), // p-4
    decoration: BoxDecoration(
      color: AppColors.olive.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.olive.withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "To'lov summasi",
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.dark.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 30, // text-3xl
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                "so'm",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Qoldiq: ${formatNumber(widget.outstanding)} so'm",
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            color: AppColors.dark.withValues(alpha: 0.4),
          ),
        ),
      ],
    ),
  );

  List<Widget> _selectStep(ThemeData theme) => [
    _amountBox(theme),
    const SizedBox(height: 20), // space-y-5
    FutureBuilder<List<SavedCard>>(
      future: _cards,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceMutedLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          );
        }
        final cards = snapshot.data ?? const <SavedCard>[];
        // Saqlangan karta bo'lmasa darrov yangi karta formasi ochiladi.
        if (cards.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _step == _Step.select) setState(() => _step = _Step.card);
          });
          return const SizedBox.shrink();
        }
        _selectedCardId ??= cards.first.id;
        return Column(
          children: [
            for (final card in cards) ...[
              _cardOption(theme, card),
              const SizedBox(height: 8), // space-y-2
            ],
            Pressable(
              onTap: () => setState(() {
                _step = _Step.card;
                _error = '';
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
                ),
                child: Row(
                  children: [
                    const SiteIcon(SiteIcons.wallet, size: 20),
                    const SizedBox(width: 12), // gap-3
                    Text(
                      "Yangi karta bilan to'lash",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.dark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
    if (_error.isNotEmpty) ...[const SizedBox(height: 16), PaymentError(_error)],
    const SizedBox(height: 20),
    _primaryButton(
      theme,
      _loading ? "To'lanmoqda…" : "${formatNumber(_amountValue)} so'm to'lash",
      onTap: _loading || _selectedCardId == null ? null : () => _start(cardId: _selectedCardId),
    ),
  ];

  Widget _cardOption(ThemeData theme, SavedCard card) {
    final selected = _selectedCardId == card.id;
    return Pressable(
      onTap: () => setState(() => _selectedCardId = card.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.dark, AppColors.olive],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          // `ring-2 ring-cream` — tanlangan karta ajralib turadi.
          border: Border.all(color: selected ? AppColors.cream : Colors.transparent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                if (selected) const SiteIcon(SiteIcons.check, size: 16, color: AppColors.cream),
              ],
            ),
            if (card.label case final label?) ...[
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.masked,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Text(
                  card.expireDate,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _cardStep(ThemeData theme) => [
    _amountBox(theme),
    const SizedBox(height: 20),
    PaymentField(
      controller: _number,
      label: 'Karta raqami',
      hint: '8600 0000 0000 0000',
      keyboardType: TextInputType.number,
      formatters: [CardNumberFormatter()],
      letterSpacing: 1.5,
    ),
    const SizedBox(height: 16),
    PaymentField(
      controller: _expiry,
      label: 'Amal muddati',
      hint: 'MM/YY',
      keyboardType: TextInputType.number,
      formatters: [ExpiryFormatter()],
      textAlign: TextAlign.center,
      letterSpacing: 2,
      width: 128,
    ),
    if (_error.isNotEmpty) ...[const SizedBox(height: 16), PaymentError(_error)],
    const SizedBox(height: 20),
    _primaryButton(
      theme,
      _loading ? 'Yuborilmoqda…' : "${formatNumber(_amountValue)} so'm to'lash",
      onTap: _loading
          ? null
          : () {
              final digits = _number.text.replaceAll(' ', '');
              if (digits.length < 16) {
                setState(() => _error = "Karta raqamini to'liq kiriting");
                return;
              }
              if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(_expiry.text)) {
                setState(() => _error = 'Amal muddati MM/YY formatida');
                return;
              }
              _start(cardNumber: digits, expireDate: _expiry.text);
            },
    ),
    const SizedBox(height: 8),
    Center(
      child: GestureDetector(
        onTap: () => setState(() {
          _step = _Step.select;
          _error = '';
        }),
        child: Text(
          'Saqlangan kartalarga qaytish',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.5)),
        ),
      ),
    ),
    const SizedBox(height: 8),
    Center(
      child: Text(
        "To'lov Paylov orqali xavfsiz amalga oshiriladi",
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 12,
          color: AppColors.dark.withValues(alpha: 0.4),
        ),
      ),
    ),
  ];

  List<Widget> _otpStep(ThemeData theme) => [
    Center(
      child: Column(
        children: [
          Text(
            'Tasdiqlash kodi yuborildi',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
          if (_result?.otpPhone case final phone?) ...[
            const SizedBox(height: 2),
            Text(
              phone,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ],
        ],
      ),
    ),
    if (_result?.simOtp case final code?) ...[
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.olive.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.olive.withValues(alpha: 0.15)),
        ),
        child: Center(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Test kodi: '),
                TextSpan(
                  text: code,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    ],
    const SizedBox(height: 16),
    PaymentField(
      controller: _otp,
      hint: '——————',
      keyboardType: TextInputType.number,
      formatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 6,
      textAlign: TextAlign.center,
      fontSize: 24,
      letterSpacing: 9.6,
    ),
    if (_error.isNotEmpty) ...[const SizedBox(height: 16), PaymentError(_error)],
    const SizedBox(height: 20),
    _primaryButton(
      theme,
      _loading ? 'Tasdiqlanmoqda…' : "Tasdiqlash va to'lash",
      onTap: _loading ? null : _submitOtp,
    ),
    const SizedBox(height: 8),
    Center(
      child: GestureDetector(
        onTap: () => setState(() {
          _step = _Step.card;
          _error = '';
        }),
        child: Text(
          'Orqaga',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.5)),
        ),
      ),
    ),
  ];

  List<Widget> _successStep(ThemeData theme) {
    final result = _result;
    return [
      Center(
        child: Column(
          children: [
            Container(
              width: 64, // w-16 h-16
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
              child: const Center(
                child: SiteIcon(
                  SiteIcons.check,
                  size: 28,
                  strokeWidth: 2.5,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(height: 16), // mb-4
            Text(
              "${formatNumber(result?.chargeAmount ?? result?.amount ?? 0)} so'm",
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20, // text-xl
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "To'lov shartnomangizga qo'shildi",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (result?.paidAt case final paidAt?) _receiptRow(theme, 'Sana va vaqt', paidAt),
            _receiptRow(theme, "To'lov raqami", '${result?.txnId ?? ''}'),
            if (result?.cardLast4 case final last4?)
              _receiptRow(
                theme,
                'Pul yechilgan karta',
                '${result?.bankName != null ? '${result!.bankName} · ' : ''}•• $last4',
              ),
            if (result?.payerName case final payer?) _receiptRow(theme, "To'lovchi", payer),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _primaryButton(theme, 'Yopish', onTap: () => Navigator.of(context).pop(true)),
    ];
  }

  Widget _receiptRow(ThemeData theme, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // px-4 py-2.5
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.borderLight)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.dark,
          ),
        ),
      ],
    ),
  );

  Widget _primaryButton(ThemeData theme, String label, {VoidCallback? onTap}) => Pressable(
    onTap: onTap,
    child: Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14), // py-3.5
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.olive,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}
