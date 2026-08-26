import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/models/region.dart';
import '../../core/services/regions_service.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/site_icon.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `projects` bo'limi (dizayner/usta) — saytdagi `projectsTpl`.
///
/// Bajarilgan loyihalar ro'yxati: 4:3 muqova, "Qoralama" nishonchasi, tahrirlash va o'chirish
/// tugmalari, ostida sarlavha, tavsif va shahar/maydon/sana qatori. Qo'shish va tahrirlash
/// saytdagidek pastdan chiqadigan oynada.
class CabinetProjects extends StatefulWidget {
  const CabinetProjects({super.key, required this.future, required this.onChanged});

  final Future<List<SpecialistProject>> future;

  /// Ro'yxat o'zgargach qayta yuklash — saytdagi `loadProjects()`.
  final VoidCallback onChanged;

  @override
  State<CabinetProjects> createState() => _CabinetProjectsState();
}

class _CabinetProjectsState extends State<CabinetProjects> {
  final _repo = const CabinetRepository();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<SpecialistProject>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.olive));
        }
        if (snapshot.hasError) {
          return ErrorView(message: CabinetTexts.projectsLoadError, onRetry: widget.onChanged);
        }
        final projects = snapshot.data ?? const <SpecialistProject>[];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CabinetTexts.tabLabel('projects'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20, // text-xl
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2), // mt-0.5
                      Text(
                        CabinetTexts.projectsSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.dark.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12), // gap-3
                _addButton(theme, CabinetTexts.projectAddNew),
              ],
            ),
            const SizedBox(height: 16), // space-y-4
            if (projects.isEmpty)
              _emptyCard(theme)
            else
              for (final project in projects) ...[
                _card(theme, project),
                const SizedBox(height: 16), // gap-4
              ],
          ],
        );
      },
    );
  }

  Widget _addButton(ThemeData theme, String label) => Pressable(
    onTap: () => _openEditor(null),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // px-4 py-2
      decoration: BoxDecoration(
        color: AppColors.olive,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        '+ $label',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
  );

  Widget _card(ThemeData theme, SpecialistProject project) {
    final facts = <String>[
      if (project.city case final city? when city.isNotEmpty)
        project.district == null || project.district!.isEmpty ? city : '$city, ${project.district}',
      if (project.areaM2 case final area?) '${formatNumber(area)} m²',
      if (project.completedAt case final date? when date.isNotEmpty) date,
    ];

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
          AspectRatio(
            aspectRatio: 4 / 3, // aspect-[4/3]
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: AppColors.surfaceMutedLight,
                  child: project.thumbnail == null
                      ? const Center(child: SiteIcon(SiteIcons.image, size: 40))
                      : AppImage(imageUrl: project.thumbnail!, fit: BoxFit.cover),
                ),
                if (!project.isPublished)
                  Positioned(
                    top: 8, // top-2 left-2
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B), // bg-amber-500
                        borderRadius: BorderRadius.circular(4), // rounded
                      ),
                      child: Text(
                        CabinetTexts.projectDraft,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _iconButton(SiteIcons.edit, AppColors.dark, () => _openEditor(project)),
                      const SizedBox(width: 4), // gap-1
                      _iconButton(
                        SiteIcons.trash,
                        const Color(0xFFEF4444),
                        () => _confirmDelete(project),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16), // p-4
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: 4), // mt-1
                  Text(
                    project.description,
                    maxLines: 2, // line-clamp-2
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12, // text-xs
                      color: AppColors.dark.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                if (facts.isNotEmpty) ...[
                  const SizedBox(height: 12), // mt-3
                  Text(
                    facts.join(' · '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11, // text-[11px]
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// `w-8 h-8 bg-white/95 rounded-lg shadow`
  Widget _iconButton(SiteIconData icon, Color color, VoidCallback onTap) => Pressable(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF), // bg-white/95
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Center(child: SiteIcon(icon, size: 16, color: color)),
    ),
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
        SiteIcon(SiteIcons.briefcase, size: 64, color: AppColors.dark.withValues(alpha: 0.2)),
        const SizedBox(height: 12), // mb-3
        Text(
          CabinetTexts.projectsEmpty,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 16), // mt-4
        _addButton(theme, CabinetTexts.projectAddFirst),
      ],
    ),
  );

  Future<void> _confirmDelete(SpecialistProject project) async {
    final messenger = ScaffoldMessenger.of(context);
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('"${project.title}" — loyihani o\'chirmoqchimisiz?'),
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
      await _repo.deleteProject(project.id);
      widget.onChanged();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.projectDeleteError)));
    }
  }

  Future<void> _openEditor(SpecialistProject? project) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProjectEditor(project: project, repo: _repo),
    );
    if (saved == true) widget.onChanged();
  }
}

