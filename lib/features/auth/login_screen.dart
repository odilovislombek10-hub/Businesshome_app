import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/language_service.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/site_header.dart';
import 'auth_texts.dart';
import 'phone_field.dart';
import 'social_button.dart';

/// Saytning `/login` sahifasi — `features/auth/login/login.component.ts` dan 1:1.
///
/// Katta ekranda sayt ikkiga bo'linadi (chapda forma, o'ngda rasm); mobil ko'rinishda o'ng
/// tomon `hidden lg:block` bilan yashiringan, shuning uchun bu yerda faqat forma bor.
///
/// Saytda kirish **faqat telefon + parol** orqali: SMS kod bilan kirish ham, rol tanlash ham
/// bu sahifada yo'q.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();

  bool _showPassword = false;
  bool _loading = false;
  String? _socialLoading;

  // Saytdagi `errors` signali — uchta alohida xato satri.
  String? _generalError;
  String? _phoneError;
  String? _passwordError;

  /// Saytdagi til tanlagichi. Ilova hozircha faqat o'zbekcha, tanlov faqat ko'rinishda qoladi.
  String get _lang => LanguageService.instance.code;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Saytdagi `validate()` — telefon to'liq to'qqiz xona, parol kamida olti belgi.
  bool _validate() {
    final phoneError = isCompletePhone(_phone.text) ? null : AuthTexts.errorPhone;
    final passwordError = _password.text.length >= 6 ? null : AuthTexts.errorPassword;
    setState(() {
      _phoneError = phoneError;
      _passwordError = passwordError;
    });
    return phoneError == null && passwordError == null;
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_validate()) return;

    setState(() {
      _loading = true;
      _generalError = null;
    });
    try {
      await context.read<AuthService>().login(
        phone: normalizePhone(_phone.text),
        password: _password.text,
      );
      if (mounted) context.go('/');
    } on DioException catch (e) {
      // Saytda har qanday xato "telefon yoki parol noto'g'ri" ga aylanadi. Ilovada bu xavfli:
      // internet uzilganda ham xuddi shu matn chiqadi va odam parolini o'zgartira boshlaydi.
      // Shuning uchun javobi umuman kelmagan xato alohida ajratildi.
      final noResponse = e.response == null;
      if (mounted) {
        setState(
          () => _generalError = noResponse ? AuthTexts.connectionError : AuthTexts.loginError,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _generalError = AuthTexts.loginError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Saytda provayder sahifasiga to'liq yo'naltirish bo'ladi; ilovada tashqi brauzer ochiladi.
  Future<void> _social(String provider) async {
    if (_socialLoading != null) return;
    setState(() {
      _socialLoading = provider;
      _generalError = null;
    });
    final url = Uri.parse('https://businesshome.uz/api/market/social/$provider/authorize');
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    setState(() {
      _socialLoading = null;
      if (!opened) _generalError = AuthTexts.loginError;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 40), // px-6 py-10
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400), // max-w-[400px]
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _form()),
                ),
              ),
            ),
            // `absolute top-5 right-5`
            Positioned(top: 20, right: 20, child: _languageButton(context)),
          ],
        ),
      ),
    );
  }

  List<Widget> _form() {
    final theme = Theme.of(context);
    return [
      // Saytda bu sahifada orqaga tugmasi yo'q (brauzerniki bor), ilovada har bir
      // sahifada bo'lishi kerak.
      const HeaderBackButton(onBar: AppColors.dark),
      const SizedBox(height: 20),
      _logo(theme),
      const SizedBox(height: 48), // mb-12
      Text(
        AuthTexts.loginTitle,
        style: theme.textTheme.displaySmall?.copyWith(
          fontSize: 30, // text-3xl
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
      const SizedBox(height: 32), // mb-8
      if (_generalError case final message?) ...[
        Container(
          padding: const EdgeInsets.all(14), // p-3.5
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2), // bg-red-50
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: const Color(0xFFFECACA)), // border-red-200
          ),
          child: Row(
            children: [
              const SiteIcon(SiteIcons.xCircle, size: 20, color: Color(0xFFDC2626)),
              const SizedBox(width: 10), // gap-2.5
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFFDC2626)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20), // mb-5
      ],

      // ── telefon ─────────────────────────────────────────────────────────────
      _label(theme, AuthTexts.phone),
      _Field(
        controller: _phone,
        hint: AuthTexts.phoneHint,
        keyboardType: TextInputType.phone,
        inputFormatters: uzPhoneFormatters(),
        hasError: _phoneError != null,
        enabled: !_loading,
        // `absolute left-3.5` — maydon ichidagi qo'zg'almas prefiks.
        prefix: '+998',
        onChanged: (_) {
          if (_phoneError != null) setState(() => _phoneError = null);
        },
      ),
      if (_phoneError case final message?) _fieldError(theme, message),
      const SizedBox(height: 16), // space-y-4
      // ── parol ───────────────────────────────────────────────────────────────
      Row(
        children: [
          Expanded(child: _label(theme, AuthTexts.password, bottom: 0)),
          GestureDetector(
            onTap: _loading ? null : () => context.push('/forgot-password'),
            child: Text(
              AuthTexts.forgotPassword,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12, // text-xs
                color: AppColors.olive,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6), // mb-1.5
      _Field(
        controller: _password,
        hint: AuthTexts.passwordPlaceholder,
        obscure: !_showPassword,
        hasError: _passwordError != null,
        enabled: !_loading,
        onChanged: (_) {
          if (_passwordError != null) setState(() => _passwordError = null);
        },
        onSubmitted: (_) => _submit(),
        suffix: GestureDetector(
          onTap: () => setState(() => _showPassword = !_showPassword),
          child: SiteIcon(
            _showPassword ? SiteIcons.eyeOff : SiteIcons.eye,
            size: 20,
            color: AppColors.dark.withValues(alpha: 0.4),
          ),
        ),
      ),
      if (_passwordError case final message?) _fieldError(theme, message),

      const SizedBox(height: 24), // space-y-4 + mt-2
      _submitButton(theme),

      const SizedBox(height: 20), // mt-5
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${AuthTexts.noAccount} '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: _loading ? null : () => context.push('/register'),
                child: Text(
                  AuthTexts.createAccount,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.olive,
                  ),
                ),
              ),
            ),
          ],
        ),
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.7)),
      ),

      const SizedBox(height: 28), // my-7
      Row(
        children: [
          const Expanded(child: Divider(height: 1, color: AppColors.borderLight)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12), // gap-3
            child: Text(
              AuthTexts.or,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12, // text-xs
                fontWeight: FontWeight.w500,
                letterSpacing: 1, // tracking-wider
                color: AppColors.dark.withValues(alpha: 0.4),
              ),
            ),
          ),
          const Expanded(child: Divider(height: 1, color: AppColors.borderLight)),
        ],
      ),
      const SizedBox(height: 28),

      SocialButton(
        mark: const GoogleMark(),
        label: AuthTexts.continueWithGoogle,
        busy: _socialLoading == 'google',
        onTap: () => _social('google'),
      ),
      const SizedBox(height: 12), // space-y-3
      SocialButton(
        mark: const SiteIcon(SiteIcons.appleMark, size: 20, color: AppColors.dark),
        label: AuthTexts.continueWithApple,
        busy: _socialLoading == 'apple',
        onTap: () => _social('apple'),
      ),
      const SizedBox(height: 12),
      SocialButton(
        mark: const SiteIcon(SiteIcons.facebookMark, size: 20, color: Color(0xFF1877F2)),
        label: AuthTexts.continueWithFacebook,
        busy: _socialLoading == 'facebook',
        onTap: () => _social('facebook'),
      ),

      const SizedBox(height: 32), // mt-8
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${AuthTexts.byContinuing} '),
            TextSpan(
              text: AuthTexts.termsOfUse,
              style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.olive),
            ),
          ],
        ),
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 12, // text-xs
          height: 1.6, // leading-relaxed
          color: AppColors.dark.withValues(alpha: 0.5),
        ),
      ),
    ];
  }

  Widget _logo(ThemeData theme) => Pressable(
    onTap: () => context.go('/'),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, // w-9
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.olive,
            borderRadius: BorderRadius.circular(AppRadius.sm), // rounded-lg
          ),
          child: const Center(
            child: SiteIcon(SiteIcons.logoHouse, size: 20, strokeWidth: 2.5, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8), // gap-2
        Text(
          AuthTexts.brand,
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: 24, // text-2xl
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5, // tracking-tight
            color: AppColors.dark,
          ),
        ),
      ],
    ),
  );

  Widget _submitButton(ThemeData theme) => Pressable(
    scale: 0.99,
    onTap: _loading ? null : _submit,
    child: Opacity(
      opacity: _loading ? 0.6 : 1,
      child: Container(
        height: 48, // py-3
        decoration: BoxDecoration(
          color: AppColors.olive,
          borderRadius: BorderRadius.circular(AppRadius.sm),
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
              _loading ? AuthTexts.loggingIn : AuthTexts.continueLabel,
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

  /// `h-9 px-3 rounded-lg border border-gray-200` — globus, til kodi va chevron.
  Widget _languageButton(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      onSelected: (code) => setState(() => LanguageService.instance.set(code)),
      offset: const Offset(0, 40),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
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
        height: 36, // h-9
        padding: const EdgeInsets.symmetric(horizontal: 12), // px-3
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.borderLight), // border-gray-200
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SiteIcon(SiteIcons.globe, size: 16, color: AppColors.dark),
            const SizedBox(width: 6), // gap-1.5
            Text(
              _lang.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12, // text-xs
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

  Widget _label(ThemeData theme, String text, {double bottom = 6}) => Padding(
    padding: EdgeInsets.only(bottom: bottom), // mb-1.5
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text),
          const TextSpan(
            text: '*',
            style: TextStyle(color: Color(0xFFEF4444)),
          ),
        ],
      ),
      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
    ),
  );

  Widget _fieldError(ThemeData theme, String message) => Padding(
    padding: const EdgeInsets.only(top: 4), // mt-1
    child: Text(
      message,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 12, // text-xs
        color: const Color(0xFFEF4444), // text-red-500
      ),
    ),
  );
}

