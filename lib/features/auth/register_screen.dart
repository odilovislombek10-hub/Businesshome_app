import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/models/market_user.dart';
import '../../core/models/region.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/regions_service.dart';
import 'auth_error_box.dart';
import 'phone_field.dart';

/// `/register` — the site's two-step sign-up: choose a role and confirm the phone by SMS, then
/// fill in the profile.
///
/// The backend keys the code by `purpose: 'register'`, so a code issued for login will not work
/// here — the two steps have to stay in that order.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();

  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _fullName = TextEditingController();
  final _password = TextEditingController();

  MarketRole _role = MarketRole.user;
  Region? _region;
  District? _district;
  List<Region> _regions = const [];

  bool _codeSent = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    RegionsService.instance.regions().then((regions) {
      if (mounted) setState(() => _regions = regions);
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _fullName.dispose();
    _password.dispose();
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

  Future<void> _sendCode() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    await _run(() async {
      await _auth.sendOtp(phone: normalizePhone(_phone.text), purpose: 'register', role: _role);
      if (mounted) setState(() => _codeSent = true);
    });
  }

  Future<void> _submit() async {
    if (!_profileFormKey.currentState!.validate()) return;
    await _run(() async {
      await _auth.register(
        phone: normalizePhone(_phone.text),
        code: _code.text.trim(),
        fullName: _fullName.text.trim(),
        password: _password.text,
        region: _region?.value,
        district: _district?.value,
        role: _role,
      );
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Ro'yxatdan o'tish")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              _codeSent ? 'Ma’lumotlaringiz' : 'Kim sifatida ro‘yxatdan o‘tasiz?',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 16),

            if (!_codeSent) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final role in MarketRole.values)
                    ChoiceChip(
                      label: Text(role.label),
                      selected: _role == role,
                      onSelected: _busy ? null : (_) => setState(() => _role = role),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _phoneFormKey,
                child: PhoneField(controller: _phone, enabled: !_busy),
              ),
              AuthErrorBox(message: _error),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _sendCode,
                child: _busy ? const _Spinner() : const Text('Kod yuborish'),
              ),
            ] else ...[
              Form(
                key: _profileFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _code,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'SMS kod',
                        helperText: '+998 ${_phone.text} raqamiga yuborildi',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().length < 4) ? 'Kodni kiriting' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullName,
                      enabled: !_busy,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'To‘liq ism'),
                      validator: (v) =>
                          (v == null || v.trim().length < 2) ? 'Ismingizni kiriting' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Parol',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Parol kamida 6 ta belgi' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Region>(
                      initialValue: _region,
                      decoration: const InputDecoration(labelText: 'Viloyat'),
                      items: [
                        for (final r in _regions) DropdownMenuItem(value: r, child: Text(r.label)),
                      ],
                      onChanged: _busy
                          ? null
                          : (r) => setState(() {
                              _region = r;
                              // Districts belong to a region — a stale one would be sent with
                              // the wrong parent.
                              _district = null;
                            }),
                    ),
                    if (_region != null && _region!.districts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<District>(
                        initialValue: _district,
                        decoration: const InputDecoration(labelText: 'Tuman'),
                        items: [
                          for (final d in _region!.districts)
                            DropdownMenuItem(value: d, child: Text(d.label)),
                        ],
                        onChanged: _busy ? null : (d) => setState(() => _district = d),
                      ),
                    ],
                  ],
                ),
              ),
              AuthErrorBox(message: _error),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy ? const _Spinner() : const Text("Ro'yxatdan o'tish"),
              ),
              TextButton(
                onPressed: _busy ? null : () => setState(() => _codeSent = false),
                child: const Text('Raqamni o‘zgartirish'),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Hisobingiz bormi?', style: theme.textTheme.bodySmall),
                TextButton(
                  onPressed: _busy ? null : () => context.pushReplacement('/login'),
                  child: const Text('Kirish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
}
