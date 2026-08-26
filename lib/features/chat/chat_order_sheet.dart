import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_toast.dart';

/// Suhbat ichidan buyurtma berish — saytdagi "Order Modal".
///
/// Maydonlar: loyiha nomi, tavsif, narx (so'm/$) va muddat. Yuborilganda
/// `POST /market/chat/conversations/{id}/orders`.
class ChatOrderSheet extends StatefulWidget {
  const ChatOrderSheet({super.key, required this.conversationId, required this.propertyType});

  final int conversationId;

  /// `designer` | `master` | `agent` — xizmat turi shundan aniqlanadi.
  final String propertyType;

  static Future<bool?> show(
    BuildContext context, {
    required int conversationId,
    required String propertyType,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => ChatOrderSheet(conversationId: conversationId, propertyType: propertyType),
    );
  }

  @override
  State<ChatOrderSheet> createState() => _ChatOrderSheetState();
}

class _ChatOrderSheetState extends State<ChatOrderSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  String _currency = 'uzs';
  String? _deadline;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  /// Saytdagi `service_type` — mulk turiga qarab.
  String get _serviceType => switch (widget.propertyType) {
    'master' => 'master_work',
    'agent' => 'agent_service',
    _ => 'design',
  };

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ApiClient.instance.post<dynamic>(
        '/market/chat/conversations/${widget.conversationId}/orders',
        data: {
          'title': _title.text.trim(),
          'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
          'price': num.tryParse(_price.text.replaceAll(' ', '')),
          'currency': _currency,
          'service_type': _serviceType,
          'deadline_at': _deadline,
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      showSiteToast(context, "Buyurtmani yaratib bo'lmadi", kind: ToastKind.error);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      _deadline =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.all(24), // p-6
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buyurtma berish',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18, // text-lg
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 16), // mb-4
              _label(theme, 'Loyiha nomi'),
              _field(theme, _title),
              const SizedBox(height: 12), // space-y-3
              _label(theme, 'Tavsif'),
              _field(theme, _description, lines: 3),
              const SizedBox(height: 12),
              _label(theme, 'Narx'),
              Row(
                children: [
                  Expanded(child: _field(theme, _price, hint: '0', number: true)),
                  const SizedBox(width: 8), // gap-2
                  _currencyToggle(theme),
                ],
              ),
              const SizedBox(height: 12),
              _label(theme, 'Muddat (ixtiyoriy)'),
              Pressable(
                scale: 0.99,
                onTap: _pickDeadline,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAltLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    _deadline ?? 'kk.oo.yyyy',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: _deadline == null
                          ? AppColors.dark.withValues(alpha: 0.4)
                          : AppColors.dark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4), // mt-1
              Text(
                'Buyurtma qachongacha bajarilishi kerakligi',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Pressable(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAltLight,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          'Bekor qilish',
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Pressable(
                      onTap: _submit,
                      child: Opacity(
                        opacity: _title.text.trim().isEmpty || _sending ? 0.6 : 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.olive,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            _sending ? 'Yuklanmoqda...' : 'Yuborish',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4), // mb-1
    child: Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.dark.withValues(alpha: 0.6),
      ),
    ),
  );

  Widget _field(
    ThemeData theme,
    TextEditingController controller, {
    int lines = 1,
    String? hint,
    bool number = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: lines,
      keyboardType: number ? TextInputType.number : null,
      onChanged: number
          ? (value) {
              // Saytda raqam bo'shliq bilan ajratib ko'rsatiladi.
              final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
              final formatted = digits.isEmpty ? '' : formatNumber(int.parse(digits));
              if (formatted != value) {
                controller.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
              setState(() {});
            }
          : (_) => setState(() {}),
      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceAltLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
      ),
    );
  }

  Widget _currencyToggle(ThemeData theme) => Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceAltLight,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.borderLight),
    ),
    clipBehavior: Clip.antiAlias,
    child: Row(
      children: [
        for (final (value, label) in const [('uzs', "so'm"), ('usd', r'$')])
          Pressable(
            onTap: () => setState(() => _currency = value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: _currency == value ? AppColors.olive : Colors.transparent,
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _currency == value ? Colors.white : AppColors.dark.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
