import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/models/market_user.dart';
import '../../core/models/region.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/regions_service.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/site_header.dart';
import 'auth_field.dart';
import 'auth_texts.dart';
import 'phone_field.dart';

/// Saytning `/register` sahifasi — `features/auth/register/register.component.ts` dan 1:1.
///
/// Besh qadamli sehrgar: rol → ism va parol → hudud → telefon va rozilik → SMS kodi.
/// Katta ekrandagi chap ustun (rasm va shior) `hidden lg:flex` — mobil ko'rinishda yo'q.
///
/// **Ataylab farq qilgan ikki joy:**
/// 1. Tuman faqat viloyatda tuman ro'yxati bo'lsa majburiy. Sayt tumanlarni kodga yozilgan
///    ro'yxatdan oladi, ilova esa `/market/regions` dan — u hozircha bo'sh `districts` qaytaradi,
///    shuning uchun saytdagidek "tuman majburiy" qilinsa ro'yxatdan o'tib bo'lmaydi.
/// 2. Tugma matni: shablonda `t('common.next')`, lekin bu kalit `uz.ts` da yo'q.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _scroll = ScrollController();

  final _fullName = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();

  // Quruvchi (yuridik shaxs) maydonlari — faqat `role == developer` da ko'rinadi.
  final _companyName = TextEditingController();
  final _inn = TextEditingController();
  final _mfo = TextEditingController();
  final _oked = TextEditingController();
  final _vatRegCode = TextEditingController();
  final _contactPerson = TextEditingController();
  final _companyPhone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  String _position = AuthTexts.positions.first;

  int _step = 1;
  MarketRole _role = MarketRole.user;
  String _region = '';
  String _district = '';
  bool _agreeTerms = false;
  bool _showPassword = false;

  List<Region> _regions = const [];
  bool _loading = false;
  bool _sendingCode = false;

  /// `resendTimer` — kodni qayta yuborishgacha qolgan soniya.
  int _resendIn = 0;
  Timer? _ticker;

  /// Saytdagi `errors` signali: maydon nomi → xato matni.
  final _errors = <String, String>{};

  String get _lang => LanguageService.instance.code;

  @override
  void initState() {
    super.initState();
    RegionsService.instance.regions().then((regions) {
      if (mounted) setState(() => _regions = regions);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scroll.dispose();
    for (final c in [
      _fullName,
      _password,
      _phone,
      _code,
      _companyName,
      _inn,
      _mfo,
      _oked,
      _vatRegCode,
      _contactPerson,
      _companyPhone,
      _email,
      _address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Region? get _selectedRegion {
    for (final r in _regions) {
      if (r.value == _region) return r;
    }
    return null;
  }

  bool get _isDeveloper => _role == MarketRole.developer;

  void _clearError(String field) {
    if (_errors.remove(field) != null) setState(() {});
  }

  /// Saytdagi `validateStep` — har qadamdan o'tishdan oldin.
  bool _validateStep(int step) {
    final errs = <String, String>{};
    switch (step) {
      case 1:
        break; // rol doim tanlangan (standart — foydalanuvchi)
      case 2:
        if (_fullName.text.trim().length < 2) errs['fullName'] = AuthTexts.errorFullName;
        if (_password.text.length < 6) errs['password'] = AuthTexts.errorPasswordShort;
        if (_isDeveloper) {
          if (_companyName.text.trim().isEmpty) {
            errs['companyName'] = AuthTexts.errorCompanyName;
          }
          if (_contactPerson.text.trim().isEmpty) {
            errs['contactPerson'] = AuthTexts.errorContactPerson;
          }
        }
      case 3:
        if (_region.isEmpty) errs['region'] = AuthTexts.errorRegion;
        // Sayt tumanni doim talab qiladi; bizda ro'yxat bo'sh bo'lsa talab qilib bo'lmaydi.
        if (_district.isEmpty && (_selectedRegion?.districts.isNotEmpty ?? false)) {
          errs['district'] = AuthTexts.errorDistrict;
        }
      case 4:
        if (!isCompletePhone(_phone.text)) errs['phone'] = AuthTexts.errorPhoneDigits;
        if (!_agreeTerms) errs['agreeTerms'] = AuthTexts.errorTerms;
      case 5:
        if (_code.text.length != 6) errs['code'] = AuthTexts.errorCode;
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(errs);
    });
    return errs.isEmpty;
  }

  void _prevStep() {
    if (_step <= 1) return;
    setState(() {
      _step--;
      _errors.clear();
    });
    _scroll.jumpTo(0);
  }

  Future<void> _nextStep() async {
    if (!_validateStep(_step)) return;

    if (_step < 4) {
      setState(() => _step++);
      _scroll.jumpTo(0);
      return;
    }
    if (_step == 4) return _sendOtpAndProceed();
    await _completeRegistration();
  }

  Future<void> _sendOtpAndProceed() async {
    setState(() {
      _sendingCode = true;
      _errors.clear();
    });
    try {
      await context.read<AuthService>().sendOtp(
        phone: normalizePhone(_phone.text),
        purpose: 'register',
        role: _role,
      );
      if (!mounted) return;
      setState(() => _step = 5);
      _scroll.jumpTo(0);
      _startResendTimer();
    } on DioException catch (e) {
      if (mounted) setState(() => _errors.addAll(_otpError(e)));
    } catch (_) {
      if (mounted) setState(() => _errors['general'] = AuthTexts.errorSmsFailed);
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  /// Saytdagi `sendOtpAndProceed` xato ajratishi: 409 — raqam band, 429 — juda ko'p urinish.
  Map<String, String> _otpError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final detail = data is Map && data['detail'] != null ? data['detail'].toString() : '';
    if (e.response == null) return {'general': AuthTexts.connectionError};
    if (status == 409) return {'phone': AuthTexts.errorPhoneTaken};
    if (status == 429) return {'general': detail.isEmpty ? AuthTexts.errorTooMany : detail};
    return {'general': detail.isEmpty ? AuthTexts.errorSmsFailed : detail};
  }

  Future<void> _resendCode() async {
    if (_resendIn > 0 || _sendingCode) return;
    setState(() => _sendingCode = true);
    try {
      await context.read<AuthService>().sendOtp(
        phone: normalizePhone(_phone.text),
        purpose: 'register',
        role: _role,
      );
      if (mounted) _startResendTimer();
    } catch (_) {
      if (mounted) setState(() => _errors['general'] = AuthTexts.errorSmsFailed);
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
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

  Future<void> _completeRegistration() async {
    setState(() {
      _loading = true;
      _errors.clear();
    });
    try {
      await context.read<AuthService>().register(
        phone: normalizePhone(_phone.text),
        code: _code.text,
        fullName: _fullName.text.trim(),
        password: _password.text,
        region: _region,
        district: _district,
        role: _role,
        developer: _isDeveloper ? _developerPayload() : null,
      );
      if (mounted) context.go('/');
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final detail = data is Map && data['detail'] != null ? data['detail'].toString() : '';
      setState(() {
        if (e.response == null) {
          _errors['general'] = AuthTexts.connectionError;
        } else if (status == 400) {
          _errors['code'] = detail.isEmpty ? AuthTexts.errorCodeWrong : detail;
        } else if (status == 409) {
          _errors['general'] = AuthTexts.errorPhoneTaken;
        } else {
          _errors['general'] = detail.isEmpty ? AuthTexts.registerError : detail;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _errors['general'] = e is AuthException ? e.message : AuthTexts.registerError,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Saytdagi `registerData.developer` — bo'sh maydonlar umuman yuborilmaydi.
  Map<String, dynamic> _developerPayload() {
    String? trimmed(TextEditingController c) {
      final value = c.text.trim();
      return value.isEmpty ? null : value;
    }

    return {
      'person_type': 'legal',
      'company_name': _companyName.text.trim(),
      'inn': ?trimmed(_inn),
      'mfo': ?trimmed(_mfo),
      'oked': ?trimmed(_oked),
      'vat_reg_code': ?trimmed(_vatRegCode),
      'company_phone': ?trimmed(_companyPhone),
      'contact_person': _contactPerson.text.trim(),
      'contact_position': _position,
      'address': ?trimmed(_address),
      'email': ?trimmed(_email),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream, // bg-cream
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(24), // p-6
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448), // max-w-md
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _body()),
                  ),
                ),
              ],
            ),
            // `absolute top-4 right-4`
            Positioned(top: 16, right: 16, child: _languageButton()),
          ],
        ),
      ),
    );
  }

  List<Widget> _body() {
    final theme = Theme.of(context);
    return [
      // Saytda bu sahifada orqaga tugmasi yo'q (brauzerniki bor), ilovada har bir
      // sahifada bo'lishi kerak.
      const HeaderBackButton(onBar: AppColors.dark),
      const SizedBox(height: 20),
      _logo(theme),
      const SizedBox(height: 32), // mb-8
      _stepIndicator(theme),
      const SizedBox(height: 24), // mb-6
      if (_errors['general'] case final message?) ...[
        _errorBox(theme, message),
        const SizedBox(height: 16), // mb-4
      ],
      ...switch (_step) {
        1 => _stepRole(theme),
        2 => _stepNameAndPassword(theme),
        3 => _stepRegion(theme),
        4 => _stepPhone(theme),
        _ => _stepCode(theme),
      },
      const SizedBox(height: 24), // mt-6
      _actions(theme),
      const SizedBox(height: 24), // mt-6
      Center(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${AuthTexts.hasAccount} '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text(
                    AuthTexts.loginLink,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.olive,
                    ),
                  ),
                ),
              ),
            ],
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 15, // text-[15px]
            color: AppColors.dark.withValues(alpha: 0.6),
          ),
        ),
      ),
    ];
  }

  /// `lg:hidden` mobil logotip — 44px rasm va "BusinessHOME".
  Widget _logo(ThemeData theme) => Pressable(
    onTap: () => context.go('/'),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
          child: Image.asset(
            'assets/images/logo.jpg',
            width: 44, // h-11 w-11
            height: 44,
            fit: BoxFit.cover,
          ),
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

  Widget _stepIndicator(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${AuthTexts.stepOf} $_step / 5',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
          Text(
            AuthTexts.stepTitles[_step - 1],
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12, // text-xs
              fontWeight: FontWeight.w600,
              color: AppColors.olive,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8), // mb-2
      Row(
        children: [
          for (var s = 1; s <= 5; s++) ...[
            if (s > 1) const SizedBox(width: 6), // gap-1.5
            Expanded(
              child: Container(
                height: 6, // h-1.5
                decoration: BoxDecoration(
                  color: s <= _step ? AppColors.olive : const Color(0xFFE5E7EB), // bg-gray-200
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ],
        ],
      ),
    ],
  );

  Widget _errorBox(ThemeData theme, String message) => Container(
    padding: const EdgeInsets.all(12), // p-3
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2), // bg-red-50
      borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
      border: Border.all(color: const Color(0xFFFECACA)), // border-red-200
    ),
    child: Row(
      children: [
        const SiteIcon(SiteIcons.xCircle, size: 20, color: Color(0xFFDC2626)),
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

  // ── 1-qadam: hisob turi ────────────────────────────────────────────────────

  List<Widget> _stepRole(ThemeData theme) => [
    _stepHeading(theme, AuthTexts.stepTitles[0], AuthTexts.roleStepDesc),
    LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2; // grid-cols-2 gap-3
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (wire, label, icon) in AuthTexts.roles)
              SizedBox(width: width, child: _roleCard(theme, wire, label, icon)),
          ],
        );
      },
    ),
  ];

  Widget _roleCard(ThemeData theme, String wire, String label, String icon) {
    final role = MarketRole.parse(wire);
    final active = _role == role;
    return Pressable(
      onTap: () => setState(() => _role = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // px-4 py-5
        decoration: BoxDecoration(
          color: active ? AppColors.olive.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
          border: Border.all(
            color: active ? AppColors.olive : const Color(0xFFE5E7EB),
            width: 2, // border-2
          ),
          boxShadow: active
              ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4))]
              : null,
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 30)), // text-3xl
            const SizedBox(height: 8), // gap-2
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: active ? AppColors.olive : AppColors.dark.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2-qadam: ism va parol ──────────────────────────────────────────────────

  List<Widget> _stepNameAndPassword(ThemeData theme) => [
    _stepHeading(theme, AuthTexts.stepTitles[1], AuthTexts.nameStepDesc),
    AuthLabel(AuthTexts.fullName),
    AuthField(
      controller: _fullName,
      hint: AuthTexts.fullNamePlaceholder,
      hasError: _errors.containsKey('fullName'),
      onChanged: (_) => _clearError('fullName'),
    ),
    if (_errors['fullName'] case final message?) AuthFieldError(message),
    const SizedBox(height: 16), // space-y-4
    AuthLabel(AuthTexts.password),
    AuthField(
      controller: _password,
      hint: AuthTexts.passwordMinPlaceholder,
      obscure: !_showPassword,
      hasError: _errors.containsKey('password'),
      onChanged: (_) => _clearError('password'),
      suffix: GestureDetector(
        onTap: () => setState(() => _showPassword = !_showPassword),
        child: SiteIcon(
          _showPassword ? SiteIcons.eyeOff : SiteIcons.eye,
          size: 20,
          color: AppColors.dark.withValues(alpha: 0.4),
        ),
      ),
    ),
    if (_errors['password'] case final message?) AuthFieldError(message),
    if (_isDeveloper) ..._developerForm(theme),
  ];

  List<Widget> _developerForm(ThemeData theme) => [
    const SizedBox(height: 24), // pt-4 mt-2
    const Divider(height: 1, color: Color(0xFFE5E7EB)),
    const SizedBox(height: 16),
    Text(
      AuthTexts.companyInfo,
      style: theme.textTheme.titleMedium?.copyWith(
        fontSize: 16, // text-base
        fontWeight: FontWeight.w700,
        color: AppColors.dark,
      ),
    ),
    const SizedBox(height: 16),

    AuthLabel(AuthTexts.companyName, required: true),
    AuthField(
      controller: _companyName,
      hint: AuthTexts.companyNamePlaceholder,
      hasError: _errors.containsKey('companyName'),
      onChanged: (_) => _clearError('companyName'),
    ),
    if (_errors['companyName'] case final message?) AuthFieldError(message),
    const SizedBox(height: 16),

    _pair(
      theme,
      leftLabel: AuthTexts.inn,
      left: AuthField(controller: _inn, hint: '301234567', maxLength: 9, digitsOnly: true),
      rightLabel: AuthTexts.mfo,
      right: AuthField(controller: _mfo, hint: '00450', maxLength: 5, digitsOnly: true),
    ),
    const SizedBox(height: 16),
    _pair(
      theme,
      leftLabel: AuthTexts.oked,
      left: AuthField(controller: _oked, hint: '41200'),
      rightLabel: AuthTexts.vatRegCode,
      right: AuthField(controller: _vatRegCode, hint: '302...'),
    ),
    const SizedBox(height: 16),

    AuthLabel(AuthTexts.contactPerson, required: true),
    AuthField(
      controller: _contactPerson,
      hint: AuthTexts.contactPersonPlaceholder,
      hasError: _errors.containsKey('contactPerson'),
      onChanged: (_) => _clearError('contactPerson'),
    ),
    if (_errors['contactPerson'] case final message?) AuthFieldError(message),
    const SizedBox(height: 16),

    AuthLabel(AuthTexts.position),
    _Dropdown(
      value: _position,
      items: [for (final p in AuthTexts.positions) (p, p)],
      onChanged: (value) => setState(() => _position = value),
    ),
    const SizedBox(height: 16),

    _pair(
      theme,
      leftLabel: AuthTexts.companyPhone,
      left: AuthField(controller: _companyPhone, hint: '+998 90 123 45 67'),
      rightLabel: AuthTexts.email,
      right: AuthField(controller: _email, hint: 'info@kompaniya.uz'),
    ),
    const SizedBox(height: 16),

    AuthLabel(AuthTexts.legalAddress),
    AuthField(controller: _address, hint: AuthTexts.legalAddressPlaceholder, lines: 2),
    const SizedBox(height: 16),

    // `bg-amber-50 border-amber-200` — admin tasdig'i haqida ogohlantirish.
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AuthTexts.adminApprovalTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF92400E), // text-amber-800
            ),
          ),
          const SizedBox(height: 4), // mt-1
          Text(
            AuthTexts.adminApprovalDesc,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: const Color(0xFF92400E),
            ),
          ),
        ],
      ),
    ),
  ];

  /// `grid grid-cols-2 gap-3` — yonma-yon ikki maydon.
  Widget _pair(
    ThemeData theme, {
    required String leftLabel,
    required Widget left,
    required String rightLabel,
    required Widget right,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [AuthLabel(leftLabel), left],
        ),
      ),
      const SizedBox(width: 12), // gap-3
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [AuthLabel(rightLabel), right],
        ),
      ),
    ],
  );

  // ── 3-qadam: hudud ─────────────────────────────────────────────────────────

  List<Widget> _stepRegion(ThemeData theme) {
    final districts = _selectedRegion?.districts ?? const <District>[];
    return [
      _stepHeading(theme, AuthTexts.stepTitles[2], AuthTexts.regionStepDesc),
      AuthLabel(AuthTexts.region),
      _Dropdown(
        value: _region,
        hasError: _errors.containsKey('region'),
        items: [('', AuthTexts.selectRegion), for (final r in _regions) (r.value, r.label)],
        // Viloyat almashsa tuman tozalanadi — saytdagi `handleRegionSelect`.
        onChanged: (value) => setState(() {
          _region = value;
          _district = '';
          _errors.remove('region');
          _errors.remove('district');
        }),
      ),
      if (_errors['region'] case final message?) AuthFieldError(message),
      const SizedBox(height: 16),
      AuthLabel(AuthTexts.district),
      _Dropdown(
        value: _district,
        enabled: _region.isNotEmpty && districts.isNotEmpty,
        hasError: _errors.containsKey('district'),
        items: [('', AuthTexts.selectDistrict), for (final d in districts) (d.value, d.label)],
        onChanged: (value) => setState(() {
          _district = value;
          _errors.remove('district');
        }),
      ),
      if (_errors['district'] case final message?) AuthFieldError(message),
    ];
  }

  // ── 4-qadam: telefon va rozilik ────────────────────────────────────────────

  List<Widget> _stepPhone(ThemeData theme) => [
    _stepHeading(theme, AuthTexts.phone, AuthTexts.codeWillBeSent),
    AuthLabel(AuthTexts.phone),
    AuthField(
      controller: _phone,
      hint: AuthTexts.phoneHint,
      prefix: '+998',
      keyboardType: TextInputType.phone,
      inputFormatters: uzPhoneFormatters(),
      hasError: _errors.containsKey('phone'),
      onChanged: (_) => _clearError('phone'),
    ),
    if (_errors['phone'] case final message?) AuthFieldError(message),
    const SizedBox(height: 16),
    _termsBox(theme),
    if (_errors['agreeTerms'] case final message?) ...[
      const SizedBox(height: 8),
      Row(
        children: [
          const Text('☝', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8), // gap-2
          Text(
            message,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDC2626), // text-red-600
            ),
          ),
        ],
      ),
    ],
  ];

  Widget _termsBox(ThemeData theme) {
    final invalid = _errors.containsKey('agreeTerms');
    return Container(
      padding: const EdgeInsets.all(12), // p-3
      decoration: BoxDecoration(
        color: invalid ? const Color(0xFFFEF2F2) : AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: invalid ? const Color(0xFFF87171) : AppColors.borderLight,
          width: invalid ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() {
              _agreeTerms = !_agreeTerms;
              _errors.remove('agreeTerms');
            }),
            child: Container(
              margin: const EdgeInsets.only(top: 2), // mt-0.5
              width: 24, // w-6 h-6
              height: 24,
              decoration: BoxDecoration(
                color: _agreeTerms
                    ? AppColors.olive
                    : (invalid ? const Color(0xFFFEE2E2) : Colors.white),
                borderRadius: BorderRadius.circular(6), // rounded-md
                border: Border.all(
                  color: _agreeTerms
                      ? AppColors.olive
                      : (invalid ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF)),
                  width: 2,
                ),
              ),
              child: _agreeTerms
                  ? const Center(child: SiteIcon(SiteIcons.check, size: 14, color: Colors.white))
                  : null,
            ),
          ),
          const SizedBox(width: 12), // gap-3
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${AuthTexts.agreeWith} '),
                  TextSpan(
                    text: AuthTexts.termsLink,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.olive),
                  ),
                  TextSpan(text: AuthTexts.and),
                  TextSpan(
                    text: AuthTexts.privacyLink,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.olive),
                  ),
                ],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5-qadam: SMS kodi ──────────────────────────────────────────────────────

  List<Widget> _stepCode(ThemeData theme) => [
    Text(
      AuthTexts.verificationCode,
      style: theme.textTheme.displaySmall?.copyWith(
        fontSize: 24, // text-2xl
        fontWeight: FontWeight.w700,
        color: AppColors.dark,
      ),
    ),
    const SizedBox(height: 16),
    Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '+998${_phone.text.replaceAll(' ', '')} ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.dark.withValues(alpha: 0.8),
            ),
          ),
          TextSpan(text: AuthTexts.sentTo),
        ],
      ),
      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.6)),
    ),
    const SizedBox(height: 16),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AuthTexts.smsCodeLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
        GestureDetector(
          onTap: _resendCode,
          child: Text(
            switch ((_resendIn, _sendingCode)) {
              (final left, _) when left > 0 => '${AuthTexts.resendIn} ${left}s',
              (_, true) => AuthTexts.resending,
              _ => AuthTexts.resend,
            },
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _resendIn > 0 || _sendingCode
                  ? AppColors.dark.withValues(alpha: 0.3)
                  : AppColors.olive,
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
      onChanged: (_) => _clearError('code'),
      // `text-2xl tracking-[0.4em] text-center font-bold`
      textStyle: theme.textTheme.displaySmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 9.6,
        color: AppColors.dark,
      ),
      textAlign: TextAlign.center,
    ),
    if (_errors['code'] case final message?) AuthFieldError(message),
  ];

  // ── umumiy qismlar ─────────────────────────────────────────────────────────

  Widget _stepHeading(ThemeData theme, String title, String description) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: theme.textTheme.displaySmall?.copyWith(
          fontSize: 24, // text-2xl
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
      const SizedBox(height: 16), // space-y-4
      Text(
        description,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.6)),
      ),
      const SizedBox(height: 16),
    ],
  );

  Widget _actions(ThemeData theme) {
    final busy = _loading || _sendingCode;
    return Row(
      children: [
        if (_step > 1) ...[
          Pressable(
            scale: 0.98,
            onTap: busy ? null : _prevStep,
            child: Container(
              height: 52, // py-3.5
              padding: const EdgeInsets.symmetric(horizontal: 20), // px-5
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
              ),
              child: Text(
                AuthTexts.back,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12), // gap-3
        ],
        Expanded(
          child: Pressable(
            scale: 0.98,
            onTap: busy ? null : _nextStep,
            child: Opacity(
              opacity: busy ? 0.6 : 1,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.olive,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (busy) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 8), // gap-2
                    ],
                    Text(
                      switch (_step) {
                        1 || 2 || 3 => AuthTexts.next,
                        4 => AuthTexts.sendCode,
                        _ => _loading ? AuthTexts.verifying : AuthTexts.verifyAndLogin,
                      },
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
          ),
        ),
      ],
    );
  }

  /// `h-9 px-3 rounded-xl bg-white border shadow-sm`
  Widget _languageButton() {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      onSelected: (code) => setState(() => LanguageService.instance.set(code)),
      offset: const Offset(0, 40),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      itemBuilder: (context) => [
        for (final (code, label, flag) in AuthTexts.languages)
          PopupMenuItem(
            value: code,
            height: 40,
            child: Text(
              '$flag $label',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: _lang == code ? FontWeight.w700 : FontWeight.w400,
                color: _lang == code ? AppColors.olive : AppColors.dark,
              ),
            ),
          ),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SiteIcon(SiteIcons.globe, size: 16, color: AppColors.dark),
            const SizedBox(width: 6),
            Text(
              _lang.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(width: 6),
            const SiteIcon(SiteIcons.chevronDown, size: 12, color: AppColors.dark),
          ],
        ),
      ),
    );
  }
}

/// Shablondagi `<select>` — o'chirilganda `bg-gray-100 text-dark/30`.
class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.hasError = false,
  });

  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 52, // py-3.5
      padding: const EdgeInsets.symmetric(horizontal: 16), // px-4
      decoration: BoxDecoration(
        color: enabled ? Colors.white : AppColors.surfaceMutedLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: hasError ? const Color(0xFFF87171) : const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((o) => o.$1 == value) ? value : items.first.$1,
          isExpanded: true,
          icon: const SiteIcon(SiteIcons.chevronDown, size: 16),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            color: enabled ? AppColors.dark : AppColors.dark.withValues(alpha: 0.3),
          ),
          items: [
            for (final (v, label) in items)
              DropdownMenuItem(
                value: v,
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: enabled ? (v) => onChanged(v ?? '') : null,
        ),
      ),
    );
  }
}