/// Saytdagi loyiha oynasi — telefonda pastdan chiqadi (`items-end`, `rounded-t-2xl`).
class _ProjectEditor extends StatefulWidget {
  const _ProjectEditor({required this.project, required this.repo});

  final SpecialistProject? project;
  final CabinetRepository repo;

  @override
  State<_ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends State<_ProjectEditor> {
  late final _title = TextEditingController(text: widget.project?.title ?? '');
  late final _description = TextEditingController(text: widget.project?.description ?? '');
  late final _area = TextEditingController(text: widget.project?.areaM2?.toString() ?? '');
  late final _budget = TextEditingController(text: widget.project?.budget?.toString() ?? '');
  late final _completedAt = TextEditingController(text: widget.project?.completedAt ?? '');

  late List<String> _images = [...?widget.project?.images];
  late String _city = widget.project?.city ?? '';
  late String _district = widget.project?.district ?? '';
  late String _type = widget.project?.projectType ?? '';

  List<Region> _regions = const [];
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    RegionsService.instance.regions().then((regions) {
      if (mounted) setState(() => _regions = regions);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _area.dispose();
    _budget.dispose();
    _completedAt.dispose();
    super.dispose();
  }

  Region? get _selectedRegion {
    for (final r in _regions) {
      if (r.value == _city) return r;
    }
    return null;
  }

  /// Saytda rasmlar portfolio endpointiga yuklanadi va yangilari formaga qo'shiladi.
  Future<void> _uploadImages() async {
    if (_uploading) return;
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;

    final paths = <String>[];
    for (final file in picked) {
      if (await file.length() <= 5 * 1024 * 1024) paths.add(file.path);
    }
    if (paths.isEmpty) return;

    setState(() => _uploading = true);
    try {
      final portfolio = await widget.repo.addPortfolio(paths);
      // Javob butun portfolioni qaytaradi — oxiridan yangi yuklanganlari olinadi.
      final fresh = portfolio.length >= paths.length
          ? portfolio.sublist(portfolio.length - paths.length)
          : portfolio;
      if (mounted) setState(() => _images = [..._images, ...fresh]);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.portfolioUploadError)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await widget.repo.saveProject({
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'images': _images,
        'city': _city.isEmpty ? null : _city,
        'district': _district.isEmpty ? null : _district,
        'area_m2': num.tryParse(_area.text),
        'project_type': _type.isEmpty ? null : _type,
        'budget': num.tryParse(_budget.text),
        'completed_at': _completedAt.text.isEmpty ? null : _completedAt.text,
        'is_published': true,
      }, id: widget.project?.id);
      navigator.pop(true);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.projectSaveError)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      // `max-h-[92vh] rounded-t-2xl`
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // `sticky top-0 … border-b`
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // px-6 py-4
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.project == null ? CabinetTexts.projectAddNew : CabinetTexts.projectEdit,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18, // text-lg
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                Pressable(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMutedLight,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Center(child: SiteIcon(SiteIcons.close, size: 16)),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(24), // p-6
              children: [
                _label(theme, '${CabinetTexts.projectTitle} *'),
                _field(_title, CabinetTexts.projectTitlePlaceholder),
                const SizedBox(height: 16), // space-y-4

                _label(theme, CabinetTexts.projectDescription),
                _field(_description, CabinetTexts.projectDescPlaceholder, lines: 3),
                const SizedBox(height: 16),

                _label(theme, CabinetTexts.projectImages),
                if (_images.isNotEmpty) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // `grid-cols-3 gap-2`
                      final size = (constraints.maxWidth - 16) / 3;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (index, url) in _images.indexed)
                            SizedBox(width: size, child: _imageTile(theme, index, url)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12), // mb-3
                ],
                _uploadButton(theme),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(theme, CabinetTexts.projectCity),
                          _dropdown(
                            value: _city,
                            items: [('', '—'), for (final r in _regions) (r.value, r.label)],
                            onChanged: (value) => setState(() {
                              _city = value;
                              _district = '';
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12), // gap-3
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(theme, CabinetTexts.projectDistrict),
                          _dropdown(
                            value: _district,
                            enabled: _city.isNotEmpty,
                            items: [
                              ('', '—'),
                              for (final d in _selectedRegion?.districts ?? const <District>[])
                                (d.value, d.label),
                            ],
                            onChanged: (value) => setState(() => _district = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(theme, '${CabinetTexts.projectArea} (m²)'),
                          _field(_area, '0', digitsOnly: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(theme, CabinetTexts.projectType),
                          _dropdown(
                            value: _type,
                            items: [('', '—'), ...CabinetTexts.projectTypes],
                            onChanged: (value) => setState(() => _type = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _label(theme, CabinetTexts.projectBudget),
                _field(_budget, '0', digitsOnly: true, suffix: CabinetTexts.projectBudgetSuffix),
                const SizedBox(height: 16),

                _label(theme, CabinetTexts.projectCompletedAt),
                _dateField(theme),
              ],
            ),
          ),
          // `sticky bottom-0 … border-t`
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.viewInsetsOf(context).bottom),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Pressable(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                const SizedBox(width: 12), // gap-3
                Pressable(
                  onTap: _saving ? null : _save,
                  child: Opacity(
                    opacity: _title.text.trim().isEmpty || _saving ? 0.6 : 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // px-5
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageTile(ThemeData theme, int index, String url) => AspectRatio(
    aspectRatio: 1,
    child: Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ColoredBox(
              color: AppColors.surfaceMutedLight,
              child: AppImage(imageUrl: url, fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          top: 6, // top-1.5
          right: 6,
          child: Pressable(
            onTap: () => setState(() => _images.removeAt(index)),
            child: Container(
              width: 24, // w-6 h-6
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xF2EF4444), // bg-red-500/95
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('×', style: TextStyle(fontSize: 14, color: Colors.white, height: 1)),
              ),
            ),
          ),
        ),
        // Birinchi rasm — muqova.
        if (index == 0)
          Positioned(
            bottom: 4, // bottom-1 left-1
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                CabinetTexts.projectCover,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9, // text-[9px]
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    ),
  );

  /// `border-2 border-dashed` yuklash tugmasi.
  Widget _uploadButton(ThemeData theme) => Pressable(
    onTap: _uploading ? null : _uploadImages,
    child: Container(
      height: 48, // py-3
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: const Color(0xFFD1D5DB), // border-gray-300
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_uploading) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.olive),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            '+ ${CabinetTexts.projectUploadImages}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _dateField(ThemeData theme) => Pressable(
    onTap: () async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.tryParse(_completedAt.text) ?? now,
        firstDate: DateTime(now.year - 30),
        lastDate: now,
      );
      if (picked == null) return;
      final month = picked.month.toString().padLeft(2, '0');
      final day = picked.day.toString().padLeft(2, '0');
      setState(() => _completedAt.text = '${picked.year}-$month-$day');
    },
    child: Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        _completedAt.text.isEmpty ? '—' : _completedAt.text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: _completedAt.text.isEmpty ? AppColors.dark.withValues(alpha: 0.4) : AppColors.dark,
        ),
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
        color: AppColors.dark.withValues(alpha: 0.7),
      ),
    ),
  );

  /// `px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm`
  Widget _field(
    TextEditingController controller,
    String hint, {
    int lines = 1,
    bool digitsOnly = false,
    String? suffix,
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
      onChanged: (_) => setState(() {}), // saqlash tugmasi holati sarlavhaga bog'liq
      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceAltLight,
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.dark.withValues(alpha: 0.4),
        ),
        suffixText: suffix,
        suffixStyle: theme.textTheme.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.dark.withValues(alpha: 0.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: border(AppColors.borderLight),
        enabledBorder: border(AppColors.borderLight),
        focusedBorder: border(AppColors.olive),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<(String, String)> items,
    required ValueChanged<String> onChanged,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.5, // disabled:opacity-50
      child: Container(
        height: 44,
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
            onChanged: enabled ? (v) => onChanged(v ?? '') : null,
          ),
        ),
      ),
    );
  }
}
