import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import 'auth_field.dart';
import 'auth_texts.dart';
import 'phone_field.dart';

/// Saytning `/forgot-password` sahifasi — `forgot-password.component.ts` dan 1:1.
///
/// Uch qadam: telefon → SMS kod → yangi parol, so'ng muvaffaqiyat ekrani. Kod ikkinchi qadamda
/// serverga yuborilmaydi — sayt uni faqat uzunligiga qarab o'tkazadi va haqiqiy tekshiruv
/// `reset-password` chaqiruvida bo'ladi.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { phone, code, password }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  _Step _step = _Step.phone;
  bool _loading = false;
  bool _success = false;
  bool _showPassword = false;

  int _resendIn = 0;
  Timer? _ticker;

  final _errors = <String, String>{};

  @override
  void dispose() {
    _ticker?.cancel();
    _phone.dispose();
    _code.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  int get _stepIndex => _Step.values.indexOf(_step);

  String get _stepDescription => switch (_step) {
    _Step.phone => AuthTexts.resetStepPhone,
    _Step.code => AuthTexts.resetStepCode,
    _Step.password => AuthTexts.resetStepPassword,
  };

  Future<void> _sendOtp() async {
    if (!isCompletePhone(_phone.text)) {
      setState(() => _errors['phone'] = AuthTexts.errorPhone);
      return;
    }
    setState(() {
      _loading = true;
      _errors.clear();
    });
    try {
      await context.read<AuthService>().sendOtp(
        phone: normalizePhone(_phone.text),
        purpose: 'reset',
      );
      if (!mounted) return;
      setState(() => _step = _Step.code);
      _startResendTimer();
    } on AuthException catch (e) {
      if (mounted) setState(() => _errors['general'] = e.message);
    } catch (_) {
      if (mounted) setState(() => _errors['general'] = AuthTexts.errorSendCode);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendIn > 0 || _loading) return;
    await _sendOtp();
  }

  void _startResendTimer() {
    _ticker?.cancel();
    setState(() => _resendIn = 60);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  /// Saytdagi `verifyCode()` — kod serverga yuborilmaydi, faqat uzunligi tekshiriladi.
  void _verifyCode() {
    if (_code.text.length != 6) {
      setState(() => _errors['code'] = AuthTexts.errorSmsCode);
      return;
    }
    setState(() {
      _errors.clear();
      _step = _Step.password;
    });
  }

  Future<void> _resetPassword() async {
    final errs = <String, String>{};
    if (_newPassword.text.length < 6) errs['password'] = AuthTexts.errorPasswordMin;
    if (_newPassword.text != _confirmPassword.text) {
      errs['confirmPassword'] = AuthTexts.errorPasswordMatch;
    }
    if (errs.isNotEmpty) {
      setState(() {
        _errors
          ..clear()
          ..addAll(errs);
      });
      return;
    }

    setState(() {
      _loading = true;
      _errors.clear();
    });
    try {
      await context.read<AuthService>().resetPassword(
        phone: normalizePhone(_phone.text),
        code: _code.text,
        newPassword: _newPassword.text,
      );
      if (mounted) setState(() => _success = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _errors['general'] = e.message);
    } catch (_) {
      if (mounted) setState(() => _errors['general'] = AuthTexts.resetError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream, // bg-cream
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24), // p-6
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448), // max-w-md
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _logo(theme),
                    const SizedBox(height: 40), // mb-10
                    if (!_success) ...[
                      _stepDots(),
                      const SizedBox(height: 32), // mb-8
                    ],
                    if (_success)
                      _successView(theme)
                    else ...[
                      Text(
                        AuthTexts.resetTitle,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontSize: 30, // text-3xl
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 8), // mb-2
                      Text(
                        _stepDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.dark.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 32), // mb-8
                      if (_errors['general'] case final message?) ...[
                        _errorBox(theme, message),
                        const SizedBox(height: 24), // mb-6
                      ],
                      ...switch (_step) {
                        _Step.phone => _phoneStep(theme),
                        _Step.code => _codeStep(theme),
                        _Step.password => _passwordStep(theme),
                      },
                      const SizedBox(height: 32), // mt-8
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            AuthTexts.backToLogin,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 15, // text-[15px]
                              fontWeight: FontWeight.w600,
                              color: AppColors.olive,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logo(ThemeData theme) => Pressable(
    onTap: () => context.go('/'),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.asset('assets/images/logo.jpg', width: 44, height: 44, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12), // gap-3
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Business',
                style: TextStyle(color: AppColors.olive),
              ),
              const TextSpan(text: 'HOME'),
            ],
          ),
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: 24, // text-2xl
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
      ],
    ),
  );

  /// Uch raqamli doira va ular orasidagi chiziq; o'tilgan qadam belgisi bilan.
  Widget _stepDots() => Row(
    children: [
      for (var i = 0; i < 3; i++) ...[
        Container(
          width: 32, // w-8 h-8
          height: 32,
          decoration: BoxDecoration(
            color: _stepIndex >= i ? AppColors.olive : const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _stepIndex > i
                ? const SiteIcon(SiteIcons.check, size: 16, strokeWidth: 3, color: Colors.white)
                : Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 14, // text-sm
                      fontWeight: FontWeight.w600,
                      color: _stepIndex >= i ? Colors.white : AppColors.dark.withValues(alpha: 0.4),
                    ),
                  ),
          ),
        ),
        if (i < 2)
          Container(
            width: 32, // w-8
            height: 2, // h-0.5
            margin: const EdgeInsets.symmetric(horizontal: 8), // gap-2
            color: _stepIndex > i ? AppColors.olive : const Color(0xFFE5E7EB),
          ),
      ],
    ],
  );

  Widget _errorBox(ThemeData theme, String message) => Container(
    padding: const EdgeInsets.all(16), // p-4
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: const Color(0xFFFECACA)),
    ),
    child: Row(
      children: [
        const SiteIcon(SiteIcons.xCircle, size: 20, color: Color(0xFFEF4444)),
        const SizedBox(width: 12), // gap-3
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFFDC2626)),
          ),
        ),
      ],
    ),
  );

  List<Widget> _phoneStep(ThemeData theme) => [
    AuthLabel(AuthTexts.phone),
    AuthField(
      controller: _phone,
      hint: AuthTexts.phoneHint,
      prefix: '+998',
      keyboardType: TextInputType.phone,
      inputFormatters: uzPhoneFormatters(),
      hasError: _errors.containsKey('phone'),
      onChanged: (_) {
        if (_errors.remove('phone') != null) setState(() {});
      },
    ),
    if (_errors['phone'] case final message?) AuthFieldError(message),
    const SizedBox(height: 20), // space-y-5
    _primaryButton(theme, AuthTexts.sendSms, _sendOtp),
  ];

  List<Widget> _codeStep(ThemeData theme) => [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AuthTexts.smsCode,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
        GestureDetector(
          onTap: _resendOtp,
          child: Text(
            _resendIn > 0
                ? '${AuthTexts.resendPrefix}$_resendIn${AuthTexts.sec}'
                : AuthTexts.resendCode,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12, // text-xs
              fontWeight: FontWeight.w500,
              color: _resendIn > 0 ? AppColors.dark.withValues(alpha: 0.3) : AppColors.olive,
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 8), // mb-2
    AuthField(
      controller: _code,
      hint: AuthTexts.codePlaceholder,
      keyboardType: TextInputType.number,
      digitsOnly: true,
      maxLength: 6,
      hasError: _errors.containsKey('code'),
      textAlign: TextAlign.center,
      // `text-[15px] tracking-[0.3em] text-center font-semibold`
      textStyle: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 4.5,
        color: AppColors.dark,
      ),
      onChanged: (_) {
        if (_errors.remove('code') != null) setState(() {});
      },
    ),
    if (_errors['code'] case final message?) AuthFieldError(message),
    const SizedBox(height: 8), // mt-2
    Text(
      AuthTexts.smsHint,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 12,
        color: AppColors.dark.withValues(alpha: 0.4),
      ),
    ),
    const SizedBox(height: 20), // space-y-5
    _primaryButton(theme, AuthTexts.verifyCode, () async => _verifyCode()),
  ];

  List<Widget> _passwordStep(ThemeData theme) => [
    AuthLabel(AuthTexts.newPassword),
    AuthField(
      controller: _newPassword,
      hint: AuthTexts.createPasswordPlaceholder,
      obscure: !_showPassword,
      hasError: _errors.containsKey('password'),
      suffix: GestureDetector(
        onTap: () => setState(() => _showPassword = !_showPassword),
        child: SiteIcon(
          _showPassword ? SiteIcons.eyeOff : SiteIcons.eye,
          size: 20,
          color: AppColors.dark.withValues(alpha: 0.3),
        ),
      ),
      onChanged: (_) {
        if (_errors.remove('password') != null) setState(() {});
      },
    ),
    if (_errors['password'] case final message?) AuthFieldError(message),
    const SizedBox(height: 20), // space-y-5
    AuthLabel(AuthTexts.confirmPassword),
    AuthField(
      controller: _confirmPassword,
      hint: AuthTexts.confirmPasswordPlaceholder,
      obscure: !_showPassword,
      hasError: _errors.containsKey('confirmPassword'),
      onChanged: (_) {
        if (_errors.remove('confirmPassword') != null) setState(() {});
      },
    ),
    if (_errors['confirmPassword'] case final message?) AuthFieldError(message),
    const SizedBox(height: 20),
    _primaryButton(theme, AuthTexts.resetButton, _resetPassword),
  ];

  Widget _successView(ThemeData theme) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 32), // py-8
      child: Column(
        children: [
          Container(
            width: 64, // w-16 h-16
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.olive.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SiteIcon(SiteIcons.check, size: 32, strokeWidth: 2.5, color: AppColors.olive),
            ),
          ),
          const SizedBox(height: 16), // mb-4
          Text(
            AuthTexts.resetSuccess,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20, // text-xl
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8), // mb-2
          Text(
            AuthTexts.resetSuccessDesc,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24), // mb-6
          Pressable(
            onTap: () => context.go('/login'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), // px-8 py-3
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                AuthTexts.loginButton,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  /// `w-full py-3.5 bg-olive rounded-xl` — har uch qadamning asosiy tugmasi.
  Widget _primaryButton(ThemeData theme, String label, Future<void> Function() onTap) => Pressable(
    scale: 0.98,
    onTap: _loading ? null : () => onTap(),
    child: Opacity(
      opacity: _loading ? 0.6 : 1,
      child: Container(
        height: 52, // py-3.5
        decoration: BoxDecoration(
          color: AppColors.olive,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 8), // gap-2
            ],
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15, // text-[15px]
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
