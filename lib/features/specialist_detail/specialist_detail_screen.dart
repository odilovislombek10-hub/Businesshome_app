import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/constants/city_labels.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';
import 'master_services.dart';
import 'specialist_detail_models.dart';
import 'specialist_detail_repository.dart';
import 'specialist_detail_texts.dart';

/// `/designers/:id` va `/masters/:id`.
///
/// Ikkala shablon (`designer-detail` va `master-detail`) 658 qatordan bo'lsa ham, ularni
/// dastur bilan solishtirganda 518 qatori farq qildi. Shuning uchun bitta ekran ishlatilyapti,
/// lekin farqlar aniq belgilangan:
///
/// | | Dizayner | Usta |
/// |---|---|---|
/// | Hero gradienti | zaytun → bronza | bronza → to'q |
/// | Sanoqlar | loyiha, yil tajriba | ish, shoshilinch |
/// | Portfolio sarlavhasi | "Portfolio" / "ta loyiha" | "Bajarilgan ishlar" / "ta rasm" |
/// | Tavsif sarlavhasi | "Men haqimda" | "Usta haqida" |
/// | Teglar sarlavhasi | "Mutaxassisligim" | "Ko'nikmalar" |
/// | Xizmatlar | "Xizmat paketlari" (narx, muddat, ro'yxat) | "Narx jadvali" |
/// | Yon panel | javob vaqti (soat), javob darajasi | kelish vaqti (daq), kafolat, radius |
/// | Qo'shimcha | — | "Shoshilinch chaqiriq" bloki |
enum SpecialistKind {
  designer(
    endpoint: 'designers',
    listPath: '/designers',
    breadcrumb: SpecialistDetailTexts.breadcrumbDesigners,
  ),
  master(
    endpoint: 'masters',
    listPath: '/masters',
    breadcrumb: SpecialistDetailTexts.breadcrumbMasters,
  );

  const SpecialistKind({required this.endpoint, required this.listPath, required this.breadcrumb});

  final String endpoint;
  final String listPath;
  final String breadcrumb;

  bool get isDesigner => this == SpecialistKind.designer;
}

class SpecialistDetailScreen extends StatefulWidget {
  const SpecialistDetailScreen({super.key, required this.id, required this.kind});

  final int id;
  final SpecialistKind kind;

  @override
  State<SpecialistDetailScreen> createState() => _SpecialistDetailScreenState();
}

class _SpecialistDetailScreenState extends State<SpecialistDetailScreen> {
  final _scroll = ScrollController();

