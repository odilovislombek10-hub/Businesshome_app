import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/models/market_user.dart';
import '../../core/models/region.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/regions_service.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/specialist_bits.dart';
import 'cabinet_screen.dart' show roleGradient, roleWatermark;
import 'cabinet_texts.dart';

/// Kabinetning `profile` bo'limi — saytdagi `profileTpl`.
///
/// Uch qism: rolga xos gradientli muqova va ustiga chiqib turgan avatar (bosilsa rasm
/// almashtiriladi), xabar satri, va "Asosiy ma'lumotlar" formasi — ism, telefon (o'zgarmas),
/// viloyat/tuman va rol (o'zgarmas), pastida saqlash tugmasi.
///
/// **Bu yerda yo'q:** muqova rasmini yuklash va bandlik holati bloki — ikkalasi ham faqat
/// dizayner/usta/agent uchun va mutaxassis profili bo'limlari bilan birga keladi.
class CabinetProfile extends StatefulWidget {
  const CabinetProfile({super.key, required this.user});

  final MarketUser user;

  @override
  State<CabinetProfile> createState() => _CabinetProfileState();
}

class _CabinetProfileState extends State<CabinetProfile> {
  late final _fullName = TextEditingController(text: widget.user.fullName);
  late String _region = widget.user.region ?? '';
  late String _district = widget.user.district ?? '';

  List<Region> _regions = const [];
  bool _saving = false;
  bool _avatarUploading = false;

  /// Saytdagi `profileMessage` — yashil muvaffaqiyat yoki qizil xato satri.
  (String, bool)? _message;

  @override
  void initState() {
    super.initState();
    RegionsService.instance.regions().then((regions) {
      if (mounted) setState(() => _regions = regions);
    });
  }

  @override
  void dispose() {
    _fullName.dispose();
    super.dispose();
  }

