import '../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/currency_service.dart';
import '../../core/utils/file_download.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/skeleton.dart';
import '../payments/payment_sheet.dart';
import '../payments/saved_cards.dart';
import 'my_home_models.dart';
import 'my_home_repository.dart';
import 'my_home_texts.dart';

/// Saytning `/my-home` sahifasi — `my-home.component.html` dan.
///
/// Foydalanuvchi sotib olgan xonadon: shartnoma, to'lov grafigi, qurilish jarayoni, bozor
/// tahlili va hujjatlar. Ma'lumot quruvchining CRM'idan keladi.
///
/// **Bu yerda yo'q:** saytdagi "qo'lda kiritish" rejimi — u vaqtinchalik yechim (shablonda ham
/// "Kelajakda bu ma'lumotlar avtomatik CRM'dan keladi" deb yozilgan) va o'nlab maydonli forma.
class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  final _repo = const MyHomeRepository();

  late Future<List<MyHomeItem>> _future = _repo.load();

  /// Ro'yxatdan tanlangan mulk; bitta bo'lsa darrov ochiladi.
  int? _selected;
  String _tab = 'overview';

  /// Saytdagi sahifa ichidagi valyuta almashtirgichi (`setCurrency`).
  String _currency = 'uzs';
  bool _linkMode = false;

  /// Bo'limlar paneli saytda `position: sticky`. Flutter'da qadalgan `SliverPersistentHeader`
  /// buni uddalay olmaydi: viewport sliverlarni teskari tartibda chizadi, shuning uchun
  /// panelning tepasidagi tarkib (investitsiya kartalari) uning ustiga chizilib qolardi.
  /// Endi panel ro'yxat ichida o'z joyini egallaydi, tepaga yetganda esa ustiga nusxasi
  /// qo'yiladi — CSS'dagi `sticky` bilan bir xil natija.
  final _scrollController = ScrollController();
  final _tabBarKey = GlobalKey();
  final _scrollKey = GlobalKey();

  /// Panelning ro'yxat boshidan hisoblangan o'rni; panel ekrandan chiqib ketganda ham
  /// oxirgi o'lchov saqlanib qoladi.
  double? _tabBarOffset;
  bool _tabBarStuck = false;

  /// Har bir siljishda panelning o'rni qayta o'lchanadi — tepadagi rasm yuklanib
  /// balandlik o'zgarsa ham qadalish nuqtasi to'g'ri qoladi.
  void _measureTabBar() {
    final scrollBox = _scrollKey.currentContext?.findRenderObject() as RenderBox?;
    if (scrollBox == null || !_scrollController.hasClients) return;
    final tabBox = _tabBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (tabBox != null && tabBox.hasSize) {
      final dy = tabBox.localToGlobal(Offset.zero, ancestor: scrollBox).dy;
      _tabBarOffset = _scrollController.offset + dy;
    }
    final offset = _tabBarOffset;
    if (offset == null) return;
    final stuck = _scrollController.offset >= offset;
    if (stuck != _tabBarStuck) setState(() => _tabBarStuck = stuck);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      backgroundColor: AppColors.surfaceAltLight, // bg-gray-50
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                // `pt-24` — header ostidan boshlanadi.
                padding: const EdgeInsets.only(top: 110),
                child: auth.isLoggedIn ? _body() : _signedOut(),
              ),
            ),
          ),
          // `Positioned` bo'lmasa Stack bolasi butun maydonni egallab, tarkibni yopib qo'yadi.
          const Positioned(top: 0, left: 0, right: 0, child: SiteHeader(showSearch: false)),
        ],
      ),
    );
  }

  Widget _body() => FutureBuilder<List<MyHomeItem>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return _loading();
      if (snapshot.hasError) return _error();

      final items = snapshot.data ?? const <MyHomeItem>[];
      if (_linkMode) return _linkForm();
      if (items.isEmpty) return _empty();

      // Bitta mulk bo'lsa ro'yxat ko'rsatilmaydi — saytda ham shunday.
      final index = _selected ?? (items.length == 1 ? 0 : null);
      if (index == null) return _list(items);
      return _detail(items, index.clamp(0, items.length - 1));
    },
  );

  // ── holatlar ───────────────────────────────────────────────────────────────

  Widget _loading() => ListView(
    padding: const EdgeInsets.all(16),
    children: const [
      SkeletonHeading(width: 192),
      SizedBox(height: 16),
      Skeleton(height: 288, radius: AppRadius.xl),
      SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: Skeleton(height: 112, radius: AppRadius.lg)),
          SizedBox(width: 12),
          Expanded(child: Skeleton(height: 112, radius: AppRadius.lg)),
        ],
      ),
      SizedBox(height: 16),
      Skeleton(height: 56, radius: AppRadius.lg),
      SizedBox(height: 16),
      Skeleton(height: 384, radius: AppRadius.lg),
    ],
  );

  Widget _error() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: _card(
        Column(
          children: [
            _roundIcon(SiteIcons.xCircle, const Color(0xFFFEF2F2), const Color(0xFFDC2626)),
            const SizedBox(height: 20), // mb-5
            Text(MyHomeTexts.errorTitle, style: _titleStyle(20)),
            const SizedBox(height: 8),
            Text(MyHomeTexts.errorText, textAlign: TextAlign.center, style: _mutedStyle()),
            const SizedBox(height: 24), // mb-6
            _button(MyHomeTexts.retry, onTap: () => setState(() => _future = _repo.load())),
          ],
        ),
        padding: 40,
      ),
    ),
  );

  Widget _empty() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      _card(
        Column(
          children: [
            _roundIcon(
              SiteIcons.house,
              AppColors.olive.withValues(alpha: 0.1),
              AppColors.olive,
              size: 80,
            ),
            const SizedBox(height: 24), // mb-6
            Text(MyHomeTexts.emptyTitle, textAlign: TextAlign.center, style: _titleStyle(24)),
            const SizedBox(height: 12), // mb-3
            Text(MyHomeTexts.emptyText, textAlign: TextAlign.center, style: _mutedStyle()),
            const SizedBox(height: 24),
            _button(
              MyHomeTexts.emptySeeProjects,
              onTap: () => context.go('/new-projects'),
              fullWidth: true,
            ),
            const SizedBox(height: 12), // gap-3
            _button(
              MyHomeTexts.emptyLinkManually,
              onTap: () => setState(() => _linkMode = true),
              fullWidth: true,
              outlined: true,
            ),
          ],
        ),
        padding: 40,
      ),
    ],
  );

  Widget _signedOut() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: _card(
        Column(
          children: [
            Text(MyHomeTexts.emptyTitle, textAlign: TextAlign.center, style: _titleStyle(20)),
            const SizedBox(height: 16),
            _button(t('header.login'), onTap: () => context.push('/login')),
          ],
        ),
        padding: 32,
      ),
    ),
  );

  // ── shartnomani bog'lash ───────────────────────────────────────────────────

  final _series = TextEditingController();
  final _number = TextEditingController();
  final _phone = TextEditingController();
  bool _linking = false;
  String? _linkError;
  String? _linkSuccess;

  Future<void> _submitLink() async {
    if (_linking) return;
    setState(() {
      _linking = true;
      _linkError = null;
      _linkSuccess = null;
    });
    try {
      final (linked, number) = await _repo.linkContract(
        passportSeries: _series.text.trim().isEmpty ? null : _series.text.trim(),
        passportNumber: _number.text.trim().isEmpty ? null : _number.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );
      if (!mounted) return;
      if (!linked) {
        setState(() => _linkError = MyHomeTexts.linkNotFound);
        return;
      }
      setState(() {
        _linkSuccess = MyHomeTexts.linkSuccess(number);
        _linkMode = false;
        _future = _repo.load();
      });
    } catch (_) {
      if (mounted) setState(() => _linkError = MyHomeTexts.linkNotFound);
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  Widget _linkForm() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(MyHomeTexts.linkTitle, style: _titleStyle(20)),
              const SizedBox(height: 4),
              Text(MyHomeTexts.linkSubtitle, style: _mutedStyle()),
              const SizedBox(height: 16),
              if (_linkError case final message?) ...[
                _notice(message, const Color(0xFFFEF2F2), const Color(0xFFB91C1C)),
                const SizedBox(height: 16),
              ],
              if (_linkSuccess case final message?) ...[
                _notice(message, const Color(0xFFECFDF5), const Color(0xFF047857)),
                const SizedBox(height: 16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel(theme, MyHomeTexts.linkPassportSeries),
                        _field(_series, hint: 'AD', maxLength: 2, upperCase: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12), // gap-3
                  Expanded(
                    flex: 2, // col-span-2
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel(theme, MyHomeTexts.linkPassportNumber),
                        _field(_number, hint: '6156012', maxLength: 7, digitsOnly: true),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.borderLight)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      MyHomeTexts.linkOr.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        letterSpacing: 1,
                        color: AppColors.dark.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.borderLight)),
                ],
              ),
              const SizedBox(height: 16),
              _fieldLabel(theme, MyHomeTexts.linkPhone),
              _field(_phone, hint: '+998901234567'),
              const SizedBox(height: 4),
              Text(
                MyHomeTexts.linkPhoneHint,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _button(
                      MyHomeTexts.linkCancel,
                      onTap: () => setState(() => _linkMode = false),
                      outlined: true,
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 8), // gap-2
                  Expanded(
                    child: _button(
                      _linking ? MyHomeTexts.linkSearching : MyHomeTexts.linkSubmit,
                      onTap: _linking ? null : _submitLink,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── mulklar ro'yxati ───────────────────────────────────────────────────────

  Widget _list(List<MyHomeItem> items) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(MyHomeTexts.listTitle, style: _displayStyle(24)),
      const SizedBox(height: 4),
      Text(MyHomeTexts.listSubtitle(items.length), style: _mutedStyle()),
      const SizedBox(height: 24), // mb-6
      const SavedCardsSection(),
      const SizedBox(height: 24),
      for (final (index, item) in items.indexed) ...[
        _listCard(item, index),
        const SizedBox(height: 20), // gap-5
      ],
      const SizedBox(height: 44),
      const SiteFooterSection(),
    ],
  );

  Widget _listCard(MyHomeItem item, int index) {
    final theme = Theme.of(context);
    final cover = item.property?.coverImage;
    return Pressable(
      onTap: () => setState(() => _selected = index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl), // rounded-3xl
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160, // h-40
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (cover != null && cover.isNotEmpty)
                    AppImage(imageUrl: cover, fit: BoxFit.cover)
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.olive.withValues(alpha: 0.1), AppColors.cream],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          item.isShop ? '🏪' : '🏠',
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12, // top-3 left-3
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xE6FFFFFF), // bg-white/90
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        item.isShop ? MyHomeTexts.shop : MyHomeTexts.apartment,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
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
                  Text(item.labelFor(index), style: _titleStyle(18)),
                  Text(
                    item.property?.projectName.isNotEmpty == true
                        ? item.property!.projectName
                        : (item.contract?.developerName ?? ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _mutedStyle(),
                  ),
                  const SizedBox(height: 8), // mt-2
                  Text(
                    [
                      if (item.property?.area case final area?) '${formatNumber(area)} m²',
                      if (item.property?.floor case final floor?)
                        '$floor-${t('propertyCard.floor')}',
                      if (item.contract?.number.isNotEmpty == true) '№${item.contract!.number}',
                    ].join(' · '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12), // mt-3 pt-3
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              MyHomeTexts.totalPriceShort,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                color: AppColors.dark.withValues(alpha: 0.4),
                              ),
                            ),
                            Text(
                              _money(item.finance?.totalPrice),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        MyHomeTexts.open,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.olive,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── tafsilot ───────────────────────────────────────────────────────────────

  Widget _detail(List<MyHomeItem> items, int index) {
    final item = items[index];
    // Saytda bo'limlar paneli `sticky top-[72px]` — pastga surilganda tepada qolib turadi,
    // shuning uchun `CustomScrollView` + qadalgan sarlavha ishlatiladi.
    final scroll = CustomScrollView(
      key: _scrollKey,
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList.list(
            children: [
              if (items.length > 1) ...[
                GestureDetector(
                  onTap: () => setState(() => _selected = null),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SiteIcon(SiteIcons.chevronLeft, size: 16),
                      const SizedBox(width: 8),
                      Text(MyHomeTexts.backToList, style: _mutedStyle()),
                    ],
                  ),
                ),
                const SizedBox(height: 16), // mb-4
              ],
              Text(MyHomeTexts.title, style: _displayStyle(24)),
              const SizedBox(height: 4),
              Text(MyHomeTexts.subtitle, style: _mutedStyle()),
              const SizedBox(height: 12),
              _currencyToggle(),
              const SizedBox(height: 24), // mb-6
              const SavedCardsSection(),
              const SizedBox(height: 24),
              if (items.length > 1) ...[
                _propertyChips(items, index),
                const SizedBox(height: 24), // mb-6
              ],
              if (item.property case final property?) ...[
                _propertySummary(property, item.construction),
                const SizedBox(height: 24),
              ],
              if (item.finance case final finance?) ...[
                _contractStatusCard(item, finance),
                const SizedBox(height: 24),
                _investmentCards(finance),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: KeyedSubtree(key: _tabBarKey, child: _tabBarBar()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          sliver: SliverList.list(children: _tabContent(item)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 64)), // pb-16
        const SliverToBoxAdapter(child: SiteFooterSection()),
      ],
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _measureTabBar();
        return false;
      },
      child: Stack(
        children: [
          Positioned.fill(child: scroll),
          if (_tabBarStuck) Positioned(top: 0, left: 0, right: 0, child: _tabBarBar()),
        ],
      ),
    );
  }

  /// Panel va uning atrofidagi bo'shliq — ro'yxatdagi nusxa ham, tepadagisi ham shu.
  Widget _tabBarBar() => ColoredBox(
    // Ostidagi tarkib panel orqasidan ko'rinmasligi uchun fon to'ldiriladi.
    color: AppColors.surfaceAltLight,
    child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: _tabBar()),
  );

  /// Valyuta almashtirgich — saytdagi sarlavha o'ngidagi tugmachalar.
  Widget _currencyToggle() {
    final theme = Theme.of(context);
    Widget option(String value, String label) {
      final active = _currency == value;
      return Pressable(
        onTap: () => setState(() => _currency = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // px-3 py-1.5
          decoration: BoxDecoration(
            color: active ? AppColors.olive : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12, // text-xs
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(2), // p-0.5
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [option('uzs', MyHomeTexts.soum), option('usd', r'$')],
        ),
      ),
    );
  }

  /// Bir nechta mulk bo'lsa tez almashtirish chiplari — saytdagi `selectProperty`.
  Widget _propertyChips(List<MyHomeItem> items, int selected) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          MyHomeTexts.myProperties(items.length).toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppColors.dark.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8), // mb-2
        Wrap(
          spacing: 8, // gap-2
          runSpacing: 8,
          children: [
            for (final (index, item) in items.indexed)
              Pressable(
                onTap: () => setState(() => _selected = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: index == selected ? AppColors.olive : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: index == selected ? AppColors.olive : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.isShop ? '\u{1F3EA}' : '\u{1F3E0}'),
                      const SizedBox(width: 8), // gap-2
                      Text(
                        item.labelFor(index),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: index == selected
                              ? Colors.white
                              : AppColors.dark.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Xonadon xulosasi — rasm, nomi, manzili, holat nishonchasi va to'rt ko'rsatkich.
  Widget _propertySummary(MyHomeProperty property, MyHomeConstruction? construction) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl), // rounded-3xl
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 224, // h-56
            child: property.coverImage == null || property.coverImage!.isEmpty
                ? ColoredBox(
                    color: AppColors.surfaceMutedLight,
                    child: Center(
                      child: Text(
                        property.isShop ? '🏪' : '🏠',
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                  )
                : AppImage(imageUrl: property.coverImage!, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(24), // p-6
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.projectName.isEmpty ? '—' : property.projectName,
                  style: _displayStyle(24),
                ),
                const SizedBox(height: 4),
                Text(property.address.isEmpty ? '—' : property.address, style: _mutedStyle()),
                if (property.status.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.olive.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.olive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          property.status,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.olive,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24), // mb-6
                // `grid-cols-2` — mobil ko'rinishda ikki ustun.
                Wrap(
                  runSpacing: 16,
                  children: [
                    _fact(MyHomeTexts.block, property.block),
                    _fact(MyHomeTexts.floor, property.floor?.toString()),
                    _fact(
                      MyHomeTexts.apartmentNo,
                      property.apartmentNumber.isEmpty ? null : '№${property.apartmentNumber}',
                    ),
                    _fact(MyHomeTexts.rooms, property.rooms?.toString()),
                    _fact(
                      MyHomeTexts.area,
                      property.area == null ? null : '${formatNumber(property.area!)} m²',
                      wide: true,
                    ),
                    _fact(MyHomeTexts.delivery, property.deliveryDate, wide: true),
                  ],
                ),
                if (construction != null) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          MyHomeTexts.constructionProgress.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.dark.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Text(
                        '${construction.progress}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.olive,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _bar(construction.progress / 100, AppColors.olive),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fact(String label, String? value, {bool wide = false}) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = Theme.of(context);
      return SizedBox(
        width: wide ? double.infinity : (MediaQuery.sizeOf(context).width - 32 - 48 - 16) / 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                color: AppColors.dark.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 2), // mt-0.5
            Text(
              value == null || value.isEmpty ? '—' : value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16, // text-base
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      );
    },
  );

  /// `bg-gradient-to-br from-dark to-olive` — qoldiq, keyingi to'lov va to'langan foiz.
  Widget _contractStatusCard(MyHomeItem item, MyHomeFinance finance) {
    final theme = Theme.of(context);
    final number = item.contract?.number ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.dark, AppColors.olive],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  number.isNotEmpty
                      ? '${MyHomeTexts.contractWord} №$number'
                      : (item.property?.projectName ?? MyHomeTexts.title),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              if (item.contract?.status.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    item.contract!.status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20), // mb-5
          Wrap(
            spacing: 32, // gap-x-8
            runSpacing: 8,
            children: [
              _whiteFact(theme, MyHomeTexts.remaining, _money(finance.remainingAmount)),
              if (finance.nextPaymentDate.isNotEmpty)
                _whiteFact(
                  theme,
                  MyHomeTexts.nextPayment,
                  MyHomeTexts.date(finance.nextPaymentDate),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: formatNumber(finance.nextPaymentAmount)),
                      TextSpan(
                        text: ' ${MyHomeTexts.soum}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 30, // text-3xl
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${finance.paidPercent}%',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20, // text-xl
                  fontWeight: FontWeight.w700,
                  color: AppColors.cream,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: finance.paidPercent / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.cream),
            ),
          ),
        ],
      ),
    );
  }

  Widget _whiteFact(ThemeData theme, String label, String value) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: '$label: '),
        TextSpan(
          text: value,
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ],
    ),
    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
  );

  Widget _investmentCards(MyHomeFinance f) {
    final growth = f.growth;
    final hasMarket = f.currentMarketPrice > 0;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard(MyHomeTexts.bought, _money(f.totalPrice), '${_money(f.pricePerM2)}/m²'),
        _statCard(
          MyHomeTexts.currentMarket,
          _money(f.currentMarketPrice),
          '${_money(f.currentPricePerM2)}/m²',
        ),
        if (hasMarket && f.currentMarketPrice != f.totalPrice)
          _statCard(
            MyHomeTexts.investmentGrowth,
            '${growth >= 0 ? '+' : ''}${_money(growth)}',
            MyHomeTexts.percent(f.growthPercent),
            tone: growth >= 0 ? _Tone.positive : _Tone.negative,
          )
        else if (hasMarket)
          _statCard(MyHomeTexts.investmentGrowth, '0%', MyHomeTexts.priceUnchanged)
        else
          _statCard(MyHomeTexts.investmentGrowth, '', MyHomeTexts.notEnoughMarket),
        if (f.districtGrowthMonths > 0)
          _statCard(
            MyHomeTexts.districtGrowth,
            MyHomeTexts.percent(f.districtGrowthPercent),
            MyHomeTexts.lastMonths(f.districtGrowthMonths),
          )
        else
          _statCard(MyHomeTexts.districtGrowth, '', MyHomeTexts.noDistrictHistory),
      ],
    );
  }

  /// Saytda uch joyda uchraydi va o'lchamlari har xil: umumiy ko'rinishda `p-5 text-xl` va fon
  /// yarim shaffof (`bg-emerald-50/50`), to'lovlarda `p-4 text-lg` va fon to'liq, bozor
  /// tahlilida esa kartalar bitta ustunda (`grid-cols-1`). Shuning uchun farqlar parametr.
  Widget _statCard(
    String label,
    String value,
    String hint, {
    _Tone tone = _Tone.neutral,
    double padding = 20, // p-5
    double valueSize = 20, // text-xl
    double hintSize = 12, // text-xs
    bool solid = false,
    bool fullWidth = false,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final (background, border, text) = switch (tone) {
      _Tone.positive => (
        solid ? const Color(0xFFECFDF5) : const Color(0x80ECFDF5),
        const Color(0xFFD1FAE5),
        const Color(0xFF047857),
      ),
      _Tone.negative => (const Color(0x80FFF1F2), const Color(0xFFFECDD3), const Color(0xFFBE123C)),
      _Tone.warning => (
        const Color(0xFFFFFBEB), // bg-amber-50
        const Color(0xFFFEF3C7), // border-amber-100
        const Color(0xFFB45309), // text-amber-700
      ),
      _Tone.neutral => (Colors.white, AppColors.borderLight, AppColors.dark),
    };
    return Container(
      width: fullWidth
          ? double.infinity
          : (MediaQuery.sizeOf(context).width - 32 - 12) / 2, // grid-cols-2 gap-3
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tone == _Tone.neutral ? AppColors.dark.withValues(alpha: 0.5) : text,
            ),
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(height: 4), // mt-1
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: valueSize,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
          ],
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 2), // mt-0.5
            Text(
              hint,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: hintSize,
                color: tone == _Tone.neutral
                    ? AppColors.dark.withValues(alpha: 0.4)
                    : text.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (trailing != null) ...[const SizedBox(height: 8), trailing], // mt-2
        ],
      ),
    );
  }

  /// Gorizontal suriladigan bo'limlar paneli.
  Widget _tabBar() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (key, label) in MyHomeTexts.tabs)
              Pressable(
                onTap: () => setState(() => _tab = key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: _tab == key ? AppColors.olive.withValues(alpha: 0.05) : null,
                    border: Border(
                      bottom: BorderSide(
                        color: _tab == key ? AppColors.olive : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _tab == key ? AppColors.olive : AppColors.dark.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _tabContent(MyHomeItem item) => switch (_tab) {
    'contract' => _contractTab(item),
    'payments' => _paymentsTab(item),
    'construction' => _constructionTab(item),
    'market' => _marketTab(item),
    'documents' => _documentsTab(item),
    _ => _overviewTab(item),
  };

  // ── 1. Umumiy ──────────────────────────────────────────────────────────────

  List<Widget> _overviewTab(MyHomeItem item) {
    final property = item.property;
    if (property == null) return const [];
    final theme = Theme.of(context);
    return [
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(MyHomeTexts.propertyInfo, style: _titleStyle(16)),
            const SizedBox(height: 16),
            _row(MyHomeTexts.project, property.projectName),
            _row(MyHomeTexts.address, property.address),
            _row(MyHomeTexts.block, property.block),
            _row(MyHomeTexts.entrance, property.entrance),
            _row(MyHomeTexts.floor, property.floor?.toString()),
            _row(
              MyHomeTexts.apartmentNo,
              property.apartmentNumber.isEmpty ? null : '№${property.apartmentNumber}',
            ),
            _row(
              MyHomeTexts.area,
              property.area == null ? null : '${formatNumber(property.area!)} m²',
            ),
            _row(MyHomeTexts.rooms, property.rooms?.toString()),
            if (property.layoutImage case final layout? when layout.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 16),
              Text(
                MyHomeTexts.layout,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.dark.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AppImage(imageUrl: layout, fit: BoxFit.contain),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(MyHomeTexts.statusSection, style: _titleStyle(16)),
            const SizedBox(height: 16),
            if (item.contract case final contract?)
              _tile(
                '${MyHomeTexts.contractWord} ${contract.status}',
                const Color(0xFFECFDF5),
                const Color(0xFF047857),
              ),
            if (item.construction case final construction?) ...[
              const SizedBox(height: 12),
              _tile(
                MyHomeTexts.construction,
                const Color(0xFFEFF6FF),
                const Color(0xFF1D4ED8),
                trailing: '${construction.progress}%',
              ),
            ],
            if (item.finance case final finance?) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _softBox(MyHomeTexts.delivery, property.deliveryDate)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _softBox(
                      MyHomeTexts.nextPayment,
                      MyHomeTexts.date(finance.nextPaymentDate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _softBox(
                      MyHomeTexts.remainingSum,
                      _money(finance.remainingAmount),
                      big: true,
                    ),
                  ),
                  // Saytda ham to'lash tugmasi faqat qoldiq bo'lganda chiqadi.
                  if (finance.remainingAmount > 0) ...[
                    const SizedBox(width: 12),
                    _button(
                      MyHomeTexts.pay,
                      onTap: () => _openPay(item, finance.nextPaymentAmount),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    ];
  }

  // ── 2. Shartnoma ───────────────────────────────────────────────────────────

  List<Widget> _contractTab(MyHomeItem item) {
    final contract = item.contract;
    if (contract == null) return [_emptyBox(MyHomeTexts.noDocuments)];
    final theme = Theme.of(context);
    return [
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MyHomeTexts.contractNumber.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: AppColors.dark.withValues(alpha: 0.5),
                        ),
                      ),
                      Text(contract.number.isEmpty ? '—' : contract.number, style: _titleStyle(20)),
                    ],
                  ),
                ),
                if (contract.status.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      contract.status,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20), // mb-5
            _row(MyHomeTexts.signedAt, MyHomeTexts.date(contract.date)),
            _row(MyHomeTexts.buyer, contract.buyerFullName),
            _row(MyHomeTexts.developer, contract.developerName),
            _row(MyHomeTexts.totalAmount, _money(item.finance?.totalPrice)),
            _row(MyHomeTexts.paymentType, contract.paymentType),
            if (contract.warrantyMonths case final months?)
              _row(MyHomeTexts.warranty, MyHomeTexts.warrantyMonths(months)),
            if (contract.latePaymentTerms.isNotEmpty)
              _row(MyHomeTexts.lateTerms, contract.latePaymentTerms),
            if (contract.additionalNotes.isNotEmpty)
              _row(MyHomeTexts.notes, contract.additionalNotes),
          ],
        ),
      ),
      if (contract.pdfUrl case final pdf? when pdf.isNotEmpty) ...[
        const SizedBox(height: 16),
        _contractPdfCard(pdf),
      ],
    ];
  }

  /// Saytdagi "Shartnoma PDF" kartasi — qizil hujjat belgisi va ikki tugma.
  Widget _contractPdfCard(String pdf) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, // w-12 h-12
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2), // bg-red-50
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Center(
                  child: SiteIcon(SiteIcons.document, size: 24, color: Color(0xFFDC2626)),
                ),
              ),
              const SizedBox(width: 12), // gap-3
              Text(MyHomeTexts.contractPdf, style: _titleStyle(14)),
            ],
          ),
          const SizedBox(height: 16), // mb-4
          _button(
            MyHomeTexts.view,
            onTap: () => _download(pdf, 'Shartnoma.pdf'),
            fullWidth: true,
            dark: true,
            compact: true,
          ),
          const SizedBox(height: 8), // space-y-2
          _button(
            MyHomeTexts.download,
            onTap: () => _download(pdf, 'Shartnoma.pdf', save: true),
            fullWidth: true,
            outlined: true,
            compact: true,
          ),
        ],
      ),
    );
  }

  /// Grafik qatoridagi kichik "To'lash" tugmasi (`px-3 py-1.5 text-xs font-semibold`).
  Widget _payChip({VoidCallback? onTap}) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.olive,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        MyHomeTexts.pay,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
  );

  // ── 3. To'lov grafigi ──────────────────────────────────────────────────────

  List<Widget> _paymentsTab(MyHomeItem item) {
    final finance = item.finance;
    if (finance == null) return [_emptyBox(MyHomeTexts.noPayments)];
    final theme = Theme.of(context);
    final paid = item.schedule.where((s) => s.status == 'paid').length;

    return [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _statCard(
            MyHomeTexts.totalLabel,
            _money(finance.totalPrice),
            '',
            padding: 16,
            valueSize: 18,
          ),
          _statCard(
            MyHomeTexts.paidWithPercent(finance.paidPercent),
            _money(finance.paidAmount),
            '',
            tone: _Tone.positive,
            solid: true,
            padding: 16,
            valueSize: 18,
          ),
          _statCard(
            MyHomeTexts.remainingLabel,
            _money(finance.remainingAmount),
            '',
            padding: 16,
            valueSize: 18,
          ),
          // Saytda "To'lash" tugmasi aynan shu kartaning ichida turadi, alohida emas.
          _statCard(
            MyHomeTexts.nextLabel,
            _money(finance.nextPaymentAmount),
            MyHomeTexts.date(finance.nextPaymentDate),
            tone: _Tone.warning,
            padding: 16,
            valueSize: 18,
            hintSize: 10, // text-[10px]
            trailing: finance.remainingAmount > 0
                ? SizedBox(
                    width: double.infinity,
                    child: _payChip(onTap: () => _openPay(item, finance.nextPaymentAmount)),
                  )
                : null,
          ),
        ],
      ),
      const SizedBox(height: 16), // space-y-4
      if (item.schedule.isNotEmpty) ...[
        Row(
          children: [
            _legend(const Color(0xFF10B981), MyHomeTexts.paidMonths(paid)),
            const SizedBox(width: 16),
            _legend(
              const Color(0xFFD1D5DB),
              MyHomeTexts.remainingMonths(item.schedule.length - paid),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final row in item.schedule) ...[
          _card(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${row.n}. ${MyHomeTexts.date(row.date)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: AppColors.dark.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(_money(row.amount), style: _titleStyle(16)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      row.paidAmount > 0 ? _money(row.paidAmount) : '—',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14, // text-sm
                        fontWeight: FontWeight.w700, // font-bold
                        color: switch (row.status) {
                          'paid' => const Color(0xFF059669), // text-emerald-600
                          'partial' => AppColors.olive, // text-primary
                          _ => AppColors.dark.withValues(alpha: 0.3), // text-dark/30
                        },
                      ),
                    ),
                    // Saytdagi mobil kartada to'lanmagan qatorda "To'lash", to'langanida esa
                    // chek havolasi turadi — ikkalasi bir vaqtda ko'rinmaydi.
                    if (row.status != 'paid')
                      Padding(
                        padding: const EdgeInsets.only(top: 4), // mt-1
                        child: _payChip(onTap: () => _openPay(item, row.amount - row.paidAmount)),
                      )
                    else if (row.receiptUrl case final receipt? when receipt.isNotEmpty)
                      GestureDetector(
                        onTap: () => _download(receipt, 'Kvitansiya-${row.date}.pdf', save: true),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4), // mt-1
                          child: Text(
                            MyHomeTexts.downloadReceipt,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.olive,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            padding: 16,
          ),
          const SizedBox(height: 8),
        ],
      ],
      if (item.payments.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(MyHomeTexts.paymentHistory, style: _titleStyle(16)),
        const SizedBox(height: 12),
        for (final payment in item.payments) ...[
          _card(
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MyHomeTexts.date(payment.date),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: AppColors.dark.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(_money(payment.amount), style: _titleStyle(16)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Builder(
                      builder: (context) {
                        final (label, foreground, background) = MyHomeTexts.paymentStatus(
                          payment.status,
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: foreground,
                            ),
                          ),
                        );
                      },
                    ),
                    if (payment.receiptUrl case final receipt? when receipt.isNotEmpty)
                      GestureDetector(
                        onTap: () =>
                            _download(receipt, 'Kvitansiya-${payment.date}.pdf', save: true),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4), // mt-1
                          child: Text(
                            MyHomeTexts.receipt,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.olive,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            padding: 16,
          ),
          const SizedBox(height: 8),
        ],
      ],
      if (item.schedule.isEmpty && item.payments.isEmpty) _emptyBox(MyHomeTexts.noPayments),
    ];
  }

  // ── 4. Qurilish jarayoni ───────────────────────────────────────────────────

  List<Widget> _constructionTab(MyHomeItem item) {
    final construction = item.construction;
    if (construction == null) return [_emptyBox(MyHomeTexts.noPayments)];
    final theme = Theme.of(context);
    return [
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              MyHomeTexts.overallProgress.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${construction.progress}%', style: _displayStyle(36)),
                const SizedBox(width: 12),
                if (construction.pacePercent > 0)
                  Text(
                    MyHomeTexts.fasterBy(construction.pacePercent),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF059669),
                    ),
                  )
                else if (construction.pacePercent < 0)
                  Text(
                    MyHomeTexts.slowerBy(construction.pacePercent),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _bar(construction.progress / 100, AppColors.olive),
            if (construction.lastUpdate.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                MyHomeTexts.updatedAt(MyHomeTexts.date(construction.lastUpdate)),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
      if (construction.stages.isNotEmpty) ...[
        const SizedBox(height: 16),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(MyHomeTexts.stages, style: _titleStyle(16)),
              const SizedBox(height: 16),
              for (final (name, progress) in construction.stages) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    Text(
                      '$progress%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: progress == 100
                            ? const Color(0xFF059669)
                            : AppColors.dark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _bar(progress / 100, progress == 100 ? const Color(0xFF10B981) : AppColors.olive),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
      if (construction.photos.isNotEmpty) ...[
        const SizedBox(height: 16),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(MyHomeTexts.photoGallery, style: _titleStyle(16)),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final size = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final photo in construction.photos)
                        SizedBox(
                          width: size,
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: AppImage(imageUrl: photo, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
      if (construction.aiSummary.isNotEmpty) ...[
        const SizedBox(height: 16),
        _aiBox(MyHomeTexts.aiAnalysis, construction.aiSummary),
      ],
    ];
  }

  // ── 5. Bozor analizi ───────────────────────────────────────────────────────

  List<Widget> _marketTab(MyHomeItem item) {
    final finance = item.finance;
    if (finance == null) return [_emptyBox(MyHomeTexts.notEnoughMarket)];
    final market = item.market;
    final theme = Theme.of(context);
    return [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          // Saytda bu bo'lim mobilda `grid-cols-1` — kartalar to'liq kenglikda, ustma-ust.
          _statCard(MyHomeTexts.yourPrice, _money(finance.totalPrice), '', fullWidth: true),
          _statCard(
            MyHomeTexts.currentPrice,
            _money(finance.currentMarketPrice),
            '',
            fullWidth: true,
          ),
          _statCard(
            MyHomeTexts.potentialProfit,
            '+${_money(finance.growth)}',
            MyHomeTexts.percent(finance.growthPercent),
            tone: _Tone.positive,
            solid: true,
            fullWidth: true,
          ),
        ],
      ),
      if (market != null && market.history.isNotEmpty) ...[
        const SizedBox(height: 16),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(MyHomeTexts.priceDynamics, style: _titleStyle(16)),
              const SizedBox(height: 12),
              SizedBox(height: 140, child: CustomPaint(painter: _PricePainter(market.history))),
            ],
          ),
        ),
      ],
      if (market != null && market.similar.isNotEmpty) ...[
        const SizedBox(height: 16),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(MyHomeTexts.similarApartments, style: _titleStyle(16)),
              const SizedBox(height: 12),
              for (final similar in market.similar) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            similar.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark,
                            ),
                          ),
                          Text(
                            [
                              if (similar.area case final area?) '${formatNumber(area)} m²',
                              if (similar.rooms case final rooms?)
                                '$rooms-${t('propertyCard.rooms')}',
                              ?similar.district,
                            ].join(' · '),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              color: AppColors.dark.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _money(similar.price),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                        if (similar.pricePerM2 case final perM2?)
                          Text(
                            '${_money(perM2)}/m²',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              color: AppColors.dark.withValues(alpha: 0.5),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
      if (market != null && market.aiInsight.isNotEmpty) ...[
        const SizedBox(height: 16),
        _aiBox(MyHomeTexts.aiMarketInsight, market.aiInsight),
      ],
    ];
  }

  // ── 6. Hujjatlar ───────────────────────────────────────────────────────────

  List<Widget> _documentsTab(MyHomeItem item) {
    if (item.documents.isEmpty) return [_emptyBox(MyHomeTexts.noDocuments)];
    final theme = Theme.of(context);
    return [
      for (final (key, label, icon) in MyHomeTexts.documentCategories)
        if (item.documents.where((d) => d.category == key).toList() case final docs
            when docs.isNotEmpty) ...[
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(label, style: _titleStyle(16)),
                    const SizedBox(width: 8),
                    Text(
                      '(${docs.length})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: AppColors.dark.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final doc in docs) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.dark,
                              ),
                            ),
                            Text(
                              '${MyHomeTexts.date(doc.date)} · ${MyHomeTexts.fileSize(doc.sizeBytes)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 12,
                                color: AppColors.dark.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _download(doc.url, doc.name),
                        child: Text(
                          MyHomeTexts.download,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.olive,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
    ];
  }

  // ── umumiy qismlar ─────────────────────────────────────────────────────────

  /// Saytdagi `openPay()` — taklif qilinadigan summa keyingi to'lov miqdori.
  Future<void> _openPay(MyHomeItem item, num suggested) async {
    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentSheet(
        amount: suggested,
        outstanding: item.finance?.remainingAmount ?? 0,
        devCode: item.devCode,
        contractId: item.contractId,
      ),
    );
    // To'lov o'tgan bo'lsa shartnoma ma'lumoti yangilanadi.
    if (paid == true && mounted) setState(() => _future = _repo.load());
  }

  /// Chek, shartnoma va hujjatlar `Authorization` talab qiladi — shuning uchun oddiy havola
  /// bilan ochilmaydi, `downloadAndOpen` orqali yuklab olinadi.
  Future<void> _download(String url, String fileName, {bool save = false}) async {
    if (url.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(MyHomeTexts.downloading)));
    final ok = await downloadAndOpen(url, fileName, saveToDownloads: save);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text(MyHomeTexts.downloadFailed)));
    }
  }

  /// Saytdagi `fmtMoney` — so'mda `495 600 000 so'm`, dollarda `\$39,648`.
  String _money(num? value) {
    if (value == null) return '—';
    if (_currency == 'usd') {
      final usd = (value / CurrencyService.instance.rate).round();
      return '\$${formatNumber(usd).replaceAll(' ', ',')}';
    }
    return '${formatNumber(value)} ${MyHomeTexts.soum}';
  }

  /// Saytda karta sarlavhalari `font-semibold` (600); `font-bold` faqat sahifa sarlavhasida.
  TextStyle? _titleStyle(double size) => Theme.of(context).textTheme.titleMedium?.copyWith(
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: AppColors.dark,
  );

  TextStyle? _displayStyle(double size) => Theme.of(context).textTheme.displaySmall?.copyWith(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: AppColors.dark,
  );

  TextStyle? _mutedStyle() => Theme.of(
    context,
  ).textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.6));

  Widget _card(Widget child, {double padding = 24}) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: child,
  );

  Widget _row(String label, String? value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10), // py-2.5
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value == null || value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(String label, Color background, Color foreground, {String? trailing}) => Container(
    padding: const EdgeInsets.all(12), // p-3
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.md)),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: foreground),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: foreground),
          )
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
          ),
      ],
    ),
  );

  Widget _softBox(String label, String value, {bool big = false}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '—' : value,
            style: big
                ? _titleStyle(18)
                : theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 12,
          color: AppColors.dark.withValues(alpha: 0.5),
        ),
      ),
    ],
  );

  Widget _aiBox(String title, String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.olive.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.olive.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.olive,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: AppColors.dark.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(String text) => _card(
    Center(
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.4)),
      ),
    ),
  );

  Widget _notice(String text, Color background, Color foreground) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.md)),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: foreground)),
  );

  Widget _roundIcon(SiteIconData icon, Color background, Color foreground, {double size = 64}) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Center(
          child: SiteIcon(icon, size: size * 0.45, color: foreground),
        ),
      );

  Widget _bar(double value, Color color) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.pill),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: 8,
      backgroundColor: AppColors.surfaceMutedLight,
      valueColor: AlwaysStoppedAnimation(color),
    ),
  );

  Widget _button(
    String label, {
    VoidCallback? onTap,
    bool fullWidth = false,
    bool outlined = false,
    bool dark = false,
    // Shartnoma PDF kartasidagi tugmalar kichikroq: `px-3 py-2 rounded-lg font-medium`.
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined ? Colors.white : (dark ? AppColors.dark : AppColors.olive),
          borderRadius: BorderRadius.circular(compact ? AppRadius.sm : AppRadius.md),
          border: outlined ? Border.all(color: AppColors.borderLight) : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: compact ? FontWeight.w500 : FontWeight.w600,
            color: outlined ? AppColors.dark : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.dark.withValues(alpha: 0.6),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller, {
    String? hint,
    int? maxLength,
    bool digitsOnly = false,
    bool upperCase = false,
  }) {
    final theme = Theme.of(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: digitsOnly ? TextInputType.number : null,
      textCapitalization: upperCase ? TextCapitalization.characters : TextCapitalization.none,
      inputFormatters: [
        if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
        if (upperCase)
          TextInputFormatter.withFunction(
            (_, next) => next.copyWith(text: next.text.toUpperCase()),
          ),
      ],
      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        filled: true,
        fillColor: AppColors.surfaceAltLight,
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.dark.withValues(alpha: 0.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: border(AppColors.borderLight),
        enabledBorder: border(AppColors.borderLight),
        focusedBorder: border(AppColors.olive),
      ),
    );
  }

  @override
  void dispose() {
    _series.dispose();
    _number.dispose();
    _phone.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

enum _Tone { neutral, positive, negative, warning }

/// Narx dinamikasi — oddiy chiziq va maydon.
class _PricePainter extends CustomPainter {
  _PricePainter(this.points);

  final List<(String, num)> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxValue = points.map((p) => p.$2).reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return;

    final step = points.length == 1 ? size.width : size.width / (points.length - 1);
    final offsets = <Offset>[
      for (final (index, point) in points.indexed)
        Offset(
          points.length == 1 ? size.width / 2 : index * step,
          size.height - size.height * (point.$2 / maxValue),
        ),
    ];

    final area = Path()..moveTo(offsets.first.dx, size.height);
    for (final offset in offsets) {
      area.lineTo(offset.dx, offset.dy);
    }
    area
      ..lineTo(offsets.last.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.olive.withValues(alpha: 0.25),
            AppColors.olive.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final offset in offsets.skip(1)) {
      line.lineTo(offset.dx, offset.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.olive
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PricePainter old) => old.points != points;
}

/// Bo'limlar panelini tepada ushlab turadi — saytdagi `sticky top-[72px]`.
