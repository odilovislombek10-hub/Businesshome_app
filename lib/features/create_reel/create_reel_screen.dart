import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/media_url.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';

/// Saytning `/reels/create` sahifasi — `create-reel.component.ts`.
///
/// Uch bo'lim: video, e'lonni biriktirish, ma'lumotlar. Yuborilgan reel darrov chiqmaydi —
/// admin tekshiruvidan keyin e'lon qilinadi, shuning uchun oxirida "Reel yuborildi!" ekrani
/// ko'rsatiladi.
///
/// Backend `kind` ni biriktirilgan e'londan oladi (`entityId` saqlanmaydi) — saytdagi izohda
/// ham shunday yozilgan.
class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({super.key});

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  final _scroll = ScrollController();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();

  File? _video;
  String? _videoName;
  List<_MyListing> _listings = const [];
  _MyListing? _attached;

  bool _scrolled = false;
  bool _listingsLoading = true;
  bool _submitting = false;
  bool _published = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 10;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
    _loadListings();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _title.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  /// Biriktirish uchun foydalanuvchining o'z e'lonlari.
  Future<void> _loadListings() async {
    try {
      final res = await ApiClient.instance.get<dynamic>('/market/my-listings/me');
      final data = res.data;
      final items = data is Map ? data['items'] : data;
      if (!mounted) return;
      setState(() {
        _listings = [
          for (final row in (items is List ? items : const []))
            if (row is Map) _MyListing.fromJson(row),
        ];
        _listingsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _listingsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAltLight,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 96 + MediaQuery.paddingOf(context).top, 16, 0),
                sliver: SliverList.list(children: _published ? _successView() : _form()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 64)),
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

  // ── muvaffaqiyat ekrani ────────────────────────────────────────────────────

  List<Widget> _successView() {
    final theme = Theme.of(context);
    return [
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
              child: const Center(
                child: SiteIcon(
                  SiteIcons.check,
                  size: 28,
                  color: Color(0xFF059669),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              CreateReelTexts.successTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CreateReelTexts.successText,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            _primaryButton(CreateReelTexts.successView, () => context.go('/reels')),
            const SizedBox(height: 8),
            _secondaryButton(CreateReelTexts.successAgain, () {
              setState(() {
                _published = false;
                _video = null;
                _videoName = null;
                _attached = null;
                _title.clear();
                _subtitle.clear();
              });
            }),
          ],
        ),
      ),
    ];
  }

  // ── forma ──────────────────────────────────────────────────────────────────

  List<Widget> _form() {
    final theme = Theme.of(context);
    return [
      Text(
        CreateReelTexts.title,
        style: theme.textTheme.displaySmall?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        CreateReelTexts.subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.6)),
      ),
      const SizedBox(height: 32),
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
            _section(CreateReelTexts.sectionVideo, CreateReelTexts.required, _videoSection()),
            const Divider(height: 1, color: AppColors.borderLight),
            _section(CreateReelTexts.sectionAttach, CreateReelTexts.optional, _attachSection()),
            const Divider(height: 1, color: AppColors.borderLight),
            _section(CreateReelTexts.sectionDetails, CreateReelTexts.required, _detailsSection()),
            const Divider(height: 1, color: AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _hint(CreateReelTexts.moderationNote),
                  const SizedBox(height: 16),
                  _primaryButton(
                    _submitting ? CreateReelTexts.publishing : CreateReelTexts.publish,
                    _submitting ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  _secondaryButton(CreateReelTexts.cancel, () => context.go('/reels')),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// Bo'lim sarlavhasi va "Majburiy/Ixtiyoriy" belgisi.
  Widget _section(String title, String badge, List<Widget> children) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badge == CreateReelTexts.required
                      ? AppColors.olive.withValues(alpha: 0.1)
                      : AppColors.surfaceMutedLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: badge == CreateReelTexts.required
                        ? AppColors.olive
                        : AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  List<Widget> _videoSection() {
    final theme = Theme.of(context);
    return [
      GestureDetector(
        onTap: _pickVideo,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
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
                  child: SiteIcon(SiteIcons.video, size: 24, color: AppColors.olive),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _videoName ?? CreateReelTexts.previewEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                // Saytdagi cheklovlar: MP4, vertikal 9:16, 60 soniyagacha, 100 MB.
                'MP4 · vertikal (9:16) · maksimal 60 soniya',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _video = File(picked.path);
      _videoName = picked.name;
      _error = null;
    });
  }

  List<Widget> _attachSection() {
    final theme = Theme.of(context);
    if (_listingsLoading) {
      return [_hint(CreateReelTexts.attachLoading)];
    }
    if (_listings.isEmpty) {
      return [_hint(CreateReelTexts.attachEmpty)];
    }
    return [
      _hint(CreateReelTexts.attachHint),
      const SizedBox(height: 12),
      for (final listing in [null, ..._listings])
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Pressable(
            scale: 0.99,
            onTap: () => setState(() => _attached = listing),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _attached == listing
                    ? AppColors.olive.withValues(alpha: 0.08)
                    : AppColors.surfaceAltLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: _attached == listing ? AppColors.olive : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  if (listing != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: switch (absoluteMediaUrl(listing.coverImage)) {
                          final image? when image.isNotEmpty => AppImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                          ),
                          _ => const ColoredBox(color: AppColors.surfaceMutedLight),
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      listing?.title ?? CreateReelTexts.attachNone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  if (listing != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: listing.kind == 'rent'
                            ? const Color(0xFFDBEAFE)
                            : AppColors.olive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        listing.kind == 'rent'
                            ? CreateReelTexts.badgeRent
                            : CreateReelTexts.badgeSale,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: listing.kind == 'rent' ? const Color(0xFF1D4ED8) : AppColors.olive,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _detailsSection() => [
    _label(CreateReelTexts.titleLabel),
    const SizedBox(height: 8),
    _input(_title, hint: CreateReelTexts.titlePlaceholder),
    const SizedBox(height: 20),
    _label(CreateReelTexts.subtitleLabel),
    const SizedBox(height: 8),
    _input(_subtitle, hint: CreateReelTexts.subtitlePlaceholder, lines: 3),
  ];

  Future<void> _submit() async {
    if (_video == null) {
      setState(() => _error = CreateReelTexts.needVideo);
      return;
    }
    if (_title.text.trim().length < 3) {
      setState(() => _error = CreateReelTexts.needTitle);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final form = FormData();
      form.fields.add(MapEntry('title', _title.text.trim()));
      final subtitle = _subtitle.text.trim();
      if (subtitle.isNotEmpty) form.fields.add(MapEntry('subtitle', subtitle));
      if (_attached?.kind case final kind?) form.fields.add(MapEntry('kind', kind));
      form.files.add(
        MapEntry(
          'video',
          await MultipartFile.fromFile(_video!.path, filename: _videoName ?? 'reel.mp4'),
        ),
      );

      final res = await ApiClient.instance.post<dynamic>('/market/cabinet/reels', data: form);
      if (!mounted) return;
      if (res.statusCode != 200 && res.statusCode != 201) {
        final data = res.data;
        setState(() {
          _submitting = false;
          _error = data is Map && data['detail'] != null
              ? data['detail'].toString()
              : CreateReelTexts.errorGeneric;
        });
        return;
      }
      setState(() {
        _submitting = false;
        _published = true;
      });
      _scroll.jumpTo(0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = CreateReelTexts.errorGeneric;
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

  Widget _input(TextEditingController controller, {required String hint, int lines = 1}) {
    final theme = Theme.of(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      maxLines: lines,
      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, color: AppColors.dark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          color: AppColors.dark.withValues(alpha: 0.3),
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(AppColors.borderLight),
        enabledBorder: border(AppColors.borderLight),
        focusedBorder: border(AppColors.olive),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onTap) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.olive,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton(String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.98,
      onTap: onTap,
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
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.dark.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

/// `uz.ts` dagi `createReel.*` kalitlari.
abstract final class CreateReelTexts {
  static const title = 'Reel yaratish';
  static const subtitle = "Ko'chmas mulk videongizni yuklang va e'lon qiling";
  static const sectionVideo = 'Video';
  static const sectionAttach = "E'lonni biriktirish";
  static const sectionDetails = "Ma'lumotlar";
  static const required = 'Majburiy';
  static const optional = 'Ixtiyoriy';
  static const titleLabel = 'Sarlavha';
  static const titlePlaceholder = 'Masalan: Markazda yangi kvartira';
  static const subtitleLabel = "Qo'shimcha matn";
  static const subtitlePlaceholder = 'Qisqa tavsif (ixtiyoriy)';
  static const attachHint = "Reelni o'z e'loningizga bog'lang (ixtiyoriy)";
  static const attachLoading = 'Yuklanmoqda...';
  static const attachEmpty = "Biriktiriladigan e'lon topilmadi";
  static const attachNone = 'Biriktirmaslik';
  static const badgeRent = 'Ijara';
  static const badgeSale = 'Sotuv';
  static const previewEmpty = 'Video yuklang';
  static const moderationNote = "Reel admin tekshiruvidan so'ng e'lon qilinadi";
  static const needVideo = 'Avval video yuklang';
  static const needTitle = "Sarlavha kamida 3 ta belgi bo'lishi kerak";
  static const publish = "E'lon qilish";
  static const publishing = 'Yuklanmoqda...';
  static const cancel = 'Bekor qilish';
  static const errorGeneric = "Xatolik yuz berdi. Qayta urinib ko'ring";
  static const successTitle = 'Reel yuborildi!';
  static const successText = "Admin tekshiruvidan so'ng e'lon qilinadi";
  static const successView = "Reellarni ko'rish";
  static const successAgain = 'Yana yaratish';
}

/// Biriktirish uchun foydalanuvchining e'loni.
class _MyListing {
  const _MyListing({required this.id, required this.kind, required this.title, this.coverImage});

  final int id;
  final String kind;
  final String title;
  final String? coverImage;

  factory _MyListing.fromJson(Map row) => _MyListing(
    id: (row['id'] as num?)?.toInt() ?? 0,
    kind: row['kind']?.toString() ?? 'secondary',
    title: row['title']?.toString() ?? '',
    coverImage: row['cover_image']?.toString(),
  );
}
