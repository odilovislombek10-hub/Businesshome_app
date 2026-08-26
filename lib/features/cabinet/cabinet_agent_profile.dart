import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/error_view.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `agent-profile` bo'limi — saytdagi `agentProfileTpl`.
///
/// Bitta kartada agentlik ma'lumotlari: ko'rsatiladigan ism, agentlik nomi, o'zi haqida,
/// tajriba va litsenziya (yonma-yon), Telegram va Instagram (yonma-yon), saqlash tugmasi.
class CabinetAgentProfile extends StatefulWidget {
  const CabinetAgentProfile({super.key});

  @override
  State<CabinetAgentProfile> createState() => _CabinetAgentProfileState();
}

class _CabinetAgentProfileState extends State<CabinetAgentProfile> {
  final _repo = const CabinetRepository();

  late Future<AgentProfile> _future = _repo.agentProfile();

  final _displayName = TextEditingController();
  final _agency = TextEditingController();
  final _bio = TextEditingController();
  final _experience = TextEditingController();
  final _license = TextEditingController();
  final _telegram = TextEditingController();
  final _instagram = TextEditingController();

  /// Maydonlar javob kelgach bir marta to'ldiriladi — keyin foydalanuvchi kiritgani qoladi.
  bool _filled = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_displayName, _agency, _bio, _experience, _license, _telegram, _instagram]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(AgentProfile profile) {
    if (_filled) return;
    _filled = true;
    _displayName.text = profile.displayName;
    _agency.text = profile.agencyName;
    _bio.text = profile.bio;
    _experience.text = profile.experienceYears?.toString() ?? '';
    _license.text = profile.licenseNumber;
    _telegram.text = profile.telegram;
    _instagram.text = profile.instagram;
  }

  Future<void> _save() async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await _repo.saveAgentProfile({
        'display_name': _displayName.text.trim(),
        'agency_name': _agency.text.trim(),
        'bio': _bio.text.trim(),
        'experience_years': int.tryParse(_experience.text),
        'license_number': _license.text.trim(),
        'telegram': _telegram.text.trim(),
        'instagram': _instagram.text.trim(),
      });
      messenger.showSnackBar(SnackBar(content: Text(CabinetTexts.profileSaved)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(CabinetTexts.profileError)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<AgentProfile>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.olive));
        }
        if (snapshot.hasError) {
          return ErrorView(
            message: CabinetTexts.agentLoadError,
            onRetry: () => setState(() => _future = _repo.agentProfile()),
          );
        }
        _fill(snapshot.data ?? const AgentProfile());

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              CabinetTexts.tabLabel('agent-profile'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20, // text-xl
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16), // space-y-4
            Container(
              padding: const EdgeInsets.all(24), // p-6
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(theme, CabinetTexts.agentDisplayName),
                  _field(_displayName),
                  const SizedBox(height: 16), // space-y-4

                  _label(theme, CabinetTexts.agentAgency),
                  _field(_agency),
                  const SizedBox(height: 16),

                  _label(theme, CabinetTexts.agentBio),
                  _field(_bio, lines: 3),
                  const SizedBox(height: 16),

                  _pair(
                    theme,
                    leftLabel: CabinetTexts.agentExperience,
                    left: _field(_experience, digitsOnly: true),
                    rightLabel: CabinetTexts.agentLicense,
                    right: _field(_license),
                  ),
                  const SizedBox(height: 16),

                  _pair(
                    theme,
                    leftLabel: CabinetTexts.agentTelegram,
                    left: _field(_telegram, hint: CabinetTexts.agentHandleHint),
                    rightLabel: CabinetTexts.agentInstagram,
                    right: _field(_instagram, hint: CabinetTexts.agentHandleHint),
                  ),
                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Pressable(
                      onTap: _saving ? null : _save,
                      child: Opacity(
                        opacity: _saving ? 0.6 : 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24, // px-6
                            vertical: 10, // py-2.5
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.olive,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            _saving ? CabinetTexts.saving : CabinetTexts.saveChanges,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// `grid grid-cols-2 gap-4`
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
          children: [_label(theme, leftLabel), left],
        ),
      ),
      const SizedBox(width: 16), // gap-4
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_label(theme, rightLabel), right],
        ),
      ),
    ],
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

  /// `px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm`
  Widget _field(
    TextEditingController controller, {
    int lines = 1,
    bool digitsOnly = false,
    String? hint,
  }) {
    final theme = Theme.of(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      maxLines: lines,
      keyboardType: digitsOnly ? TextInputType.number : null,
      inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceAltLight,
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.dark.withValues(alpha: 0.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: border(AppColors.borderLight),
        enabledBorder: border(AppColors.borderLight),
        focusedBorder: border(AppColors.olive),
      ),
    );
  }
}
