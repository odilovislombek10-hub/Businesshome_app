import '../../core/i18n/translate.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import 'entrance.dart';
import 'site_icon.dart';
import 'site_toast.dart';

/// `report-modal.component.ts` — e'lon ustidan shikoyat.
///
/// Mobilda pastdan chiqadi (`items-end`, `rounded-t-3xl`), sabab tanlanmaguncha
/// "Yuborish" o'chiq turadi; "Qo'shimcha" tanlansa kamida 5 belgi matn kerak.
class ReportSheet extends StatefulWidget {
  const ReportSheet({super.key, required this.propertyId, required this.propertyType});

  final int propertyId;

  /// `secondary` yoki `rent` — backend shu nom bilan saqlaydi.
  final String propertyType;

  static Future<void> show(
    BuildContext context, {
    required int propertyId,
    required String propertyType,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => ReportSheet(propertyId: propertyId, propertyType: propertyType),
    );
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  static List<({String key, String label, String icon})> get _reasons =>
      <({String key, String label, String icon})>[
        (key: 'scam', label: t('report.reason.scam'), icon: '⚠️'),
        (key: 'fakeAd', label: t('report.reason.fakeAd'), icon: '🚫'),
        (key: 'phoneDead', label: t('report.reason.phoneDead'), icon: '📵'),
        (key: 'other', label: t('report.reason.other'), icon: '✏️'),
      ];

  final _other = TextEditingController();
  String? _selected;
  bool _sending = false;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_selected == null) return false;
    if (_selected == 'other') return _other.text.trim().length >= 5;
    return true;
  }

  Future<void> _submit() async {
    if (!_canSubmit || _sending) return;
    setState(() => _sending = true);
    final reason = _selected!;
    final label = _reasons.firstWhere((r) => r.key == reason).label;
    try {
      final res = await ApiClient.instance.post<dynamic>(
        '/market/cabinet/reports',
        data: {
          'property_id': widget.propertyId,
          'property_type': widget.propertyType,
          'reason': reason,
          'text': reason == 'other' ? _other.text.trim() : label,
        },
      );
      if (!mounted) return;
      final ok = res.statusCode == 200 || res.statusCode == 201;
      Navigator.of(context).pop();
      showSiteToast(
        context,
        ok ? t('report.success') : 'Shikoyatni yuborib bo\'lmadi',
        kind: ok ? ToastKind.success : ToastKind.error,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      showSiteToast(context, "Shikoyatni yuborib bo'lmadi", kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(theme),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20), // p-5
                child: Column(
                  children: [
                    for (final reason in _reasons) ...[
                      _reasonRow(theme, reason),
                      const SizedBox(height: 8), // space-y-2
                    ],
                    if (_selected == 'other')
                      TextField(
                        controller: _other,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: t('report.otherPlaceholder'),
                          filled: true,
                          fillColor: AppColors.surfaceAltLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: AppColors.borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: AppColors.borderLight),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _footer(theme),
          ],
        ),
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // px-5 py-4
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.dark.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('report.title'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2), // mt-0.5
                Text(
                  t('report.subtitle'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Pressable(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36, // w-9
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SiteIcon(
                  SiteIcons.close,
                  size: 18,
                  color: AppColors.dark.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonRow(ThemeData theme, ({String key, String label, String icon}) reason) {
    final selected = _selected == reason.key;
    return Pressable(
      scale: 0.99,
      onTap: () => setState(() => _selected = reason.key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // px-4 py-3
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? const Color(0xFFFCA5A5) : AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFFEF4444) : Colors.transparent,
                border: Border.all(
                  color: selected ? const Color(0xFFEF4444) : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Center(
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12), // gap-3
            Expanded(
              child: Text(
                reason.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? const Color(0xFFB91C1C) : AppColors.dark,
                ),
              ),
            ),
            Text(reason.icon, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _footer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.dark.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  t('common.cancel'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.dark.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12), // gap-3
          Expanded(
            child: Pressable(
              scale: _canSubmit ? 0.98 : 1,
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _canSubmit ? const Color(0xFFEF4444) : AppColors.surfaceAltLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  t('common.submit'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _canSubmit ? Colors.white : AppColors.dark.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