  late final SpecialistDetailRepository _repo = SpecialistDetailRepository(
    kind: widget.kind.endpoint,
  );
  late final Future<SpecialistDetail?> _future = _repo.byId(widget.id);
  late final Future<List<SpecialistReview>> _reviews = _repo.reviews(widget.id);
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 10;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAltLight,
      body: Stack(
        children: [
          FutureBuilder<SpecialistDetail?>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.olive));
              }
              final specialist = snapshot.data;
              if (specialist == null) return _notFound();
              return _body(specialist);
            },
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

  Widget _notFound() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              SpecialistDetailTexts.notFound,
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: AppColors.dark),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
              onPressed: () => context.go(widget.kind.listPath),
              child: const Text(SpecialistDetailTexts.backToList),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(SpecialistDetail s) {
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(16, 96 + MediaQuery.paddingOf(context).top, 16, 0),
      children: [
        _breadcrumb(s),
        const SizedBox(height: 16),
        _hero(s),
        const SizedBox(height: 24), // mb-6
        _statsBar(s),
        const SizedBox(height: 16),
        if (s.portfolio.isNotEmpty) ...[_portfolio(s), const SizedBox(height: 16)],
        _about(s),
        const SizedBox(height: 16),
        if (widget.kind.isDesigner) _packages(s) else _priceList(s),
        const SizedBox(height: 16),
        if (!widget.kind.isDesigner) ...[_serviceAreas(), const SizedBox(height: 16)],
        _sidebar(s),
        const SizedBox(height: 16),
        _reviewsBlock(s),
        const SizedBox(height: 48),
        const SiteFooterSection(),
      ],
    );
  }

  Widget _breadcrumb(SpecialistDetail s) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      color: AppColors.dark.withValues(alpha: 0.5),
    );
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/'),
          child: Text(SpecialistDetailTexts.breadcrumbHome, style: muted),
        ),
        const SizedBox(width: 8),
        SiteIcon(SiteIcons.chevronRight, size: 12, color: AppColors.dark.withValues(alpha: 0.3)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.go(widget.kind.listPath),
          child: Text(widget.kind.breadcrumb, style: muted),
        ),
        const SizedBox(width: 8),
        SiteIcon(SiteIcons.chevronRight, size: 12, color: AppColors.dark.withValues(alpha: 0.3)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            s.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.dark,
            ),
          ),
        ),
      ],
    );
  }

  // ── hero ───────────────────────────────────────────────────────────────────

  Widget _hero(SpecialistDetail s) {
    final theme = Theme.of(context);
    // Dizaynerda `from-olive via-olive/90 to-bronze`, ustada `from-bronze via-bronze/90 to-dark`.
    final colors = widget.kind.isDesigner
        ? [AppColors.olive, AppColors.olive.withValues(alpha: 0.9), AppColors.bronze]
        : [AppColors.bronze, AppColors.bronze.withValues(alpha: 0.9), AppColors.dark];

    return Container(
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl), // rounded-3xl
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(s),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.fullName,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 24, // text-2xl mobilda
                        color: Colors.white,
                      ),
                    ),
                    if (s.specialization.isNotEmpty) ...[
                      const SizedBox(height: 8), // mb-2
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          widget.kind.isDesigner
                              ? SpecialistDetailTexts.designerSpec(s.specialization)
                              : s.specialization,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (s.description case final description?) ...[
            const SizedBox(height: 12), // mb-3
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Tez sanoqlar — dizaynerda "loyiha / yil tajriba", ustada "ish / shoshilinch".
          Wrap(
            spacing: 16, // gap-4
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SiteIcon(SiteIcons.star, size: 14, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 6),
                  Text(
                    '${s.rating}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${s.reviewsCount} ${SpecialistDetailTexts.reviews})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              _heroStat(
                '${s.completedProjects}',
                widget.kind.isDesigner
                    ? SpecialistDetailTexts.projects
                    : SpecialistDetailTexts.jobs,
              ),
              if (widget.kind.isDesigner)
                _heroStat('${s.experience}', SpecialistDetailTexts.years)
              else if (s.isAvailable)
                _heroStat('24/7', SpecialistDetailTexts.emergency),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        text: value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        children: [
          TextSpan(
            text: ' $label',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Rasm bo'lmasa saytda ism harflaridan gradientli doira chiziladi.
  Widget _avatar(SpecialistDetail s) {
    final theme = Theme.of(context);
    final avatar = s.avatar;
    final initials = s.fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Stack(
      children: [
        ClipOval(
          child: SizedBox(
            width: 80,
            height: 80,
            child: avatar != null && avatar.isNotEmpty
                ? AppImage(imageUrl: avatar, fit: BoxFit.cover)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        if (s.isVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
              child: const Center(
                child: SiteIcon(SiteIcons.check, size: 12, color: Colors.white, strokeWidth: 3),
              ),
            ),
          ),
      ],
    );
  }

  // ── statistika paneli ──────────────────────────────────────────────────────

  Widget _statsBar(SpecialistDetail s) {
    final rate = s.responseRatePercent;
    return _card(
      null,
      Row(
        children: [
          _stat(
            '${s.completedProjects}',
            widget.kind.isDesigner
                ? SpecialistDetailTexts.completedProjects
                : SpecialistDetailTexts.completedJobs,
          ),
          _stat('${s.experience}+', SpecialistDetailTexts.yearsExperience),
          _stat('${s.rating}', SpecialistDetailTexts.avgRating),
          _stat(rate == null ? '—' : '$rate%', SpecialistDetailTexts.responseRate),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 22, // mobilda kichikroq, saytda `text-3xl`
              color: AppColors.olive,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── portfolio ──────────────────────────────────────────────────────────────

  Widget _portfolio(SpecialistDetail s) {
    final theme = Theme.of(context);
    return _card(
      null,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.kind.isDesigner
                ? SpecialistDetailTexts.portfolio
                : SpecialistDetailTexts.completedWork,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${s.portfolio.length} '
            '${widget.kind.isDesigner ? SpecialistDetailTexts.projectsCount : SpecialistDetailTexts.photosCount}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16), // mb-4
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: s.portfolio.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 240,
                  child: AppImage(imageUrl: s.portfolio[index], fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── tavsif va teglar ───────────────────────────────────────────────────────

  Widget _about(SpecialistDetail s) {
    final theme = Theme.of(context);
    return _card(
      widget.kind.isDesigner ? SpecialistDetailTexts.aboutMe : SpecialistDetailTexts.aboutMaster,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.description case final description?)
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
          if (s.tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              widget.kind.isDesigner
                  ? SpecialistDetailTexts.specializations
                  : SpecialistDetailTexts.skills,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in s.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.olive.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.olive,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── dizayner: xizmat paketlari ─────────────────────────────────────────────

  Widget _packages(SpecialistDetail s) {
    final theme = Theme.of(context);
    return _card(
      SpecialistDetailTexts.servicePackages,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SpecialistDetailTexts.packagesHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20), // mb-5
          if (s.servicePackages.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceAltLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                SpecialistDetailTexts.noPackages,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: AppColors.dark.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            for (final package in s.servicePackages) ...[
              _packageCard(package, s),
              const SizedBox(height: 16), // gap-4
            ],
        ],
      ),
    );
  }

  Widget _packageCard(ServicePackage package, SpecialistDetail s) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20), // p-5
      decoration: BoxDecoration(
        color: package.isRecommended ? AppColors.olive.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: package.isRecommended ? AppColors.olive : AppColors.borderLight,
          width: package.isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (package.isRecommended) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                SpecialistDetailTexts.popular,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            package.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 12), // mt-3
          Text(
            formatNumber(package.price),
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 28, color: AppColors.olive),
          ),
          Text(
            SpecialistDetailTexts.som,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16), // mb-4
          Row(
            children: [
              SiteIcon(SiteIcons.clock, size: 14, color: AppColors.dark.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text(
                '${package.deliveryDays} ${SpecialistDetailTexts.days}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: AppColors.dark.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          if (package.features.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final feature in package.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 8), // space-y-2
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SiteIcon(SiteIcons.check, size: 14, color: AppColors.olive),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: AppColors.dark.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12), // mb-5
          Pressable(
            scale: 0.98,
            onTap: () => _hire(s),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: package.isRecommended ? AppColors.olive : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.olive),
              ),
              child: Text(
                SpecialistDetailTexts.selectPackage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: package.isRecommended ? Colors.white : AppColors.olive,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── usta: narx jadvali ─────────────────────────────────────────────────────

  /// Saytda narx jadvali paketlar bilan bir xil manbadan keladi, faqat boshqacha
  /// ko'rinishda — xizmat nomi, narxi va birligi qatorma-qator.
  Widget _priceList(SpecialistDetail s) {
    final theme = Theme.of(context);
    final rows = masterServiceRows(s);
    return _card(
      null,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SpecialistDetailTexts.priceList,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4), // mb-1
          Text(
            SpecialistDetailTexts.priceListHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          // Saytda bo'sh holat yo'q: jadval bo'sh bo'lsa hech narsa chizilmaydi.
          if (rows.isNotEmpty) const SizedBox(height: 20), // mb-5
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12), // space-y-3
            _serviceRow(rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _serviceRow(ServiceRow service) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16), // p-4
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // items-start
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                if (service.description.isNotEmpty) ...[
                  const SizedBox(height: 2), // mt-0.5
                  Text(
                    service.description,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16), // gap-4
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatNumber(service.price),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bronze,
                ),
              ),
              Text(
                service.unit,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Xizmat ko'rsatadigan hududlar — saytda ham har bir usta uchun bir xil
  /// ro'yxat, mobil ko'rinishda ikki ustun (`grid-cols-2`).
  Widget _serviceAreas() {
    final theme = Theme.of(context);
    const areas = SpecialistDetailTexts.serviceAreas;
    return _card(
      SpecialistDetailTexts.serviceArea,
      Column(
        children: [
          for (var i = 0; i < areas.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 12), // gap-3
            Row(
              children: [
                Expanded(child: _areaChip(areas[i], theme)),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < areas.length
                      ? _areaChip(areas[i + 1], theme)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _areaChip(String area, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // px-3 py-2.5
      decoration: BoxDecoration(
        color: AppColors.bronze.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          SiteIcon(SiteIcons.check, size: 16, color: AppColors.bronze),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              area,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.dark.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── yon panel ──────────────────────────────────────────────────────────────

  Widget _sidebar(SpecialistDetail s) {
    final theme = Theme.of(context);
    final rate = s.responseRatePercent;

    return _card(
      null,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.kind.isDesigner
                ? SpecialistDetailTexts.priceStartsFrom
                : SpecialistDetailTexts.startingFrom,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatNumber(s.priceFrom),
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 28, color: AppColors.olive),
          ),
          Text(
            widget.kind.isDesigner
                ? SpecialistDetailTexts.som
                : SpecialistDetailTexts.somPerService,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),

          // Ustada shoshilinch chaqiriq bloki bor, dizaynerda yo'q.
          if (!widget.kind.isDesigner) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SiteIcon(SiteIcons.zap, size: 14, color: Color(0xFFDC2626)),
                      const SizedBox(width: 6),
                      Text(
                        SpecialistDetailTexts.emergencyCall,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    SpecialistDetailTexts.emergencyHint,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: const Color(0xFFDC2626).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (widget.kind.isDesigner) ...[
            _sidebarRow(SpecialistDetailTexts.responseTime, '1 ${SpecialistDetailTexts.hour}'),
            _sidebarRow(
              SpecialistDetailTexts.responseRate,
              rate == null ? '—' : '$rate%',
              valueColor: const Color(0xFF059669),
            ),
          ] else ...[
            _sidebarRow(SpecialistDetailTexts.arrivalTime, '30-60 ${SpecialistDetailTexts.minute}'),
            _sidebarRow(SpecialistDetailTexts.warranty, '6 ${SpecialistDetailTexts.months}'),
            if (s.city case final city?)
              _sidebarRow(SpecialistDetailTexts.serviceRadius, CityLabels.label(city)),
          ],
          _availabilityRow(s),
          const SizedBox(height: 20),

          Pressable(
            scale: 0.98,
            onTap: () => _hire(s),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                SpecialistDetailTexts.hireMe,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (s.phone case final phone?) ...[
            const SizedBox(height: 8),
            Pressable(
              scale: 0.98,
              onTap: () => launchUrl(Uri.parse('tel:$phone')),
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
                  widget.kind.isDesigner
                      ? SpecialistDetailTexts.call
                      : SpecialistDetailTexts.callNow,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Saytda qo'ng'iroqdan keyin WhatsApp tugmasi turadi.
            Pressable(
              scale: 0.98,
              onTap: () {
                final digits = phone.replaceAll(RegExp(r'\D'), '');
                final message = Uri.encodeComponent(
                  widget.kind.isDesigner
                      ? 'Salom ${s.fullName}, sizning xizmatlaringiz haqida gaplashmoqchi edim'
                      : 'Salom ${s.fullName}, ustachilik xizmatlari kerak edi',
                );
                launchUrl(
                  Uri.parse('https://wa.me/$digits?text=$message'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12), // py-3
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981), // bg-emerald-500
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  'WhatsApp',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sidebarRow(String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // space-y-3
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _availabilityRow(SpecialistDetail s) {
    final theme = Theme.of(context);
    final available = s.isAvailable;
    final label = available
        ? (widget.kind.isDesigner
              ? SpecialistDetailTexts.available
              : SpecialistDetailTexts.availableToday)
        : SpecialistDetailTexts.busy;
    final color = available ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            SpecialistDetailTexts.availability,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── sharhlar ───────────────────────────────────────────────────────────────

  Widget _reviewsBlock(SpecialistDetail s) {
    final theme = Theme.of(context);
    return FutureBuilder<List<SpecialistReview>>(
      future: _reviews,
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <SpecialistReview>[];
        return _card(
          SpecialistDetailTexts.clientReviews,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!s.ratingBreakdown.isEmpty) ...[
                for (final (star, percent) in s.ratingBreakdown.rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          child: Text(
                            '$star',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              color: AppColors.dark.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        const SiteIcon(SiteIcons.star, size: 12, color: Color(0xFFFBBF24)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: percent / 100,
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceMutedLight,
                              valueColor: const AlwaysStoppedAnimation(Color(0xFFFBBF24)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${percent.round()}%',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              color: AppColors.dark.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              if (reviews.isEmpty)
                Text(
                  'Hozircha sharhlar yo\'q',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: AppColors.dark.withValues(alpha: 0.4),
                  ),
                )
              else
                for (final review in reviews) ...[
                  _reviewCard(review),
                  const SizedBox(height: 20), // space-y-5
                ],
            ],
          ),
        );
      },
    );
  }

  Widget _reviewCard(SpecialistReview review) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: (review.authorAvatar?.isNotEmpty ?? false)
                    ? AppImage(imageUrl: review.authorAvatar!, fit: BoxFit.cover)
                    : const ColoredBox(color: AppColors.surfaceMutedLight),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.authorName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  if (review.createdAt case final date?)
                    Text(
                      '${date.day}.${date.month}.${date.year}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: AppColors.dark.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 1; i <= 5; i++)
                  SiteIcon(
                    SiteIcons.star,
                    size: 12,
                    color: i <= review.rating
                        ? const Color(0xFFFBBF24)
                        : AppColors.dark.withValues(alpha: 0.15),
                  ),
              ],
            ),
          ],
        ),
        if (review.text case final text?) ...[
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              height: 1.6,
              color: AppColors.dark.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  // ── umumiy ─────────────────────────────────────────────────────────────────

  /// Saytda "Yollash" chat ochadi; ilovada chat sahifasi hali yo'q, shuning uchun
  /// telefon orqali bog'lanish taklif qilinadi.
  void _hire(SpecialistDetail s) {
    final phone = s.phone;
    if (phone == null || phone.isEmpty) return;
    launchUrl(Uri.parse('tel:$phone'));
  }

  Widget _card(String? title, Widget child) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceMutedLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}
