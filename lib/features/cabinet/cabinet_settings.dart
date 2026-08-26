import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/theme_controller.dart';
import '../../shared/widgets/entrance.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `settings` bo'limi — saytdagi `settingsTpl`.
///
/// Uch karta: ikkita bildirishnoma tugmachasi va parol o'zgartirish bloki bitta bo'lingan
/// kartada; keyin "Til va Mavzu"; oxirida hisobni o'chirish (xavfli zona).
///
/// Til tanlagichi shablonda uch tilni beradi, ammo ilovada hozircha faqat o'zbekcha matnlar
/// bor — shuning uchun u ko'rinadi, lekin o'chirilgan holatda turadi.
class CabinetSettings extends StatefulWidget {
  const CabinetSettings({super.key, required this.onDeleted});

  /// Hisob o'chirilgach bosh sahifaga qaytarish — saytda `router.navigate(['/'])`.
  final VoidCallback onDeleted;

  @override
  State<CabinetSettings> createState() => _CabinetSettingsState();
}

class _CabinetSettingsState extends State<CabinetSettings> {
  final _repo = const CabinetRepository();

  // Saytda bu ikkalasi ham faqat mahalliy signal — hech qayerga yuborilmaydi.
  bool _notifications = true;
  bool _email = false;

  bool _showPasswordForm = false;
  bool _passwordSaving = false;
  (String, bool)? _passwordMessage;

  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _cancelPasswordChange() {
    setState(() {
      _showPasswordForm = false;
      _passwordMessage = null;
      _current.clear();
      _newPassword.clear();
      _confirm.clear();
    });
  }

