import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/site_icon.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `services` bo'limi (dizayner/usta) — saytdagi `servicesTpl`.
///
/// Xizmat paketlari: nomi, narxi, bajarish muddati va xususiyatlar ro'yxati. Tavsiya etilgan
/// paket zaytun ramka va tepasidagi nishoncha bilan ajralib turadi.
class CabinetServices extends StatefulWidget {
  const CabinetServices({super.key, required this.future, required this.onChanged});

  final Future<List<ServicePackage>> future;
  final VoidCallback onChanged;

  @override
  State<CabinetServices> createState() => _CabinetServicesState();
}

class _CabinetServicesState extends State<CabinetServices> {
  final _repo = const CabinetRepository();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<ServicePackage>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.olive));
        }
        if (snapshot.hasError) {
          return ErrorView(message: CabinetTexts.servicesLoadError, onRetry: widget.onChanged);
        }
        final packages = snapshot.data ?? const <ServicePackage>[];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    CabinetTexts.tabLabel('services'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20, // text-xl
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                Pressable(
                  onTap: () => _openEditor(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.olive,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      '+ ${CabinetTexts.serviceAdd}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // space-y-4
            if (packages.isEmpty)
              _emptyCard(theme)
            else
              for (final pkg in packages) ...[
                _card(theme, pkg),
                const SizedBox(height: 16), // gap-4
              ],
          ],
        );
      },
    );
  }

  Widget _card(ThemeData theme, ServicePackage pkg) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20), // p-5
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
          border: Border.all(color: pkg.isRecommended ? AppColors.olive : AppColors.borderLight),
          // `ring-2 ring-olive/20`
          boxShadow: pkg.isRecommended
              ? [
                  BoxShadow(
                    color: AppColors.olive.withValues(alpha: 0.2),
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pkg.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18, // text-lg
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8), // mt-2
            Text(
              '${formatNumber(pkg.price)} ${pkg.currency}',
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 24, // text-2xl
                fontWeight: FontWeight.w700,
                color: AppColors.olive,
              ),
            ),
            const SizedBox(height: 4), // mt-1
            Text(
              '${pkg.deliveryDays} ${CabinetTexts.serviceDays}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12, // text-xs
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
            if (pkg.features.isNotEmpty) ...[
              const SizedBox(height: 12), // mt-3
              for (final feature in pkg.features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6), // space-y-1.5
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: SiteIcon(SiteIcons.check, size: 12, color: AppColors.olive),
                      ),
                      const SizedBox(width: 8), // gap-2
                      Expanded(
                        child: Text(
                          feature,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            color: AppColors.dark.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 16), // mt-4 pt-4
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!pkg.isRecommended)
                  GestureDetector(
                    onTap: () => _markRecommended(pkg),
                    child: Text(
                      CabinetTexts.serviceMakeRecommended,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: AppColors.olive,
                      ),
                    ),
                  ),
                const Spacer(), // ml-auto
                GestureDetector(
                  onTap: () => _openEditor(pkg),
                  child: Text(
                    CabinetTexts.edit,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _confirmDelete(pkg),
                  child: Text(
                    CabinetTexts.delete,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // `absolute -top-3 left-1/2` — kartaning tepasidan chiqib turadi.
      if (pkg.isRecommended)
        Positioned(
          top: -12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                CabinetTexts.serviceRecommended,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10, // text-[10px]
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _emptyCard(ThemeData theme) => Container(
    padding: const EdgeInsets.all(48), // p-12
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Column(
      children: [
        Text(
          CabinetTexts.servicesEmpty,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18, // text-lg
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 8), // mb-2
        Text(
          CabinetTexts.servicesEmptyDesc,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.5)),
        ),
      ],
    ),
  );

  Future<void> _markRecommended(ServicePackage pkg) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.markPackageRecommended(pkg.id);
      widget.onChanged();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.serviceSaveError)));
    }
  }

  Future<void> _confirmDelete(ServicePackage pkg) async {
    final messenger = ScaffoldMessenger.of(context);
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(CabinetTexts.servicesConfirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(CabinetTexts.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(CabinetTexts.deleteConfirmYes, style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (agreed != true) return;
    try {
      await _repo.deletePackage(pkg.id);
      widget.onChanged();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.portfolioRemoveError)));
    }
  }

  Future<void> _openEditor(ServicePackage? pkg) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _PackageEditor(package: pkg, repo: _repo),
    );
    if (saved == true) widget.onChanged();
  }
}

/// Saytdagi paket oynasi — markazda, `max-w-md`.
class _PackageEditor extends StatefulWidget {
  const _PackageEditor({required this.package, required this.repo});

  final ServicePackage? package;
  final CabinetRepository repo;

  @override
  State<_PackageEditor> createState() => _PackageEditorState();
}

class _PackageEditorState extends State<_PackageEditor> {
  late final _title = TextEditingController(text: widget.package?.title ?? '');
  late final _price = TextEditingController(text: widget.package?.price.toString() ?? '');
  late final _delivery = TextEditingController(text: widget.package?.deliveryDays.toString() ?? '');

  /// Saytda xususiyatlar bitta matn maydonida, har biri yangi qatorda.
  late final _features = TextEditingController(
    text: (widget.package?.features ?? const <String>[]).join('\n'),
  );

  late bool _recommended = widget.package?.isRecommended ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _delivery.dispose();
    _features.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await widget.repo.savePackage({
        'title': _title.text.trim(),
        'price': num.tryParse(_price.text) ?? 0,
        'delivery_days': int.tryParse(_delivery.text) ?? 0,
        'features': _features.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList(),
        'is_recommended': _recommended,
      }, id: widget.package?.id);
      navigator.pop(true);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.serviceSaveError)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(16), // p-4
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24), // p-6
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.package == null ? CabinetTexts.serviceAdd : CabinetTexts.serviceEdit,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18, // text-lg
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16), // mb-4

            _label(theme, CabinetTexts.serviceTitle),
            _field(_title),
            const SizedBox(height: 12), // space-y-3

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(theme, CabinetTexts.servicePrice),
                      _field(_price, digitsOnly: true),
                    ],
                  ),
                ),
                const SizedBox(width: 12), // gap-3
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(theme, CabinetTexts.serviceDelivery),
                      _field(_delivery, digitsOnly: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _label(theme, '${CabinetTexts.serviceFeatures} (${CabinetTexts.serviceFeaturesHint})'),
            _field(_features, lines: 3),
            const SizedBox(height: 12),

            Row(
              children: [
                Checkbox(
                  value: _recommended,
                  activeColor: AppColors.olive,
                  onChanged: (value) => setState(() => _recommended = value ?? false),
                ),
                Expanded(
                  child: Text(
                    CabinetTexts.serviceMakeRecommended,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // mt-4

            Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      height: 44, // py-2.5
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMutedLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        CabinetTexts.cancel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8), // gap-2
                Expanded(
                  child: Pressable(
                    onTap: _saving ? null : _save,
                    child: Opacity(
                      opacity: _saving ? 0.6 : 1,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.olive,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          CabinetTexts.save,
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
          ],
        ),
      ),
    );
  }

  Widget _label(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4), // mb-1
    child: Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 12, // text-xs
        fontWeight: FontWeight.w600,
        color: AppColors.dark,
      ),
    ),
  );

  /// `px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm`
  Widget _field(TextEditingController controller, {int lines = 1, bool digitsOnly = false}) {
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: border(AppColors.borderLight),
        enabledBorder: border(AppColors.borderLight),
        focusedBorder: border(AppColors.olive),
      ),
    );
  }
}
