import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import 'payment_fields.dart';
import 'paylov_repository.dart';

/// "To'lov kartalarim" — saytdagi `app-saved-cards`.
///
/// Kartalar zaytun-qora gradientli plastik ko'rinishida chiziladi (sayt ataylab bank ranglariga
/// taqlid qilmaydi). "+" tugmasi ikki qadamli qo'shish formasini ochadi: karta ma'lumoti → OTP.
class SavedCardsSection extends StatefulWidget {
  const SavedCardsSection({super.key});

  @override
  State<SavedCardsSection> createState() => _SavedCardsSectionState();
}

enum _AddStep { closed, card, otp }

class _SavedCardsSectionState extends State<SavedCardsSection> {
  final _repo = const PaylovRepository();

  late Future<List<SavedCard>> _future = _repo.cards();

  _AddStep _step = _AddStep.closed;
  bool _submitting = false;
  String _error = '';

  final _label = TextEditingController();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _otp = TextEditingController();

  int? _pendingCardId;
  String? _otpPhone;
  String? _simOtp;
  int? _copiedId;

  @override
  void dispose() {
    _label.dispose();
    _number.dispose();
    _expiry.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _repo.cards());

  void _openAdd() {
    _label.clear();
    _number.clear();
    _expiry.clear();
    _otp.clear();
    setState(() {
      _error = '';
      _step = _AddStep.card;
    });
  }