  Region? get _selectedRegion {
    for (final r in _regions) {
      if (r.value == _region) return r;
    }
    return null;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await context.read<AuthService>().updateProfile(
        fullName: _fullName.text.trim(),
        region: _region,
        district: _district,
      );
      if (mounted) setState(() => _message = (CabinetTexts.profileSaved, true));
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = (e.message, false));
    } catch (_) {
      if (mounted) setState(() => _message = (CabinetTexts.profileError, false));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Saytdagi `onAvatarSelected` — 5 MB chegarasi ham o'sha yerdan.
  Future<void> _pickAvatar() async {
    if (_avatarUploading) return;
    final auth = context.read<AuthService>();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;

    if (await file.length() > 5 * 1024 * 1024) {
      if (mounted) setState(() => _message = (CabinetTexts.avatarTooBig, false));
      return;
    }

    setState(() {
      _avatarUploading = true;
      _message = null;
    });
    try {
      await auth.uploadAvatar(file.path);
      if (mounted) setState(() => _message = (CabinetTexts.profileSaved, true));
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = (e.message, false));
    } catch (_) {
      if (mounted) setState(() => _message = (CabinetTexts.profileError, false));
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthService>().user ?? widget.user;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          CabinetTexts.tabLabel('profile'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20, // text-xl
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 16), // space-y-4
        _header(context, user),
        if (_message case final message?) ...[
          const SizedBox(height: 16),
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
        ],
        const SizedBox(height: 16),
        _basicInfo(context, user),
      ],
    );
  }

  /// Muqova (rolga xos gradient + nuqtali naqsh) va ustiga chiqib turgan avatar.
  Widget _header(BuildContext context, MarketUser user) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 128, // h-32
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(decoration: BoxDecoration(gradient: roleGradient(user.role))),
                // `opacity-[0.14]`, 18×18 nuqtalar.
                const CustomPaint(painter: DotPatternPainter(step: 18, alpha: 0.14)),
                Positioned(
                  right: -40,
                  bottom: -64,
                  child: SiteIcon(
                    roleWatermark(user.role),
                    size: 200,
                    strokeWidth: 1.3,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), // px-5 pb-5
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // `-mt-12` — avatarning yuqori yarmi muqova ustiga chiqadi.
                SizedBox(
                  height: 48,
                  child: OverflowBox(
                    alignment: Alignment.bottomLeft,
                    maxHeight: 96,
                    child: _avatar(context, user),
                  ),
                ),
                const SizedBox(height: 16), // gap-4
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20, // text-xl
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8), // gap-2
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: CabinetTexts.roleBadgeBackground(user.role),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        CabinetTexts.roleLabel(user.role).toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10, // text-[10px]
                          fontWeight: FontWeight.w700,
                          color: CabinetTexts.roleBadgeForeground(user.role),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2), // mt-0.5
                Text(
                  user.phone,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// `w-24 h-24 rounded-full ring-4 ring-white` — bosilsa galereyadan rasm tanlanadi.
  Widget _avatar(BuildContext context, MarketUser user) {
    final theme = Theme.of(context);
    final hasAvatar = user.avatar != null && user.avatar!.isNotEmpty;
    return Pressable(
      onTap: _pickAvatar,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4), // ring-4 ring-white
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasAvatar)
                AppImage(imageUrl: user.avatar!, fit: BoxFit.cover)
              else
                ColoredBox(
                  color: CabinetTexts.roleColor(user.role),
                  child: Center(
                    child: Text(
                      initialsOf(user.fullName),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 30, // text-3xl
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Saytda kamera ikonkasi hover'da chiqadi; telefonda hover yo'q, shuning uchun
              // doim ko'rinadigan kichik nishoncha qo'yildi — aks holda rasm bosilishini hech
              // narsa bildirmaydi.
              if (!_avatarUploading)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0x99000000),
                      shape: BoxShape.circle,
                    ),
                    child: const SiteIcon(SiteIcons.camera, size: 13, color: Colors.white),
                  ),
                ),
              if (_avatarUploading)
                const ColoredBox(
                  color: Color(0x80000000), // bg-black/50
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _basicInfo(BuildContext context, MarketUser user) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20), // p-5
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CabinetTexts.basicInfo,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16, // text-base
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16), // mb-4

          _label(theme, CabinetTexts.fullName),
          _Field(controller: _fullName),
          const SizedBox(height: 16), // gap-4

          _label(theme, CabinetTexts.phone),
          _Field(value: user.phone, enabled: false),
          const SizedBox(height: 16),

          _label(theme, CabinetTexts.region),
          _Dropdown(
            value: _region,
            items: [('', CabinetTexts.allRegions), for (final r in _regions) (r.value, r.label)],
            // Viloyat almashsa tuman tozalanadi — saytdagi `onProfileCityChange`.
            onChanged: (value) => setState(() {
              _region = value;
              _district = '';
            }),
          ),
          if (_selectedRegion?.districts.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            _Dropdown(
              value: _district,
              items: [
                ('', CabinetTexts.allDistricts),
                for (final d in _selectedRegion!.districts) (d.value, d.label),
              ],
              onChanged: (value) => setState(() => _district = value),
            ),
          ],
          const SizedBox(height: 16),

          _label(theme, CabinetTexts.roleFieldLabel),
          _Field(value: CabinetTexts.roleLabel(user.role), enabled: false),

          const SizedBox(height: 24), // mt-6
          Align(
            alignment: Alignment.centerLeft,
            child: Pressable(
              onTap: _saving ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), // px-6 py-2.5
                decoration: BoxDecoration(
                  color: _saving ? AppColors.olive.withValues(alpha: 0.6) : AppColors.olive,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_saving) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 8), // gap-2
                    ],
                    Text(
                      _saving ? CabinetTexts.saving : CabinetTexts.saveChanges,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

/// `px-4 py-2.5 bg-gray-50 border rounded-xl text-sm` — o'chirilgani kulrangroq.
class _Field extends StatelessWidget {
  const _Field({this.controller, this.value, this.enabled = true});

  final TextEditingController? controller;

  /// Faqat o'chirilgan maydonlar uchun — ular tahrirlanmagani sababli nazoratchi kerak emas.
  final String? value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color),
    );
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? value : null,
      enabled: enabled,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: enabled ? AppColors.dark : AppColors.dark.withValues(alpha: 0.6),
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: enabled ? AppColors.surfaceAltLight : AppColors.surfaceMutedLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: border(AppColors.borderLight),
        enabledBorder: border(AppColors.borderLight),
        disabledBorder: border(AppColors.borderLight),
        focusedBorder: border(AppColors.olive),
      ),
    );
  }
}

/// Ikkilamchi sahifadagi `_CitySelect` bilan bir xil ko'rinishdagi ochiluvchi ro'yxat.
class _Dropdown extends StatelessWidget {
  const _Dropdown({required this.value, required this.items, required this.onChanged});

  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((o) => o.$1 == value) ? value : items.first.$1,
          isExpanded: true,
          icon: const SiteIcon(SiteIcons.chevronDown, size: 16),
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
          items: [
            for (final (v, label) in items)
              DropdownMenuItem(
                value: v,
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => onChanged(v ?? ''),
        ),
      ),
    );
  }
}
