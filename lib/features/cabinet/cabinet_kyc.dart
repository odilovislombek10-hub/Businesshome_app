import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/market_user.dart';
import '../../shared/widgets/entrance.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `kyc` bo'limi — saytdagi `kycTpl`.
///
/// Holat nishonchasi, rad etilgan bo'lsa sabab, izoh matni va hujjat maydonlari: pasport
/// hamma uchun, dizaynerga diplom, usta va agentga litsenziya. Sayt `image/*` va PDF qabul
/// qiladi, shuning uchun bu yerda ham fayl tanlagich (rasm + PDF) ishlatiladi.
class CabinetKyc extends StatefulWidget {
  const CabinetKyc({super.key, required this.role});

  final MarketRole role;

  @override
  State<CabinetKyc> createState() => _CabinetKycState();
}

class _CabinetKycState extends State<CabinetKyc> {
  final _repo = const CabinetRepository();

  late Future<(String, String?)> _status = _repo.kycStatus();

  String? _passportPath;
  String? _passportName;
  String? _secondPath;
  String? _secondName;
  bool _submitting = false;

  /// Ikkinchi hujjat rolga qarab: dizaynerga diplom, usta/agentga litsenziya.
  bool get _isDiploma => widget.role == MarketRole.designer;

  bool get _hasSecondDocument =>
      widget.role == MarketRole.designer ||
      widget.role == MarketRole.master ||
      widget.role == MarketRole.agent;

  Future<void> _pick({required bool passport}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    final file = result?.files.singleOrNull;
    if (file?.path == null) return;
    setState(() {
      if (passport) {
        _passportPath = file!.path;
        _passportName = file.name;
      } else {
        _secondPath = file!.path;
        _secondName = file.name;
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final messenger = ScaffoldMessenger.of(context);
    if (_passportPath == null) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.kycNeedPassport)));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _repo.submitKyc(
        passport: _passportPath,
        diploma: _isDiploma ? _secondPath : null,
        license: _isDiploma ? null : _secondPath,
      );
      if (mounted) setState(() => _status = _repo.kycStatus());
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.kycSubmitError)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<(String, String?)>(
      future: _status,
      builder: (context, snapshot) {
        final (status, rejectReason) = snapshot.data ?? ('none', null);
        final (label, foreground, background) = CabinetTexts.kycStatusStyle(status);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              CabinetTexts.tabLabel('kyc'),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // px-3 py-1
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12, // text-xs
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16), // mb-4
                  if (status == 'rejected' && rejectReason != null) ...[
                    Text(
                      rejectReason,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFDC2626), // text-red-600
                      ),
                    ),
                    const SizedBox(height: 12), // mb-3
                  ],
                  Text(
                    CabinetTexts.kycIntro,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.dark.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16), // mb-4

                  _fileRow(
                    theme,
                    label: CabinetTexts.kycPassport,
                    fileName: _passportName,
                    onTap: () => _pick(passport: true),
                  ),
                  if (_hasSecondDocument) ...[
                    const SizedBox(height: 12), // space-y-3
                    _fileRow(
                      theme,
                      label: _isDiploma ? CabinetTexts.kycDiploma : CabinetTexts.kycLicense,
                      fileName: _secondName,
                      onTap: () => _pick(passport: false),
                    ),
                  ],

                  const SizedBox(height: 20), // mt-5
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Pressable(
                      // Tekshiruvda turgan arizani qayta yuborib bo'lmaydi.
                      onTap: _submitting || status == 'pending' ? null : _submit,
                      child: Opacity(
                        opacity: _submitting || status == 'pending' ? 0.6 : 1,
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
                            _submitting ? CabinetTexts.saving : CabinetTexts.kycSubmit,
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

  Widget _fileRow(
    ThemeData theme, {
    required String label,
    required String? fileName,
    required VoidCallback onTap,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 12, // text-xs
          fontWeight: FontWeight.w600,
          color: AppColors.dark.withValues(alpha: 0.6),
        ),
      ),
      const SizedBox(height: 6), // mb-1.5
      Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAltLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  fileName ?? CabinetTexts.kycChooseFile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fileName == null
                        ? AppColors.dark.withValues(alpha: 0.4)
                        : AppColors.dark,
                  ),
                ),
              ),
              Text(
                CabinetTexts.kycChooseFile,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.olive,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
