import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/models/market_user.dart';
import '../../core/services/auth_service.dart';
import 'phone_field.dart';

/// `/login` — phone + password, or phone + SMS code, matching the website's login page.
///
/// One phone can hold several accounts (user / agent / designer / master / developer). When it
/// does, the site asks which to enter rather than guessing; this screen does the same via
/// `/auth/login/available-roles`.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Mode { password, otp }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  _Mode _mode = _Mode.password;
  bool _busy = false;
  bool _codeSent = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  AuthService get _auth => context.read<AuthService>();

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Ulanishda xatolik: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitPassword() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(() async {
      final phone = normalizePhone(_phone.text);
      final password = _password.text;

      // Ask which accounts this pair unlocks before signing in — with several the backend would
      // otherwise pick the most recently used one, which is not necessarily the intended account.
      final roles = await _auth.availableRoles(phone: phone, password: password);
      MarketRole? chosen;
      if (roles.length > 1) {
        chosen = await _pickRole(roles);
        if (chosen == null) return; // dismissed
      }

      await _auth.login(phone: phone, password: password, role: chosen);
      if (mounted) context.go('/');
    });
  }

  Future<void> _sendCode() async {
    if (!isCompletePhone(_phone.text)) {
      setState(() => _error = 'Telefon raqamni to‘liq kiriting');
      return;
    }
    await _run(() async {
      await _auth.sendOtp(phone: normalizePhone(_phone.text), purpose: 'login');
      if (mounted) setState(() => _codeSent = true);
    });
  }

  Future<void> _submitOtp() async {
    await _run(() async {
      await _auth.loginWithOtp(phone: normalizePhone(_phone.text), code: _code.text.trim());
      if (mounted) context.go('/');
    });
  }

  Future<MarketRole?> _pickRole(List<AvailableRole> roles) => showModalBottomSheet<MarketRole>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('Qaysi hisobga kirasiz?', style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final r in roles)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(r.fullName.isEmpty ? r.role.label : r.fullName),
              subtitle: Text(r.role.label),
              trailing: r.isVerified
                  ? const Icon(Icons.verified, size: 18, color: AppColors.olive)
                  : null,
              onTap: () => Navigator.of(context).pop(r.role),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  /// Social sign-in is a browser round trip on the site; open the same URL and let the site
  /// finish the exchange until the app registers its own deep-link callback.
  Future<void> _social(String provider) async {
    final url = Uri.parse('https://businesshome.uz/api/market/social/$provider/authorize');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) setState(() => _error = 'Brauzerni ochib bo‘lmadi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Kirish')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text('Xush kelibsiz', style: theme.textTheme.displaySmall),
              const SizedBox(height: 4),
              Text('Hisobingizga kiring', style: theme.textTheme.bodySmall),
              const SizedBox(height: 24),

              PhoneField(controller: _phone, enabled: !_busy),
              const SizedBox(height: 16),

              if (_mode == _Mode.password) ...[
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: 'Parol',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Parol kamida 6 ta belgi' : null,
                  onFieldSubmitted: (_) => _submitPassword(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : () => context.push('/forgot-password'),
                    child: const Text('Parolni unutdingizmi?'),
                  ),
                ),
              ] else ...[
                if (_codeSent)
                  TextFormField(
                    controller: _code,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'SMS kod'),
                    onFieldSubmitted: (_) => _submitOtp(),
                  )
                else
                  Text(
                    'Telefon raqamingizga tasdiqlash kodi yuboriladi',
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: 8),
              ],

              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy
                    ? null
                    : switch ((_mode, _codeSent)) {
                        (_Mode.password, _) => _submitPassword,
                        (_Mode.otp, false) => _sendCode,
                        (_Mode.otp, true) => _submitOtp,
                      },
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(switch ((_mode, _codeSent)) {
                        (_Mode.password, _) => 'Kirish',
                        (_Mode.otp, false) => 'Kod yuborish',
                        (_Mode.otp, true) => 'Tasdiqlash',
                      }),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _mode = _mode == _Mode.password ? _Mode.otp : _Mode.password;
                        _codeSent = false;
                        _error = null;
                      }),
                child: Text(
                  _mode == _Mode.password ? 'SMS kod bilan kirish' : 'Parol bilan kirish',
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('yoki', style: theme.textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final (provider, label) in const [
                    ('google', 'Google'),
                    ('apple', 'Apple'),
                    ('facebook', 'Facebook'),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          onPressed: _busy ? null : () => _social(provider),
                          child: Text(label, style: theme.textTheme.labelSmall),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Hisobingiz yo‘qmi?', style: theme.textTheme.bodySmall),
                  TextButton(
                    onPressed: _busy ? null : () => context.push('/register'),
                    child: const Text("Ro'yxatdan o'ting"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
