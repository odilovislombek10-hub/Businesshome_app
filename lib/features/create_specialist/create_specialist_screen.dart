import '../../core/i18n/translate.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/constants/city_labels.dart';
import '../../core/models/market_user.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/video_upload_box.dart';
import 'create_specialist_repository.dart';
import 'create_specialist_texts.dart';

/// Saytning `/specialists/create` sahifasi — `create-specialist.component.ts`.
///
/// To'rt bo'lim: shaxsiy ma'lumot, kasbiy ma'lumot, portfolio, teglar. Profil allaqachon
/// bo'lsa forma to'ldirilgan holda ochiladi va "Yangilash" ga aylanadi (saytdagidek).
/// Roli `designer` yoki `master` bo'lgan foydalanuvchida tur tanlash bloki yashiriladi —
/// `roleLocked()`.
class CreateSpecialistScreen extends StatefulWidget {
  const CreateSpecialistScreen({super.key});

  @override
  State<CreateSpecialistScreen> createState() => _CreateSpecialistScreenState();
}

class _CreateSpecialistScreenState extends State<CreateSpecialistScreen> {
  static const _repo = CreateSpecialistRepository();
  final _scroll = ScrollController();

  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _experience = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _tagInput = TextEditingController();

  String _type = 'designer';
  String _specialization = '';
  String _city = '';
  final _tags = <String>[];
  final _images = <File>[];

  bool _scrolled = false;
  bool _loading = true;
  bool _isEdit = false;
  bool _cityOpen = false;
  bool _submitting = false;
  String? _error;

  /// Foydalanuvchi roli allaqachon dizayner/usta bo'lsa, tur tanlanmaydi.
  bool _roleLocked = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 10;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [_fullName, _phone, _experience, _price, _description, _tagInput]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final user = context.read<AuthService>().user;
    if (user != null) {
      _fullName.text = user.fullName;
      _phone.text = user.phone;
      if (user.role == MarketRole.designer || user.role == MarketRole.master) {
        _roleLocked = true;
        _type = user.role == MarketRole.master ? 'master' : 'designer';
      }
    }