  Future<void> _changePassword() async {
    final current = _current.text;
    final next = _newPassword.text;
    final confirm = _confirm.text;

    // Tekshiruvlar tartibi saytdagi `changePassword()` bilan bir xil.
    if (current.isEmpty) {
      setState(() => _passwordMessage = (CabinetTexts.currentPasswordMissing, false));
      return;
    }
    if (next.length < 6) {
      setState(() => _passwordMessage = (CabinetTexts.errorPasswordMin, false));
      return;
    }
    if (next != confirm) {
      setState(() => _passwordMessage = (CabinetTexts.errorPasswordMatch, false));
      return;
    }

    setState(() {
      _passwordSaving = true;
      _passwordMessage = null;
    });
    try {
      await context.read<AuthService>().changePassword(currentPassword: current, newPassword: next);
      if (!mounted) return;
      setState(() {
        _passwordMessage = (CabinetTexts.passwordChanged, true);
        _showPasswordForm = false;
        _current.clear();
        _newPassword.clear();
        _confirm.clear();
      });
    } on AuthException catch (e) {
      if (mounted) setState(() => _passwordMessage = (e.message, false));
    } catch (_) {
      if (mounted) setState(() => _passwordMessage = (CabinetTexts.passwordError, false));
    } finally {
      if (mounted) setState(() => _passwordSaving = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(CabinetTexts.deleteAccount),
        content: Text(CabinetTexts.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(CabinetTexts.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(CabinetTexts.deleteAccount, style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (agreed != true) return;

    try {
      await _repo.deleteAccount();
      await auth.logout();
      widget.onDeleted();
    } catch (_) {
      // Saytda ham xato yutiladi; bu yerda hech bo'lmasa sabab ko'rsatiladi.
      messenger.showSnackBar(const SnackBar(content: Text("Hisobni o'chirib bo'lmadi")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          CabinetTexts.tabLabel('settings'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20, // text-xl
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 16), // space-y-4
        _card(
          // `divide-y divide-gray-100` — ichki chegaralar.
          child: Column(
            children: [
              _toggleRow(
                theme,
                title: CabinetTexts.notifications,
                subtitle: CabinetTexts.notificationsDesc,
                value: _notifications,
                onChanged: () => setState(() => _notifications = !_notifications),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
              _toggleRow(
                theme,
                title: CabinetTexts.emailUpdates,
                subtitle: CabinetTexts.emailUpdatesDesc,
                value: _email,
                onChanged: () => setState(() => _email = !_email),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
              _passwordBlock(theme),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(child: _languageAndTheme(theme)),
        const SizedBox(height: 16),
        _dangerZone(theme),
      ],
    );
  }

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
      border: Border.all(color: AppColors.borderLight),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  Widget _toggleRow(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required bool value,
    required VoidCallback onChanged,
  }) => Padding(
    padding: const EdgeInsets.all(20), // p-5
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 2), // mt-0.5
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12, // text-xs
                  color: AppColors.dark.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _Switch(value: value, onTap: onChanged),
      ],
    ),
  );

  Widget _passwordBlock(ThemeData theme) => Padding(
    padding: const EdgeInsets.all(20), // p-5
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CabinetTexts.changePassword,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 12), // mb-3
        if (_passwordMessage case final message?) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12), // p-3
            decoration: BoxDecoration(
              color: message.$2 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              message.$1,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: message.$2 ? const Color(0xFF047857) : const Color(0xFFDC2626),
              ),
            ),
          ),
          const SizedBox(height: 16), // mb-4
        ],
        if (!_showPasswordForm)
          Align(
            alignment: Alignment.centerLeft,
            child: _button(
              theme,
              label: CabinetTexts.updatePassword,
              onTap: () => setState(() => _showPasswordForm = true),
            ),
          )
        else ...[
          _label(theme, CabinetTexts.currentPassword),
          _PasswordField(controller: _current),
          const SizedBox(height: 12), // space-y-3
          _label(theme, CabinetTexts.newPassword),
          _PasswordField(controller: _newPassword),
          const SizedBox(height: 12),
          _label(theme, CabinetTexts.confirmNewPassword),
          _PasswordField(controller: _confirm),
          const SizedBox(height: 16), // pt-1 + gap
          Row(
            children: [
              _button(
                theme,
                label: CabinetTexts.updatePassword,
                busy: _passwordSaving,
                onTap: _passwordSaving ? null : _changePassword,
              ),
              const SizedBox(width: 8), // gap-2
              _button(
                theme,
                label: CabinetTexts.cancel,
                background: AppColors.surfaceMutedLight,
                foreground: AppColors.dark.withValues(alpha: 0.7),
                onTap: _cancelPasswordChange,
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _languageAndTheme(ThemeData theme) {
    final controller = context.watch<ThemeController>();
    return Padding(
      padding: const EdgeInsets.all(20), // p-5
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CabinetTexts.languageAndTheme,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16), // space-y-4
          _label(theme, CabinetTexts.language),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMutedLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              CabinetTexts.languageUz,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 16), // gap-4
          _label(theme, CabinetTexts.theme),
          Row(
            children: [
              Expanded(
                child: _themeButton(
                  theme,
                  label: CabinetTexts.themeLight,
                  active: !controller.isDark,
                  onTap: () => controller.setMode(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 8), // gap-2
              Expanded(
                child: _themeButton(
                  theme,
                  label: CabinetTexts.themeDark,
                  active: controller.isDark,
                  onTap: () => controller.setMode(ThemeMode.dark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _themeButton(
    ThemeData theme, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8), // px-3 py-2
      decoration: BoxDecoration(
        color: active ? AppColors.olive : AppColors.surfaceMutedLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: active ? AppColors.olive : AppColors.borderLight),
        boxShadow: active
            ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4))]
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12, // text-xs
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.dark,
          ),
        ),
      ),
    ),
  );

  Widget _dangerZone(ThemeData theme) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20), // p-5
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2), // bg-red-50
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: const Color(0xFFFECACA)), // border-red-200
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CabinetTexts.dangerZone,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB91C1C), // red-700
          ),
        ),
        const SizedBox(height: 4), // mt-1
        Text(
          CabinetTexts.deleteAccountDesc,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12, // text-xs
            color: const Color(0xFFDC2626), // red-600
          ),
        ),
        const SizedBox(height: 16), // mt-4
        Align(
          alignment: Alignment.centerLeft,
          child: _button(
            theme,
            label: CabinetTexts.deleteAccount,
            background: const Color(0xFFEF4444), // bg-red-500
            onTap: _confirmDeleteAccount,
          ),
        ),
      ],
    ),
  );

  Widget _button(
    ThemeData theme, {
    required String label,
    VoidCallback? onTap,
    bool busy = false,
    Color background = AppColors.olive,
    Color foreground = Colors.white,
  }) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // px-4 py-2
      decoration: BoxDecoration(
        color: busy ? background.withValues(alpha: 0.6) : background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
            ),
            const SizedBox(width: 8), // gap-2
          ],
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _label(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6), // mb-1.5
    child: Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 12, // text-xs
        fontWeight: FontWeight.w600,
        color: AppColors.dark.withValues(alpha: 0.6),
      ),
    ),
  );
}

/// `h-6 w-11 rounded-full` tugmacha — yoqilganda zaytun rangga bo'yaladi va nuqta o'ngga suriladi.
class _Switch extends StatelessWidget {
  const _Switch({required this.value, required this.onTap});

  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200), // duration-200
      width: 44,
      height: 24,
      decoration: BoxDecoration(
        color: value ? AppColors.olive : const Color(0xFFD1D5DB), // bg-gray-300
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
          ),
        ),
      ),
    ),
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      obscureText: true,
      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceAltLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: border(AppColors.borderLight),
        enabledBorder: border(AppColors.borderLight),
        focusedBorder: border(AppColors.olive),
      ),
    );
  }
}