/// Saytdagi kirish maydoni: oq fon, `border-gray-300`, `rounded-lg`, `py-3`, `text-[15px]`.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.prefix,
    this.suffix,
    this.obscure = false,
    this.hasError = false,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final String? prefix;
  final Widget? suffix;
  final bool obscure;
  final bool hasError;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(fontSize: 15, color: AppColors.dark);
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm), // rounded-lg
      borderSide: BorderSide(color: color, width: width),
    );
    // `border-red-400` xato holatida, aks holda `border-gray-300`.
    final line = hasError ? const Color(0xFFF87171) : const Color(0xFFD1D5DB);

    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: style,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: style?.copyWith(color: AppColors.dark.withValues(alpha: 0.3)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // pl-4 py-3
        prefixIcon: prefix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 14, right: 8), // left-3.5
                child: Text(
                  prefix!,
                  style: style?.copyWith(color: AppColors.dark.withValues(alpha: 0.6)),
                ),
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix == null
            ? null
            : Padding(padding: const EdgeInsets.only(right: 14), child: suffix), // right-3.5
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: border(line),
        enabledBorder: border(line),
        disabledBorder: border(line),
        focusedBorder: border(hasError ? const Color(0xFFF87171) : AppColors.olive, 2),
      ),
    );
  }
}