    final profile = await _repo.myProfile();
    if (!mounted) return;
    if (profile != null && profile['id'] != null) {
      _isEdit = true;
      _fullName.text = (profile['fullName'] ?? _fullName.text).toString();
      _phone.text = (profile['phone'] ?? _phone.text).toString();
      _specialization = (profile['specialization'] ?? '').toString();
      _city = (profile['city'] ?? '').toString();
      _description.text = (profile['description'] ?? '').toString();
      final experience = profile['experience'];
      if (experience is num && experience > 0) _experience.text = '${experience.toInt()}';
      final price = profile['priceFrom'];
      if (price is num && price > 0) _price.text = '${price.toInt()}';
      _tags
        ..clear()
        ..addAll([for (final tag in (profile['tags'] as List? ?? const [])) tag.toString()]);
    }
    setState(() => _loading = false);
  }

  List<(String, String)> get _specs =>
      _type == 'designer' ? CreateSpecialistTexts.designerSpecs : CreateSpecialistTexts.masterSpecs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAltLight, // bg-gray-50
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.olive))
          else
            CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverPadding(
                  // `pt-24` = 96, ustiga holat paneli.
                  padding: EdgeInsets.fromLTRB(16, 96 + MediaQuery.paddingOf(context).top, 16, 0),
                  sliver: SliverList.list(children: _page()),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 64)), // pb-16
                const SliverToBoxAdapter(child: SiteFooterSection()),
              ],
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SiteHeader(scrolled: _scrolled, showSearch: false),
          ),
        ],
      ),
    );
  }

  List<Widget> _page() {
    final theme = Theme.of(context);
    return [
      Text(
        CreateSpecialistTexts.title,
        style: theme.textTheme.displaySmall?.copyWith(
          fontSize: 30, // text-3xl
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
      const SizedBox(height: 8), // mb-2
      Text(
        CreateSpecialistTexts.subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.6)),
      ),
      const SizedBox(height: 32), // mb-8
      if (_error case final message?) ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: const Color(0xFFDC2626),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(1, CreateSpecialistTexts.sectionPersonal, _personal()),
            _divider(),
            _section(2, CreateSpecialistTexts.sectionProfessional, _professional()),
            _divider(),
            _section(3, CreateSpecialistTexts.sectionPortfolio, _portfolio()),
            _divider(),
            _section(4, CreateSpecialistTexts.sectionTags, _tagsSection()),
            _divider(),
            Padding(padding: const EdgeInsets.all(24), child: _submitRow()),
          ],
        ),
      ),
    ];
  }

  Widget _divider() => const Divider(height: 1, color: AppColors.borderLight);

  Widget _section(int number, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24), // p-6
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, // w-8 h-8
                height: 32,
                decoration: const BoxDecoration(color: AppColors.olive, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18, // text-lg
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24), // mb-6
          ...children,
        ],
      ),
    );
  }

  // ── 1. Shaxsiy ma'lumotlar ────────────────────────────────────────────────

  List<Widget> _personal() => [
    if (!_roleLocked) ...[
      _label(CreateSpecialistTexts.type),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _choice(
              CreateSpecialistTexts.typeDesigner,
              selected: _type == 'designer',
              onTap: () => setState(() {
                _type = 'designer';
                _specialization = '';
              }),
            ),
          ),
          const SizedBox(width: 12), // gap-3
          Expanded(
            child: _choice(
              CreateSpecialistTexts.typeMaster,
              selected: _type == 'master',
              onTap: () => setState(() {
                _type = 'master';
                _specialization = '';
              }),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20), // space-y-5
    ] else ...[
      _hint(CreateSpecialistTexts.roleLockedNote),
      const SizedBox(height: 20),
    ],
    _label(CreateSpecialistTexts.fullName),
    const SizedBox(height: 8),
    _input(_fullName, hint: CreateSpecialistTexts.fullNamePlaceholder),
    const SizedBox(height: 20),
    _label(CreateSpecialistTexts.phone),
    const SizedBox(height: 8),
    _input(_phone, hint: '+998 90 123 45 67', keyboardType: TextInputType.phone),
    const SizedBox(height: 20),
    _label(CreateSpecialistTexts.city),
    const SizedBox(height: 8),
    _cityPicker(),
  ];

  Widget _cityPicker() {
    final theme = Theme.of(context);
    final selected = CityLabels.options.where((c) => c.$1 == _city).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pressable(
          scale: 1,
          onTap: () => setState(() => _cityOpen = !_cityOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected?.$2 ?? CreateSpecialistTexts.selectCity,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: selected == null
                          ? AppColors.dark.withValues(alpha: 0.3)
                          : AppColors.dark,
                    ),
                  ),
                ),
                SiteIcon(
                  _cityOpen ? SiteIcons.chevronUp : SiteIcons.chevronDown,
                  size: 16,
                  color: AppColors.dark.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
        if (_cityOpen) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 208),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final (code, label) in CityLabels.options)
                  GestureDetector(
                    onTap: () => setState(() {
                      _city = code;
                      _cityOpen = false;
                    }),
                    child: Container(
                      width: double.infinity,
                      color: _city == code
                          ? AppColors.olive.withValues(alpha: 0.1)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          color: _city == code ? AppColors.olive : AppColors.dark,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── 2. Kasbiy ma'lumotlar ─────────────────────────────────────────────────

  List<Widget> _professional() => [
    _label(CreateSpecialistTexts.specialization),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label) in _specs)
          _choice(
            label,
            selected: _specialization == value,
            onTap: () => setState(() => _specialization = value),
            compact: true,
          ),
      ],
    ),
    const SizedBox(height: 20),
    _label(CreateSpecialistTexts.experience),
    const SizedBox(height: 8),
    _input(
      _experience,
      hint: CreateSpecialistTexts.experiencePlaceholder,
      suffix: CreateSpecialistTexts.years,
      keyboardType: TextInputType.number,
      formatters: [FilteringTextInputFormatter.digitsOnly],
    ),
    const SizedBox(height: 20),
    _label(CreateSpecialistTexts.price),
    const SizedBox(height: 8),
    _input(
      _price,
      hint: CreateSpecialistTexts.pricePlaceholder,
      suffix: CreateSpecialistTexts.priceSuffix,
      keyboardType: TextInputType.number,
      formatters: [FilteringTextInputFormatter.digitsOnly],
    ),
    const SizedBox(height: 20),
    _label(CreateSpecialistTexts.description),
    const SizedBox(height: 8),
    _input(_description, hint: CreateSpecialistTexts.descriptionPlaceholder, lines: 4),
  ];

  // ── 3. Portfolio ──────────────────────────────────────────────────────────

  List<Widget> _portfolio() {
    final theme = Theme.of(context);
    return [
      GestureDetector(
        onTap: _pickImages,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32), // p-8
          decoration: BoxDecoration(
            color: AppColors.surfaceAltLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.olive.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SiteIcon(SiteIcons.camera, size: 24, color: AppColors.olive),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                CreateSpecialistTexts.uploadTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CreateSpecialistTexts.uploadHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
      if (_images.isNotEmpty) ...[
        const SizedBox(height: 16),
        // Mobilda `grid-cols-3`.
        _grid(
          columns: 3,
          spacing: 12,
          children: [
            for (var i = 0; i < _images.length; i++)
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Image.file(_images[i], fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => setState(() => _images.removeAt(i)),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SiteIcon(SiteIcons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _hint('${_images.length} ${CreateSpecialistTexts.imagesCount}'),
      ],
      const SizedBox(height: 24), // mt-6
      // Saytda bu blok bor, lekin tanlangan video hech qayerga yuborilmaydi —
      // `videoUrl` signali payload'ga qo'shilmagan. Shu sababli bu yerda ham
      // faqat ko'rinishi bor.
      VideoUploadBox(onChanged: (_) {}),
    ];
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;
    setState(() {
      for (final file in picked) {
        _images.add(File(file.path));
      }
    });
  }

  // ── 4. Teglar ─────────────────────────────────────────────────────────────

  List<Widget> _tagsSection() {
    final theme = Theme.of(context);
    final suggested = CreateSpecialistTexts.suggestedTagList
        .where((tag) => !_tags.contains(tag))
        .toList();
    return [
      Row(
        children: [
          Expanded(child: _input(_tagInput, hint: CreateSpecialistTexts.tagPlaceholder)),
          const SizedBox(width: 8),
          Pressable(
            scale: 0.98,
            onTap: _addTypedTag,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                CreateSpecialistTexts.addTag,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      if (_tags.isNotEmpty) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in _tags)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.olive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.olive,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _tags.remove(tag)),
                      child: const SiteIcon(SiteIcons.close, size: 10, color: AppColors.olive),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
      if (suggested.isNotEmpty) ...[
        const SizedBox(height: 20),
        _label(CreateSpecialistTexts.suggestedTags),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in suggested)
              Pressable(
                scale: 0.98,
                onTap: () => setState(() => _tags.add(tag)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAltLight,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    '+ $tag',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.dark.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ];
  }

  void _addTypedTag() {
    final tag = _tagInput.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _tagInput.clear();
    });
  }

  // ── jo'natish ─────────────────────────────────────────────────────────────

  Widget _submitRow() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Pressable(
          scale: 0.98,
          onTap: _submitting ? null : _submit,
          child: Opacity(
            opacity: _submitting ? 0.6 : 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_submitting) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _isEdit ? CreateSpecialistTexts.update : CreateSpecialistTexts.submit,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Pressable(
          scale: 0.98,
          onTap: () => context.go('/cabinet/dashboard'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              CreateSpecialistTexts.cancel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.dark.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'specialization': _specialization,
      'city': _city,
      'description': _description.text.trim(),
      'phone': _phone.text.trim(),
      'experience': int.tryParse(_experience.text) ?? 0,
      'price_from': int.tryParse(_price.text) ?? 0,
      'tags': _tags,
      if (!_isEdit) 'role': _type,
    };

    try {
      await _repo.save(payload: payload, isEdit: _isEdit);
      await _repo.uploadPortfolio(_images);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _isEdit = true;
        _images.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil saqlandi')));
    } on SpecialistException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = t('completeProfile.errorSave');
      });
    }
  }

  // ── umumiy bo'laklar ──────────────────────────────────────────────────────

  Widget _label(String text) => Text(
    text,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.dark,
    ),
  );

  Widget _hint(String text) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontSize: 12, color: AppColors.dark.withValues(alpha: 0.4)),
  );

  Widget _input(
    TextEditingController controller, {
    required String hint,
    String? suffix,
    int lines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    final theme = Theme.of(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      maxLines: lines,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, color: AppColors.dark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          color: AppColors.dark.withValues(alpha: 0.3),
        ),
        filled: true,
        fillColor: Colors.white,
        suffixText: suffix,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(AppColors.borderLight),
        enabledBorder: border(AppColors.borderLight),
        focusedBorder: border(AppColors.olive),
      ),
    );
  }

  Widget _choice(
    String label, {
    required bool selected,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 16, vertical: compact ? 10 : 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.olive.withValues(alpha: 0.1) : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColors.olive : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.olive : AppColors.dark.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _grid({required int columns, required List<Widget> children, double spacing = 8}) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(i, (i + columns).clamp(0, children.length));
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + columns < children.length ? spacing : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  Expanded(child: j < slice.length ? slice[j] : const SizedBox.shrink()),
                  if (j < columns - 1) SizedBox(width: spacing),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