  Future<void> _submitCard() async {
    final digits = _number.text.replaceAll(' ', '');
    if (digits.length < 16) {
      setState(() => _error = "Karta raqamini to'liq kiriting");
      return;
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(_expiry.text)) {
      setState(() => _error = 'Amal muddati MM/YY formatida');
      return;
    }
    setState(() {
      _submitting = true;
      _error = '';
    });
    try {
      final result = await _repo.addCard(
        cardNumber: digits,
        expireDate: _expiry.text,
        label: _label.text.trim(),
      );
      if (!mounted) return;
      // Karta Paylov'da avval faollashtirilgan bo'lsa OTP so'ralmaydi.
      if (result.alreadyActive) {
        setState(() => _step = _AddStep.closed);
        _reload();
        return;
      }
      setState(() {
        _pendingCardId = result.cardId;
        _otpPhone = result.otpPhone;
        _simOtp = result.simOtp;
        _step = _AddStep.otp;
      });
    } on PaylovException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = "Kartani qo'shib bo'lmadi");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitOtp() async {
    if (_pendingCardId == null) return;
    if (_otp.text.length < 4) {
      setState(() => _error = 'OTP kodini kiriting');
      return;
    }
    setState(() {
      _submitting = true;
      _error = '';
    });
    try {
      await _repo.confirmCard(cardId: _pendingCardId!, otp: _otp.text);
      if (!mounted) return;
      setState(() => _step = _AddStep.closed);
      _reload();
    } on PaylovException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Tasdiqlashda xatolik');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _remove(SavedCard card) async {
    final name = card.label ?? '•• •• •• ${card.last4}';
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('"$name" kartani o\'chirasizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("O'chirish", style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (agreed != true) return;
    try {
      await _repo.deleteCard(card.id);
      _reload();
    } catch (_) {}
  }

  Future<void> _copy(SavedCard card) async {
    await Clipboard.setData(ClipboardData(text: card.masked));
    if (!mounted) return;
    setState(() => _copiedId = card.id);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _copiedId = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20), // p-5
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl), // rounded-3xl
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "To'lov kartalarim",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16, // text-base
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
              if (_step == _AddStep.closed)
                Pressable(
                  onTap: _openAdd,
                  child: Container(
                    width: 36, // w-9 h-9
                    height: 36,
                    decoration: const BoxDecoration(color: AppColors.olive, shape: BoxShape.circle),
                    child: const Center(
                      child: Text(
                        '+',
                        style: TextStyle(fontSize: 20, color: Colors.white, height: 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16), // mb-4
          FutureBuilder<List<SavedCard>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 112, // h-28
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMutedLight,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                );
              }
              final cards = snapshot.data ?? const <SavedCard>[];
              if (cards.isEmpty && _step == _AddStep.closed) {
                return Text(
                  'Hali kartangiz yo\'q — "+" tugmasi bilan qo\'shing, keyingi to\'lovlarda tez '
                  "tanlab to'lay olasiz.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                );
              }
              return Column(
                children: [
                  for (final card in cards) ...[
                    _cardTile(theme, card),
                    const SizedBox(height: 12), // gap-3
                  ],
                ],
              );
            },
          ),
          if (_step == _AddStep.card) _addCardForm(theme),
          if (_step == _AddStep.otp) _otpForm(theme),
        ],
      ),
    );
  }

  /// `bg-gradient-to-br from-dark to-olive` — brend ranglari, bank rangiga taqlid qilinmaydi.
  Widget _cardTile(ThemeData theme, SavedCard card) => Stack(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16), // p-4
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.dark, AppColors.olive],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, // w-8 h-8
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Center(
                    child: SiteIcon(SiteIcons.wallet, size: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8), // gap-2
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
                if (card.isDefault)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SiteIcon(SiteIcons.check, size: 14, color: Colors.white),
                  ),
                Pressable(
                  onTap: () => _remove(card),
                  child: SiteIcon(
                    SiteIcons.trash,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // mb-4
            if (card.label case final label?) ...[
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4), // mb-1
            ],
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _copy(card),
                    child: Text(
                      card.masked,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        letterSpacing: 0.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
                Text(
                  card.expireDate,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      if (_copiedId == card.id)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x66000000),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Center(
              child: Text(
                'Nusxalandi ✓',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _addCardForm(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16), // mt-4 pt-4
      const Divider(height: 1, color: AppColors.borderLight),
      const SizedBox(height: 16),
      PaymentField(
        controller: _label,
        label: 'Karta nomi (ixtiyoriy)',
        hint: 'Masalan: Ish kartam',
        maxLength: 50,
      ),
      const SizedBox(height: 12), // space-y-3
      PaymentField(
        controller: _number,
        label: 'Karta raqami',
        hint: '8600 0000 0000 0000',
        keyboardType: TextInputType.number,
        formatters: [CardNumberFormatter()],
        letterSpacing: 1.5,
      ),
      const SizedBox(height: 12),
      PaymentField(
        controller: _expiry,
        label: 'Amal muddati',
        hint: 'MM/YY',
        keyboardType: TextInputType.number,
        formatters: [ExpiryFormatter()],
        textAlign: TextAlign.center,
        letterSpacing: 2,
        width: 128, // w-32
      ),
      if (_error.isNotEmpty) ...[const SizedBox(height: 12), PaymentError(_error)],
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _button(
              theme,
              'Bekor qilish',
              outlined: true,
              onTap: () => setState(() {
                _step = _AddStep.closed;
                _error = '';
              }),
            ),
          ),
          const SizedBox(width: 8), // gap-2
          Expanded(
            child: _button(
              theme,
              _submitting ? 'Yuborilmoqda…' : 'Davom etish',
              onTap: _submitting ? null : _submitCard,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _otpForm(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      const Divider(height: 1, color: AppColors.borderLight),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Tasdiqlash kodi yuborildi '),
            if (_otpPhone case final phone?)
              TextSpan(
                text: phone,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.dark),
              ),
          ],
        ),
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.6)),
      ),
      if (_simOtp case final code?) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
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
      const SizedBox(height: 12),
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
      if (_error.isNotEmpty) ...[const SizedBox(height: 12), PaymentError(_error)],
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _button(
              theme,
              'Orqaga',
              outlined: true,
              onTap: () => setState(() {
                _step = _AddStep.card;
                _error = '';
              }),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _button(
              theme,
              _submitting ? 'Tasdiqlanmoqda…' : 'Tasdiqlash va saqlash',
              onTap: _submitting ? null : _submitOtp,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _button(ThemeData theme, String label, {VoidCallback? onTap, bool outlined = false}) =>
      Pressable(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.6 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // px-4 py-2.5
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: outlined ? Colors.white : AppColors.olive,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: outlined ? Border.all(color: AppColors.borderLight) : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: outlined ? FontWeight.w500 : FontWeight.w600,
                color: outlined ? AppColors.dark : Colors.white,
              ),
            ),
          ),
        ),
      );
}
