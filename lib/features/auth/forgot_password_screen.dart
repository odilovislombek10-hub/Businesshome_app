import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import 'auth_error_box.dart';
import 'phone_field.dart';

/// `/forgot-password` — request a `purpose: 'reset'` code, then set a new password with it.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
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
      await _auth.sendOtp(phone: normalizePhone(_phone.text), purpose: 'reset');
      if (mounted) setState(() => _codeSent = true);
    });
  }

  Future<void> _submit() async {
    if (!_resetFormKey.currentState!.validate()) return;
    await _run(() async {
      await _auth.resetPassword(
        phone: normalizePhone(_phone.text),
        code: _code.text.trim(),
        newPassword: _password.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Parol yangilandi — endi kirishingiz mumkin')));
      context.pushReplacement('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Parolni tiklash')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              _codeSent ? 'Yangi parol' : 'Telefon raqamingiz',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 4),
            Text(
              _codeSent
                  ? 'SMS kodni kiriting va yangi parol o‘rnating'
                  : 'Raqamingizga tasdiqlash kodi yuboriladi',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            if (!_codeSent) ...[
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
                key: _resetFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _code,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'SMS kod'),
                      validator: (v) =>
                          (v == null || v.trim().length < 4) ? 'Kodni kiriting' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Yangi parol',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Parol kamida 6 ta belgi' : null,
                    ),
                  ],
                ),
              ),
              AuthErrorBox(message: _error),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy ? const _Spinner() : const Text('Parolni saqlash'),
              ),
              TextButton(
                onPressed: _busy ? null : () => setState(() => _codeSent = false),
                child: const Text('Raqamni o‘zgartirish'),
              ),
            ],
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
