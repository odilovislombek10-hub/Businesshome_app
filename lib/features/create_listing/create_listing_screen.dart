import '../../core/i18n/translate.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/models/market_user.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/my_location_button.dart';
import '../../shared/widgets/video_upload_box.dart';
import '../../shared/widgets/yandex_map.dart';
import 'create_listing_data.dart';
import 'create_listing_draft.dart';
import 'create_listing_form.dart';
import 'create_listing_repository.dart';
import 'create_listing_texts.dart';

/// Saytning `/ads/create` va `/ads/:id/edit` sahifasi — `create-listing.component.ts`.
///
/// Bitta uzun forma, oltita raqamlangan bo'lim. Ikkinchi bo'lim mulk va e'lon turiga qarab
/// butunlay o'zgaradi: omborxonada xonalar kalit bilan yoqiladi, yerda "vremenka" so'raladi,
/// faqat sotish + kvartirada qo'shimcha xonalar, uchlik maydon va ikkita narx maydoni chiqadi.
///
/// Xaritadan joylashuv saytdagidek ixtiyoriy: `lat/lng` bo'sh bo'lsa 0 yuboriladi.
class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key, this.editId, this.editKind});

  /// `/ads/:id/edit` da to'ldiriladi.
  final int? editId;
  final String? editKind;

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _repo = const CreateListingRepository();
  final _scroll = ScrollController();
  final _form = ListingForm();

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _district = TextEditingController();
  final _address = TextEditingController();
  final _area = TextEditingController();
  final _landArea = TextEditingController();
  final _livingArea = TextEditingController();
  final _balconyArea = TextEditingController();
  final _vremenkaArea = TextEditingController();
  final _floor = TextEditingController();
  final _totalFloors = TextEditingController();
  final _price = TextEditingController();
  final _pricePerM2 = TextEditingController();

  final _images = <File>[];

  /// Ixtiyoriy Reels videosi — e'lon yaratilgach alohida so'rov bilan ketadi.
  File? _video;
  Map<String, String> _errors = const {};
  bool _scrolled = false;
  bool _submitting = false;
  bool _cityOpen = false;
  bool _repairDetailsOpen = false;
  bool _tourRequestSent = false;
  bool _urgentWarning = false;

  /// Tiklangan qoralama bor-yo'qligi va oxirgi saqlangan vaqt — saytdagi ikki xil banner.
  bool _restoredDraft = false;
  DateTime? _draftSavedAt;
  Timer? _autosave;

  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 10;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
    // Saytda tahrirlash rejimida qoralama saqlanmaydi.
    if (!_isEdit) {
      _restoreDraft();
      _autosave = Timer.periodic(const Duration(seconds: 2), (_) => _saveDraft());
    }
  }

  Future<void> _restoreDraft() async {
    final savedAt = await ListingDraft.restore(_form);
    if (!mounted || savedAt == null) return;
    setState(() {
      _restoredDraft = true;
      _draftSavedAt = savedAt;
      _syncControllers();
    });
  }

  Future<void> _saveDraft() async {
    if (_submitting) return;
    final savedAt = await ListingDraft.save(_form);
    if (!mounted || savedAt == null) return;
    setState(() => _draftSavedAt = savedAt);
  }

  /// Qoralama tiklangach matn maydonlariga ham yozib qo'yiladi.
  void _syncControllers() {
    _title.text = _form.title;
    _description.text = _form.description;
    _district.text = _form.district;
    _address.text = _form.address;
    _area.text = _numText(_form.area);
    _landArea.text = _numText(_form.landArea);
    _livingArea.text = _numText(_form.livingArea);
    _balconyArea.text = _numText(_form.balconyArea);
    _vremenkaArea.text = _numText(_form.vremenkaArea);
    _floor.text = _form.floor?.toString() ?? '';
    _totalFloors.text = _form.totalFloors?.toString() ?? '';
    _price.text = _numText(_form.price);
    _pricePerM2.text = _numText(_form.pricePerM2);
  }

  static String _numText(double? value) => value == null ? '' : _trimZero(value);

  @override
  void dispose() {
    _autosave?.cancel();
    _scroll.dispose();
    for (final controller in [
      _title,
      _description,
      _district,
      _address,
      _area,
      _landArea,
      _livingArea,
      _balconyArea,
      _vremenkaArea,
      _floor,
      _totalFloors,
      _price,
      _pricePerM2,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAltLight, // bg-gray-50
      body: Stack(
        children: [
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
            // Shablonda `[transparent]="false"`.
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
        CreateListingTexts.pageTitle,
        style: theme.textTheme.displaySmall?.copyWith(
          fontSize: 30, // text-3xl
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
      const SizedBox(height: 8), // mb-2
      Text(
        CreateListingTexts.pageSubtitle,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.6)),
      ),
      const SizedBox(height: 32), // mb-8
      ..._draftBanner(),
      if (_errors['general'] case final message?) ...[
        Container(
          padding: const EdgeInsets.all(16), // p-4
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2), // bg-red-50
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: const Color(0xFFFECACA)), // border-red-200
          ),
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: const Color(0xFFDC2626), // text-red-600
            ),
          ),
        ),
        const SizedBox(height: 24), // mb-6
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
            _section(1, CreateListingTexts.sectionBasic, _basicFields()),
            _divider(),
            _featuresSection(),
            _divider(),
            _section(3, CreateListingTexts.sectionLocation, _locationFields()),
            _divider(),
            _section(4, CreateListingTexts.sectionImages, _imageFields()),
            _divider(),
            _section(5, CreateListingTexts.sectionExtras, _extraFields()),
            _divider(),
            Padding(padding: const EdgeInsets.all(24), child: _submitRow()),
          ],
        ),
      ),
    ];
  }

  /// Saytdagi ikki xil xabar: qoralama tiklangan bo'lsa ko'k karta, aks holda "Avtomatik
  /// saqlandi" degan yashil chiziqcha.
  List<Widget> _draftBanner() {
    final theme = Theme.of(context);
    if (_draftSavedAt == null) return const [];
    if (!_restoredDraft) {
      return [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981), // bg-emerald-500
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6), // gap-1.5
            Text(
              'Avtomatik saqlandi',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11, // text-[11px]
                color: const Color(0xFF047857), // text-emerald-700
              ),
            ),
          ],
        ),
        const SizedBox(height: 16), // mb-4
      ];
    }
    return [
      Container(
        padding: const EdgeInsets.all(12), // p-3
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF), // bg-sky-50
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: const Color(0xFFBAE6FD)), // border-sky-200
        ),
        child: Row(
          children: [
            const Text('📝', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 12), // gap-3
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Oldingi qoralama tiklandi',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0C4A6E), // text-sky-900
                    ),
                  ),
                  Text(
                    "Avtomatik saqlangan — sahifa yopilsa ham yo'qolmaydi",
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: const Color(0xFF0369A1).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Pressable(
              scale: 0.98,
              onTap: _discardDraft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Text(
                  'Toza boshlash',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0369A1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16), // mb-4
    ];
  }

  /// Saytda bu yerda sahifa qayta yuklanadi; ilovada forma tozalanadi.
  Future<void> _discardDraft() async {
    await ListingDraft.clear();
    if (!mounted) return;
    setState(() {
      _form.applyJson(ListingForm().toJson());
      _images.clear();
      _errors = const {};
      _restoredDraft = false;
      _draftSavedAt = null;
      _syncControllers();
    });
  }

  Widget _divider() => const Divider(height: 1, color: AppColors.borderLight);

  /// Raqamli doira + sarlavha, ostida maydonlar — barcha bo'limlarda bir xil.
  Widget _section(int number, String title, List<Widget> children, {Widget? subtitle}) {
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
              const SizedBox(width: 12), // gap-3
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18, // text-lg
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ],
          ),
          ?subtitle,
          const SizedBox(height: 24), // mb-6
          ...children,
        ],
      ),
    );
  }

  // ── 1. Asosiy ma'lumotlar ──────────────────────────────────────────────────

  List<Widget> _basicFields() => [
    _label(CreateListingTexts.dealType, strong: true),
    const SizedBox(height: 12), // mb-3
    Row(
      children: [
        for (final deal in ListingOptions.dealTypes) ...[
          Expanded(
            child: _choiceButton(
              deal.label,
              selected: _form.dealType == deal.value,
              onTap: () => setState(() => _form.dealType = deal.value),
            ),
          ),
          if (deal != ListingOptions.dealTypes.last) const SizedBox(width: 8), // gap-2
        ],
      ],
    ),
    const SizedBox(height: 20), // space-y-5
    _label(CreateListingTexts.propertyType, strong: true),
    const SizedBox(height: 12),
    // `grid-cols-3` mobilda
    _grid(
      columns: 3,
      children: [
        for (final type in ListingOptions.propertyTypes)
          _choiceButton(
            type.label,
            selected: _form.propertyType == type.value,
            onTap: () => setState(() => _form.propertyType = type.value),
          ),
      ],
    ),
    const SizedBox(height: 20),
    _label(CreateListingTexts.title),
    const SizedBox(height: 8), // mb-2
    _input(
      _title,
      hint: CreateListingTexts.titlePlaceholder,
      error: _errors['title'],
      onChanged: (value) => _form.title = value,
    ),
    const SizedBox(height: 20),
    _label(CreateListingTexts.description),
    const SizedBox(height: 8),
    _input(
      _description,
      hint: CreateListingTexts.descriptionPlaceholder,
      error: _errors['description'],
      lines: 4, // rows="4"
      onChanged: (value) => _form.description = value,
    ),
  ];

  // ── 2. Xususiyatlar ────────────────────────────────────────────────────────

  Widget _featuresSection() {
    final theme = Theme.of(context);
    final dealLabel = ListingOptions.dealTypes
        .firstWhere((d) => d.value == _form.dealType, orElse: () => ListingOptions.dealTypes.first)
        .label;
    final hint = _form.isSell
        ? CreateListingTexts.dealHintSell
        : _form.isRent
        ? CreateListingTexts.dealHintRent
        : CreateListingTexts.dealHintExchange;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: AppColors.olive, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  '2',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: CreateListingTexts.sectionFeatures,
                    children: [
                      TextSpan(
                        text: ' — $dealLabel',
                        style: const TextStyle(color: AppColors.olive),
                      ),
                    ],
                  ),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // mb-2
          Padding(
            padding: const EdgeInsets.only(left: 44), // ml-11
            child: Text(
              hint,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 24), // mb-6
          ..._featureFields(),
        ],
      ),
    );
  }

  List<Widget> _featureFields() => [
    // Omborxonada maydon eng tepada turadi.
    if (_form.isWarehouse) ...[
      _label(CreateListingTexts.area),
      const SizedBox(height: 8),
      _numberInput(
        _area,
        hint: CreateListingTexts.areaPlaceholder,
        suffix: 'm²',
        error: _errors['area'],
        onChanged: (value) => _form.area = value,
      ),
      const SizedBox(height: 20),
    ],

    // Yer va avto-turargohda xonalar/sanuzel umuman so'ralmaydi.
    if (!_form.isLand && !_form.isParking) ...[
      if (_form.isWarehouse)
        _toggleBox(
          CreateListingTexts.hasRooms,
          CreateListingTexts.hasRoomsHint,
          value: _form.roomsEnabled,
          onChanged: (value) => setState(() => _form.roomsEnabled = value),
          child: _form.roomsEnabled ? _roomPicker() : null,
        )
      else ...[
        _label(CreateListingTexts.rooms),
        const SizedBox(height: 12),
        _roomPicker(),
      ],
      const SizedBox(height: 20),

      if (_form.isOffice || _form.isShop || _form.isWarehouse)
        _toggleBox(
          CreateListingTexts.hasBathroom,
          CreateListingTexts.hasBathroomHint,
          value: _form.bathroomEnabled,
          onChanged: (value) => setState(() => _form.bathroomEnabled = value),
          child: _form.bathroomEnabled ? _bathroomKind() : null,
        )
      else ...[
        _label(CreateListingTexts.bathrooms),
        const SizedBox(height: 12),
        _bathroomPicker(),
      ],
      const SizedBox(height: 20),
    ],

    // Yer uchun — vremenka.
    if (_form.isLand) ...[
      _toggleBox(
        CreateListingTexts.hasVremenka,
        CreateListingTexts.hasVremenkaHint,
        value: _form.hasVremenka,
        onChanged: (value) => setState(() => _form.hasVremenka = value),
      ),
      if (_form.hasVremenka) ...[
        const SizedBox(height: 20),
        _label(CreateListingTexts.vremenkaRooms),
        const SizedBox(height: 12),
        _roomPicker(),
        const SizedBox(height: 12),
        _label(CreateListingTexts.vremenkaArea),
        const SizedBox(height: 8),
        _numberInput(
          _vremenkaArea,
          hint: '0',
          suffix: 'm²',
          onChanged: (value) => _form.vremenkaArea = value,
        ),
      ],
      const SizedBox(height: 20),
    ],

    // Qo'shimcha xonalar — faqat sotish + kvartira.
    if (_form.isSellApartment) ...[
      _label(CreateListingTexts.extraRoomLabel),
      const SizedBox(height: 12),
      for (final room in ListingOptions.extraRooms) ...[
        _counterRow(room),
        const SizedBox(height: 8),
      ],
      _hint(CreateListingTexts.extraRoomHint),
      const SizedBox(height: 20),
      _toggleBox(
        CreateListingTexts.hasBalcony,
        CreateListingTexts.hasBalconyHint,
        value: _form.hasBalcony,
        onChanged: (value) => setState(() => _form.hasBalcony = value),
      ),
      const SizedBox(height: 12),
      _toggleBox(
        CreateListingTexts.hasLoggia,
        CreateListingTexts.hasLoggiaHint,
        value: _form.hasLoggia,
        onChanged: (value) => setState(() => _form.hasLoggia = value),
      ),
      const SizedBox(height: 20),
    ] else if (_form.isApartment) ...[
      // Kvartirada (ijara/almashish) faqat balkon so'raladi.
      _toggleBox(
        CreateListingTexts.hasBalcony,
        CreateListingTexts.hasBalconyHint,
        value: _form.hasBalcony,
        onChanged: (value) => setState(() => _form.hasBalcony = value),
      ),
      const SizedBox(height: 20),
    ],

    // Qavatlar.
    if (_form.isHouse) ...[
      _label(CreateListingTexts.houseFloors),
      const SizedBox(height: 8),
      _numberInput(
        _totalFloors,
        hint: CreateListingTexts.houseFloorsPlaceholder,
        onChanged: (value) => _form.totalFloors = value?.round(),
      ),
      const SizedBox(height: 6),
      _hint(CreateListingTexts.houseFloorsHint),
      const SizedBox(height: 20),
    ] else if (!_form.isLand && !_form.isParking && !_form.isWarehouse) ...[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(CreateListingTexts.floor),
                const SizedBox(height: 8),
                _numberInput(
                  _floor,
                  hint: CreateListingTexts.floorPlaceholder,
                  onChanged: (value) => _form.floor = value?.round(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(CreateListingTexts.totalFloors),
                const SizedBox(height: 8),
                _numberInput(
                  _totalFloors,
                  hint: CreateListingTexts.totalFloorsPlaceholder,
                  onChanged: (value) => _form.totalFloors = value?.round(),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
    ],

    // Remont — yer/omborxona/parkingda yo'q.
    if (_form.showRepairDetails) ...[
      _toggleBox(
        CreateListingTexts.repairTitle,
        CreateListingTexts.repairHint,
        value: _form.hasRepair,
        onChanged: (value) => setState(() => _form.hasRepair = value),
        child: _form.hasRepair ? _repairFields() : null,
      ),
      const SizedBox(height: 20),
    ],
    // Saytda tashqi shart `!isLand && !isWarehouse && !isParking` — bu turlarda remont
    // bo'limi umuman chizilmaydi (ichkaridagi oddiy toggle amalda hech qachon chiqmaydi).

    // Segment — yer, omborxona va avto-turargohda mantiqsiz, shuning uchun yashirilgan.
    if (!_form.isLand && !_form.isWarehouse && !_form.isParking) ...[
      _label(CreateListingTexts.segmentLabel, strong: true),
      const SizedBox(height: 12),
      _grid(
        columns: 2,
        children: [
          for (final segment in ListingOptions.segments)
            _choiceButton(
              segment.label,
              icon: segment.icon,
              // Saytda ikkinchi marta bosilsa tanlov bekor qilinadi.
              selected: _form.segment == segment.value,
              onTap: () => setState(
                () => _form.segment = _form.segment == segment.value ? null : segment.value,
              ),
            ),
        ],
      ),
      const SizedBox(height: 6),
      _hint(CreateListingTexts.segmentHint),
      const SizedBox(height: 20),
    ],

    // Maydon.
    ..._areaFields(),

    // Narx.
    ..._priceFields(),

    // To'lov turlari — ijarada yo'q.
    if (!_form.isRent) ...[
      _label(CreateListingTexts.paymentLabel, strong: true),
      const SizedBox(height: 12),
      for (final option in ListingOptions.paymentOptions) ...[
        _checkRow(
          option,
          selected: _form.paymentOptions.contains(option.value),
          onTap: () => setState(() {
            if (!_form.paymentOptions.remove(option.value)) {
              _form.paymentOptions.add(option.value);
            }
          }),
        ),
        const SizedBox(height: 8),
      ],
      _hint(CreateListingTexts.paymentHint),
    ],
  ];

  List<Widget> _areaFields() {
    if (_form.isSellApartment) {
      return [
        _label(CreateListingTexts.areaSectionLabel, strong: true),
        const SizedBox(height: 12),
        _label(CreateListingTexts.areaSectionLiving),
        const SizedBox(height: 8),
        _numberInput(
          _livingArea,
          hint: '0',
          suffix: 'm²',
          onChanged: (value) {
            _form.livingArea = value;
            _syncTotalArea();
          },
        ),
        const SizedBox(height: 12),
        _label(CreateListingTexts.areaSectionBalcony),
        const SizedBox(height: 8),
        _numberInput(
          _balconyArea,
          hint: '0',
          suffix: 'm²',
          onChanged: (value) {
            _form.balconyArea = value;
            _syncTotalArea();
          },
        ),
        const SizedBox(height: 12),
        _label(CreateListingTexts.areaSectionTotal),
        const SizedBox(height: 8),
        // Umumiy maydon avtomatik hisoblanadi — saytda ham `read-only`.
        _input(_area, hint: '0', suffix: 'm²', readOnly: true, error: _errors['area']),
        const SizedBox(height: 6),
        _hint(CreateListingTexts.areaSectionHint),
        const SizedBox(height: 20),
      ];
    }
    if (_form.isLand) {
      return [
        _label(CreateListingTexts.landArea),
        const SizedBox(height: 8),
        _numberInput(
          _landArea,
          hint: CreateListingTexts.landAreaPlaceholder,
          suffix: 'm²',
          error: _errors['area'],
          onChanged: (value) => _form.landArea = value,
        ),
        const SizedBox(height: 20),
      ];
    }
    return [
      if (!_form.isWarehouse) ...[
        _label(_form.isHouse ? CreateListingTexts.totalArea : CreateListingTexts.area),
        const SizedBox(height: 8),
        _numberInput(
          _area,
          hint: CreateListingTexts.areaPlaceholder,
          suffix: 'm²',
          error: _errors['area'],
          onChanged: (value) => _form.area = value,
        ),
        const SizedBox(height: 20),
      ],
      if (_form.showLandArea) ...[
        _label(CreateListingTexts.landArea),
        const SizedBox(height: 8),
        _numberInput(
          _landArea,
          hint: CreateListingTexts.landAreaPlaceholder,
          suffix: 'm²',
          onChanged: (value) => _form.landArea = value,
        ),
        const SizedBox(height: 20),
      ],
    ];
  }

  /// Yashash + balkon maydonidan umumiy maydonni hisoblab, maydonni yangilaydi.
  void _syncTotalArea() {
    final total = _form.computedArea;
    _form.area = total;
    _area.text = total == null || total == 0 ? '' : _trimZero(total);
  }

  static String _trimZero(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();

  List<Widget> _priceFields() {
    final currencyToggle = Row(
      children: [
        for (final code in ['UZS', 'USD']) ...[
          _choiceButton(
            code,
            selected: _form.currency == code,
            onTap: () => setState(() => _form.currency = code),
            compact: true,
          ),
          if (code == 'UZS') const SizedBox(width: 8),
        ],
      ],
    );

    if (_form.isSellApartment) {
      return [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_label(CreateListingTexts.price, strong: true), currencyToggle],
        ),
        const SizedBox(height: 12),
        _label(CreateListingTexts.priceSectionTotal),
        const SizedBox(height: 8),
        _numberInput(
          _price,
          hint: CreateListingTexts.pricePlaceholder,
          suffix: _form.currency,
          error: _errors['price'],
          onChanged: (value) => _form.price = value,
        ),
        const SizedBox(height: 12),
        _label(CreateListingTexts.priceSectionPerM2),
        const SizedBox(height: 8),
        _numberInput(
          _pricePerM2,
          hint: '0',
          suffix: _form.currency,
          onChanged: (value) => _form.pricePerM2 = value,
        ),
        const SizedBox(height: 6),
        _hint(CreateListingTexts.priceSectionHint),
        const SizedBox(height: 20),
      ];
    }
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_label(CreateListingTexts.price, strong: true), currencyToggle],
      ),
      const SizedBox(height: 12),
      _numberInput(
        _price,
        hint: CreateListingTexts.pricePlaceholder,
        suffix: _form.currency,
        error: _errors['price'],
        onChanged: (value) => _form.price = value,
      ),
      const SizedBox(height: 20),
    ];
  }

  Widget _repairFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      _optionGroup(
        CreateListingTexts.repairTypeLabel,
        ListingOptions.repairTypes,
        _form.repairType,
        (value) => setState(() => _form.repairType = value),
      ),
      _optionGroup(
        CreateListingTexts.designStyleLabel,
        ListingOptions.designStyles,
        _form.designStyle,
        (value) => setState(() => _form.designStyle = value),
      ),
      // Saytda bu qism yopiladigan blok ichida.
      GestureDetector(
        onTap: () => setState(() => _repairDetailsOpen = !_repairDetailsOpen),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(child: _label(CreateListingTexts.repairDetails)),
              SiteIcon(
                _repairDetailsOpen ? SiteIcons.chevronUp : SiteIcons.chevronDown,
                size: 16,
                color: AppColors.dark.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
      if (_repairDetailsOpen) ...[
        _optionGroup(
          CreateListingTexts.floorMatLabel,
          ListingOptions.floorMaterials,
          _form.floorMaterial,
          (value) => setState(() => _form.floorMaterial = value),
        ),
        _optionGroup(
          CreateListingTexts.wallFinLabel,
          ListingOptions.wallFinishes,
          _form.wallFinish,
          (value) => setState(() => _form.wallFinish = value),
        ),
        _optionGroup(
          CreateListingTexts.ceilingLabel,
          ListingOptions.ceilingTypes,
          _form.ceilingType,
          (value) => setState(() => _form.ceilingType = value),
        ),
        _optionGroup(
          CreateListingTexts.windowLabel,
          ListingOptions.windowTypes,
          _form.windowType,
          (value) => setState(() => _form.windowType = value),
        ),
        _optionGroup(
          CreateListingTexts.kitchenLabel,
          ListingOptions.kitchenTypes,
          _form.kitchenType,
          (value) => setState(() => _form.kitchenType = value),
        ),
        _optionGroup(
          CreateListingTexts.bathLayoutLabel,
          ListingOptions.bathroomLayouts,
          _form.bathroomLayout,
          (value) => setState(() => _form.bathroomLayout = value),
        ),
        _optionGroup(
          CreateListingTexts.heatingLabel,
          ListingOptions.heatingTypes,
          _form.heatingType,
          (value) => setState(() => _form.heatingType = value),
        ),
      ],
    ],
  );

  Widget _optionGroup(
    String label,
    List<ListingOption> options,
    String? current,
    ValueChanged<String?> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        _grid(
          columns: 2,
          children: [
            for (final option in options)
              _choiceButton(
                option.label,
                selected: current == option.value,
                onTap: () => onChanged(current == option.value ? null : option.value),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _roomPicker() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final room in ListingOptions.rooms)
        _squareButton(
          room == 6 ? '5+' : '$room',
          selected: _form.rooms == room,
          onTap: () => setState(() => _form.rooms = room),
        ),
    ],
  );

  Widget _bathroomPicker() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final count in ListingOptions.bathrooms)
        _squareButton(
          count == 4 ? t('designers.rating4plus') : '$count',
          selected: _form.bathrooms == count,
          onTap: () => setState(() => _form.bathrooms = count),
        ),
    ],
  );

  /// Ofis/do'kon/omborxonada sanuzel yoqilgach: turi, alohida bo'lsa — soni.
  Widget _bathroomKind() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      _label(CreateListingTexts.bathroomType),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _choiceButton(
              CreateListingTexts.bathroomPrivate,
              selected: _form.bathroomShared == false,
              onTap: () => setState(() => _form.bathroomShared = false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _choiceButton(
              CreateListingTexts.bathroomShared,
              selected: _form.bathroomShared == true,
              onTap: () => setState(() => _form.bathroomShared = true),
            ),
          ),
        ],
      ),
      if (_form.bathroomShared == false) ...[
        const SizedBox(height: 12),
        _label(CreateListingTexts.bathroomCount),
        const SizedBox(height: 8),
        _bathroomPicker(),
      ],
    ],
  );

  // ── 3. Manzil ──────────────────────────────────────────────────────────────

  List<Widget> _locationFields() {
    final theme = Theme.of(context);
    final selected = ListingOptions.cities.where((c) => c.value == _form.city).firstOrNull;
    return [
      _label(CreateListingTexts.city),
      const SizedBox(height: 8),
      Pressable(
        scale: 1,
        onTap: () => setState(() => _cityOpen = !_cityOpen),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // px-4 py-3.5
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: _errors['city'] != null ? const Color(0xFFF87171) : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected?.label ?? CreateListingTexts.selectCity,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15, // text-[15px]
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
        const SizedBox(height: 4), // mt-1
        Container(
          constraints: const BoxConstraints(maxHeight: 208), // max-h-52
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              for (final city in ListingOptions.cities)
                GestureDetector(
                  onTap: () => setState(() {
                    _form.city = city.value;
                    _cityOpen = false;
                  }),
                  child: Container(
                    width: double.infinity,
                    color: _form.city == city.value
                        ? AppColors.olive.withValues(alpha: 0.1)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      city.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: _form.city == city.value ? FontWeight.w500 : null,
                        color: _form.city == city.value ? AppColors.olive : AppColors.dark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
      if (_errors['city'] case final message?) _error(message),
      const SizedBox(height: 20),
      _label(CreateListingTexts.district),
      const SizedBox(height: 8),
      _input(
        _district,
        hint: CreateListingTexts.districtPlaceholder,
        onChanged: (value) => _form.district = value,
      ),
      const SizedBox(height: 20),
      _label(CreateListingTexts.address),
      const SizedBox(height: 8),
      _input(
        _address,
        hint: CreateListingTexts.addressPlaceholder,
        error: _errors['address'],
        onChanged: (value) => _form.address = value,
      ),
      const SizedBox(height: 20),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(CreateListingTexts.mapLocation),
                const SizedBox(height: 2), // mt-0.5
                _hint(CreateListingTexts.mapLocationHint),
              ],
            ),
          ),
          if (_form.locationLat != null && _form.locationLng != null)
            GestureDetector(
              onTap: () => setState(() {
                _form.locationLat = null;
                _form.locationLng = null;
              }),
              child: Text(
                CreateListingTexts.clearLocation,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFEF4444), // text-red-500
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12), // mb-3
      Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
            child: Container(
              height: 360, // h-[360px]
              decoration: BoxDecoration(border: Border.all(color: AppColors.borderLight)),
              child: YandexMapView(
                pickMode: true,
                pickedLat: _form.locationLat,
                pickedLng: _form.locationLng,
                onPicked: (lat, lng) => setState(() {
                  _form.locationLat = lat;
                  _form.locationLng = lng;
                }),
              ),
            ),
          ),
          // Saytdagi `absolute top-3 right-3` — belgini o'z joylashuvingga qo'yadi.
          Positioned(
            top: 12,
            right: 12,
            child: MyLocationButton(
              onLocated: (lat, lng) => setState(() {
                _form.locationLat = lat;
                _form.locationLng = lng;
              }),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8), // mt-2
      if (_form.locationLat case final lat? when _form.locationLng != null)
        Row(
          children: [
            const SiteIcon(SiteIcons.check, size: 14, color: Color(0xFF059669)),
            const SizedBox(width: 8), // gap-2
            Text(
              CreateListingTexts.locationSelected,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF059669), // text-emerald-600
              ),
            ),
            const SizedBox(width: 8),
            Text(
              // Saytda `toFixed(5)`.
              '${lat.toStringAsFixed(5)}, ${_form.locationLng!.toStringAsFixed(5)}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
          ],
        )
      else
        _hint(CreateListingTexts.clickMapToSelect),
    ];
  }

  // ── 4. Rasmlar ─────────────────────────────────────────────────────────────

  List<Widget> _imageFields() {
    final theme = Theme.of(context);
    return [
      GestureDetector(
        onTap: _pickImages,
        child: DottedBorderBox(
          child: Padding(
            padding: const EdgeInsets.all(32), // p-8
            child: Column(
              children: [
                Container(
                  width: 56, // w-14 h-14
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.olive.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SiteIcon(SiteIcons.camera, size: 24, color: AppColors.olive),
                  ),
                ),
                const SizedBox(height: 12), // gap-3
                Text(
                  CreateListingTexts.uploadImages,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4), // mt-1
                Text(
                  CreateListingTexts.uploadHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: AppColors.dark.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.olive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    CreateListingTexts.selectFiles,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.olive,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (_images.isNotEmpty) ...[
        const SizedBox(height: 16), // mt-4
        _grid(
          columns: 3,
          spacing: 12, // gap-3
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
                          width: 24, // w-6 h-6
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444), // bg-red-500
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
      ],
      const SizedBox(height: 12), // mt-3
      _hint(CreateListingTexts.maxImages),
      const SizedBox(height: 24), // mt-6
      VideoUploadBox(onChanged: (file) => _video = file),
      const SizedBox(height: 24),
      _tourBox(),
    ];
  }

  /// 360° bo'limi — saytda ariza faqat ekranda belgilanadi, serverga so'rov ketmaydi.
  Widget _tourBox() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20), // p-5
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // from-blue-50
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFDBEAFE)), // border-blue-100
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, // w-10 h-10
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB), // bg-blue-600
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SiteIcon(SiteIcons.box3d, size: 20, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12), // gap-3
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CreateListingTexts.tour360Title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4), // mt-1
                    Text(
                      CreateListingTexts.tour360Description,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        height: 1.6,
                        color: AppColors.dark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // mb-4
          if (_tourRequestSent) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                CreateListingTexts.tour360RequestSentMessage,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF047857),
                ),
              ),
            ),
            const SizedBox(height: 12), // mb-3
          ],
          // Mobilda `grid-cols-1` — ikkala tugma ustma-ust.
          Pressable(
            scale: 0.98,
            onTap: _openTourRequest,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14), // py-3.5
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                CreateListingTexts.tour360RequestBtn,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12), // gap-3
          Pressable(
            scale: 0.98,
            // Saytda bu `<iframe src="https://3dtest.businesshome.uz">` bilan ochiladi. Ilovada
            // 3D ko'ruvchi hali yo'q, shuning uchun havola brauzerda ochiladi.
            onTap: () => launchUrl(
              Uri.parse('https://3dtest.businesshome.uz'),
              mode: LaunchMode.externalApplication,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFFBFDBFE)), // border-blue-200
              ),
              child: Text(
                CreateListingTexts.tour360DemoBtn,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12), // mt-3
          _hint(CreateListingTexts.tour360Hint),
        ],
      ),
    );
  }

  /// 360° ariza oynasi. Saytda ham bu ma'lumotlar serverga yuborilmaydi — tugma bosilgach
  /// faqat ekranda besh soniya "yuborildi" xabari turadi (`submitTourRequest`).
  Future<void> _openTourRequest() async {
    final phone = TextEditingController();
    final address = TextEditingController(text: _form.address);
    final comment = TextEditingController();
    final theme = Theme.of(context);

    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CreateListingTexts.tour360ModalTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 16, // text-base
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CreateListingTexts.tour360ModalSubtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.dark.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  CreateListingTexts.tour360ModalInfo,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label(CreateListingTexts.tour360ModalPhone),
              const SizedBox(height: 8),
              _input(phone, hint: '+998 90 123 45 67', keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _label(CreateListingTexts.tour360ModalAddress),
              const SizedBox(height: 8),
              _input(address, hint: CreateListingTexts.tour360ModalAddressPh),
              const SizedBox(height: 12),
              _label(CreateListingTexts.tour360ModalComment),
              const SizedBox(height: 8),
              _input(comment, hint: CreateListingTexts.tour360ModalCommentPh, lines: 3),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Pressable(
                      scale: 0.98,
                      onTap: () => Navigator.of(sheetContext).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Text(
                          CreateListingTexts.cancel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Pressable(
                      scale: 0.98,
                      onTap: () => Navigator.of(sheetContext).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          CreateListingTexts.tour360ModalSubmit,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

    phone.dispose();
    address.dispose();
    comment.dispose();
    if (sent != true || !mounted) return;

    setState(() => _tourRequestSent = true);
    await Future<void>.delayed(const Duration(seconds: 5));
    if (mounted) setState(() => _tourRequestSent = false);
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;
    setState(() {
      for (final file in picked) {
        if (_images.length >= 20) break; // saytdagi chegara — `maxImages`
        _images.add(File(file.path));
      }
    });
  }

  // ── 5. Qo'shimcha ──────────────────────────────────────────────────────────

  List<Widget> _extraFields() {
    final theme = Theme.of(context);
    final amenities = ListingOptions.amenitiesFor(_form.propertyType);
    return [
      _label(CreateListingTexts.amenities, strong: true),
      const SizedBox(height: 12),
      _grid(
        columns: 2,
        spacing: 12,
        children: [
          for (final amenity in amenities)
            _checkRow(
              amenity,
              selected: _form.amenities.contains(amenity.value),
              onTap: () => setState(() {
                if (!_form.amenities.remove(amenity.value)) _form.amenities.add(amenity.value);
              }),
            ),
        ],
      ),
      const SizedBox(height: 24), // space-y-6
      // "Shoshilinch" saytda ham o'chirilgan — bosilsa ogohlantirish chiqadi.
      Opacity(
        opacity: 0.7,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAltLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            CreateListingTexts.urgent,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            t('cabinet.inquiryStatus.in_progress'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CreateListingTexts.urgentHint,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: AppColors.dark.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  setState(() => _urgentWarning = true);
                  await Future<void>.delayed(const Duration(seconds: 4));
                  if (mounted) setState(() => _urgentWarning = false);
                },
                child: _switch(false, enabled: false),
              ),
            ],
          ),
        ),
      ),
      if (_urgentWarning) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Text(
            CreateListingTexts.urgentInProgress,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: const Color(0xFF92400E),
            ),
          ),
        ),
      ],
    ];
  }

  // ── 6. Jo'natish ───────────────────────────────────────────────────────────

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
              padding: const EdgeInsets.symmetric(vertical: 14), // py-3.5
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
                    const SizedBox(width: 8), // gap-2
                  ],
                  Text(
                    CreateListingTexts.submit,
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
        const SizedBox(height: 12), // gap-3
        Pressable(
          scale: 0.98,
          onTap: () => context.go('/cabinet/listings'),
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
              CreateListingTexts.cancel,
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
    final user = context.read<AuthService>().user;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    final errors = _form.validate(hasImages: _images.isNotEmpty, isEdit: _isEdit);
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }

    setState(() {
      _errors = const {};
      _submitting = true;
    });

    final payload = _form.toPayload(
      ownerName: user.fullName,
      ownerPhone: user.phone,
      isAgent: user.role == MarketRole.agent,
    );

    try {
      final kind = _isEdit ? (widget.editKind ?? _form.kind) : _form.kind;
      final id = _isEdit ? widget.editId! : await _repo.create(kind: kind, payload: payload);
      if (_isEdit) await _repo.update(kind: kind, id: id, payload: payload);
      await _repo.uploadImages(kind: kind, id: id, files: _images);
      if (_video case final video?) {
        await _repo.uploadVideo(kind: kind, id: id, file: video);
      }
      if (!mounted) return;
      setState(() => _submitting = false);
      await _showSuccess();
    } on ListingException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errors = {'general': e.message};
      });
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errors = {'general': t('completeProfile.errorSave')};
      });
    }
  }

  Future<void> _showSuccess() async {
    final theme = Theme.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, // w-14 h-14
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5), // bg-emerald-100
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SiteIcon(
                    SiteIcons.check,
                    size: 28,
                    color: Color(0xFF059669),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16), // mb-4
              Text(
                "E'lon yuborildi",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8), // mb-2
              Text(
                "E'loningiz tasdiqlashga jo'natildi. Admin ko'rib chiqqach, marketplace'da chiqadi.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.dark.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Pressable(
                  scale: 0.98,
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.olive,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      "Kabinetga o'tish",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
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
      ),
    );
    if (mounted) context.go('/cabinet/listings');
  }

  // ── umumiy bo'laklar ───────────────────────────────────────────────────────

  Widget _label(String text, {bool strong = false}) => Text(
    text,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 14, // text-sm
      fontWeight: FontWeight.w600,
      color: strong ? AppColors.dark.withValues(alpha: 0.8) : AppColors.dark,
    ),
  );

  Widget _hint(String text) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 12, // text-xs
      color: AppColors.dark.withValues(alpha: 0.4),
    ),
  );

  Widget _error(String message) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 4), // mt-1.5 ml-1
    child: Text(
      message,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 12,
        color: const Color(0xFFEF4444), // text-red-500
      ),
    ),
  );

  Widget _input(
    TextEditingController controller, {
    required String hint,
    String? error,
    String? suffix,
    int lines = 1,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          readOnly: readOnly,
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
            fillColor: readOnly ? AppColors.surfaceAltLight : Colors.white,
            suffixText: suffix,
            suffixStyle: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: AppColors.dark.withValues(alpha: 0.4),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: _border(AppColors.borderLight),
            enabledBorder: _border(error != null ? const Color(0xFFF87171) : AppColors.borderLight),
            focusedBorder: _border(AppColors.olive),
          ),
        ),
        if (error != null) _error(error),
      ],
    );
  }

  Widget _numberInput(
    TextEditingController controller, {
    required String hint,
    String? suffix,
    String? error,
    required ValueChanged<double?> onChanged,
  }) => _input(
    controller,
    hint: hint,
    suffix: suffix,
    error: error,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    onChanged: (value) => onChanged(double.tryParse(value)),
  );

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide(color: color),
  );

  /// Tanlanadigan tugma — saytda tanlangani zaytun, qolgani `bg-gray-50`.
  Widget _choiceButton(
    String label, {
    required bool selected,
    required VoidCallback onTap,
    String? icon,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 8, vertical: compact ? 8 : 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.olive : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColors.olive : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppColors.dark.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Xona/sanuzel soni — `w-14 h-12`.
  Widget _squareButton(String label, {required bool selected, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        width: 56, // w-14
        height: 48, // h-12
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.olive : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColors.olive : Colors.transparent),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.dark.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  /// Sarlavha + izoh + kalit; yoqilganda ostidagi tarkib chiqadi.
  Widget _toggleBox(
    String title,
    String hint, {
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? child,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2), // mt-0.5
                    Text(
                      hint,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: AppColors.dark.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(onTap: () => onChanged(!value), child: _switch(value)),
            ],
          ),
          ?child,
        ],
      ),
    );
  }

  /// `h-6 w-11` kalit, tugmachasi `h-5 w-5`.
  Widget _switch(bool value, {bool enabled = true}) => Container(
    width: 44,
    height: 24,
    padding: const EdgeInsets.all(2),
    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
    decoration: BoxDecoration(
      color: !enabled
          ? const Color(0xFFD1D5DB) // bg-gray-300
          : (value ? AppColors.olive : const Color(0xFFD1D5DB)),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
      ),
    ),
  );

  /// Qo'shimcha xona qatori — emoji, nom va −/soni/+ tugmalari.
  Widget _counterRow(ListingOption room) {
    final theme = Theme.of(context);
    final count = _form.extraRooms[room.value] ?? 0;
    Widget button(String label, VoidCallback? onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.surfaceAltLight : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            color: onTap == null
                ? AppColors.dark.withValues(alpha: 0.25)
                : AppColors.dark.withValues(alpha: 0.7),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Text(room.icon ?? '', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              room.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: AppColors.dark.withValues(alpha: 0.7),
              ),
            ),
          ),
          button(
            '−',
            count == 0 ? null : () => setState(() => _form.extraRooms[room.value] = count - 1),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ),
          button('+', () => setState(() => _form.extraRooms[room.value] = count + 1)),
        ],
      ),
    );
  }

  /// Qulaylik/to'lov turi — belgi, nom va tanlanganda zaytun ramka.
  Widget _checkRow(ListingOption option, {required bool selected, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // px-3 py-2.5
        decoration: BoxDecoration(
          color: selected ? AppColors.olive.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.olive.withValues(alpha: 0.3) : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            ?switch (option.icon) {
              final icon? => Text(icon, style: const TextStyle(fontSize: 16)),
              _ => null,
            },
            if (option.icon != null) const SizedBox(width: 8), // gap-2
            Expanded(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12, // mobilda `text-xs`
                  fontWeight: selected ? FontWeight.w500 : null,
                  color: selected ? AppColors.olive : AppColors.dark.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tailwind `grid-cols-N gap-2` ning qo'lda yig'ilgani.
  Widget _grid({required int columns, required List<Widget> children, double spacing = 8}) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(i, (i + columns).clamp(0, children.length));
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + columns < children.length ? spacing : 0),
          // `stretch` ni `IntrinsicHeight` siz qo'ysa, bolalar cheksiz balandlik oladi va
          // butun sahifa jimgina chizilmay qoladi — skill tuzoqlarida yozilgan.
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

/// `border-2 border-dashed` — Flutter'da tayyor chegara yo'q, shuning uchun chiziladi.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedPainter(),
    child: SizedBox(width: double.infinity, child: child),
  );
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFD1D5DB) // border-gray-300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.lg), // rounded-2xl
    );
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 6).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 5;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter oldDelegate) => false;
}
