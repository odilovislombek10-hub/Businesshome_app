import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../../app/theme.dart';
import 'uzbekistan_map_data.dart';

/// One region's prices, from `/api/market/regions/price-map`.
///
/// For sale these are per m², for rent a whole month — the endpoint documents both under the same
/// `avg_price` / `min_price` / `max_price` keys.
class RegionPrice {
  const RegionPrice({required this.highest, required this.average, required this.lowest});

  final num highest;
  final num average;
  final num lowest;

  factory RegionPrice.fromJson(Map<String, dynamic> json) => RegionPrice(
    highest: (json['max_price'] as num?) ?? 0,
    average: (json['avg_price'] as num?) ?? 0,
    lowest: (json['min_price'] as num?) ?? 0,
  );

  /// Turn the endpoint's list into a map keyed by the ids the drawing uses.
  static Map<String, RegionPrice> parseList(Object? data) {
    if (data is! List) return const {};
    return {
      for (final row in data.whereType<Map<String, dynamic>>())
        if (row['region']?.toString() case final region?)
          _canonicalId(region): RegionPrice.fromJson(row),
    };
  }

  /// The price endpoint and the map drawing spell a few regions differently.
  static String _canonicalId(String region) => switch (region) {
    'syrdarya' => 'sirdaryo',
    'jizzax' => 'jizzakh',
    'navoi' => 'navoiy',
    'khorazm' || 'xorazm' => 'khorezm',
    'kashkadarya' || 'qashqadaryo' => 'qashqadaryo',
    'surkhandarya' => 'surxondaryo',
    'tashkent_region' => 'tashkent',
    _ => region,
  };
}

/// The site's `property-price-map`: a tinted map of Uzbekistan where each region's shade comes
/// from where its prices rank, with rent/buy tabs, a legend and a detail panel on tap.
class PropertyPriceMap extends StatefulWidget {
  const PropertyPriceMap({super.key, required this.rentPrices, required this.buyPrices});

  /// Keyed by region id (`tashkent_city`, `samarkand`, …).
  final Map<String, RegionPrice> rentPrices;
  final Map<String, RegionPrice> buyPrices;

  @override
  State<PropertyPriceMap> createState() => _PropertyPriceMapState();
}

class _PropertyPriceMapState extends State<PropertyPriceMap> {
  bool _rentTab = true;
  String? _selected;

  Map<String, RegionPrice> get _prices => _rentTab ? widget.rentPrices : widget.buyPrices;

  /// Regions ordered priciest first; the index becomes the shade from `colorGradient`.
  Map<String, int> get _ranking {
    final entries = _prices.entries.toList()
      ..sort((a, b) => b.value.average.compareTo(a.value.average));
    return {for (var i = 0; i < entries.length; i++) entries[i].key: i};
  }

  num get _maxPrice => _prices.values.isEmpty
      ? 0
      : _prices.values.map((p) => p.highest).reduce((a, b) => a > b ? a : b);
  num get _minPrice => _prices.values.isEmpty
      ? 0
      : _prices.values.map((p) => p.lowest).reduce((a, b) => a < b ? a : b);
  num get _avgPrice => _prices.values.isEmpty
      ? 0
      : _prices.values.map((p) => p.average).reduce((a, b) => a + b) / _prices.length;

  /// Rent is printed per month in thousands, sale as a price per m².
  String _format(num value) {
    if (value == 0) return '—';
    if (_rentTab) {
      return value >= 1000000
          ? '${(value / 1000000).toStringAsFixed(1)} mln/oy'
          : '${(value / 1000).round()} ming/oy';
    }
    return value >= 1000000
        ? '${(value / 1000000).toStringAsFixed(1)} mln/m²'
        : '${(value / 1000).round()} ming/m²';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranking = _ranking;

    return ColoredBox(
      color: AppColors.cream,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48), // py-12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "O'zbekiston bo'ylab ko'chmas mulk narxlari",
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: AppColors.dark),
            ),
            const SizedBox(height: 16), // mb-4
            // `inline-flex rounded-full border p-1 bg-white`
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.dark.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Tab(
                    label: 'Ijara',
                    active: _rentTab,
                    onTap: () => setState(() {
                      _rentTab = true;
                      _selected = null;
                    }),
                  ),
                  _Tab(
                    label: 'Sotib olish',
                    active: !_rentTab,
                    onTap: () => setState(() {
                      _rentTab = false;
                      _selected = null;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32), // mb-8
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.dark.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: UzbekistanMap.viewBox.width / UzbekistanMap.viewBox.height,
                    child: LayoutBuilder(
                      builder: (context, constraints) => GestureDetector(
                        onTapUp: (details) {
                          final id = _MapPainter.regionAt(
                            details.localPosition,
                            Size(constraints.maxWidth, constraints.maxHeight),
                          );
                          setState(() => _selected = id == _selected ? null : id);
                        },
                        child: CustomPaint(
                          painter: _MapPainter(
                            ranking: ranking,
                            selected: _selected,
                            hasPrices: _prices.isNotEmpty,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                  if (_selected case final id?)
                    _RegionPanel(
                      region: UzbekistanMap.regions.firstWhere((r) => r.id == id),
                      price: _prices[id],
                      format: _format,
                      onBack: () => setState(() => _selected = null),
                    )
                  else
                    _Legend(
                      title: _rentTab ? 'Ijara narxlari' : 'Sotib olish narxlari',
                      highest: _format(_maxPrice),
                      average: _format(_avgPrice),
                      lowest: _format(_minPrice),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.olive : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: active ? Colors.white : AppColors.dark.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Paints every region path scaled into the available box, plus the region labels.
class _MapPainter extends CustomPainter {
  _MapPainter({required this.ranking, required this.selected, required this.hasPrices});

  final Map<String, int> ranking;
  final String? selected;
  final bool hasPrices;

  /// Parsed once — `parseSvgPathData` is not cheap and the geometry never changes.
  static final Map<String, Path> _paths = {
    for (final region in UzbekistanMap.regions) region.id: parseSvgPathData(region.path),
  };

  static double _scaleFor(Size size) => (size.width / UzbekistanMap.viewBox.width).clamp(
    0.0,
    size.height / UzbekistanMap.viewBox.height,
  );

  /// Which region contains [point], in widget coordinates. Null when the tap missed them all.
  static String? regionAt(Offset point, Size size) {
    final scale = _scaleFor(size);
    if (scale <= 0) return null;
    final local = point / scale;
    for (final entry in _paths.entries) {
      if (entry.value.contains(local)) return entry.key;
    }
    return null;
  }

  Color _colorFor(String id) {
    if (id == selected) return UzbekistanMap.selectedColor;
    // No price data means no ranking — fall back to the brand olive, as the site does.
    if (!hasPrices) return AppColors.olive;
    final rank = ranking[id] ?? UzbekistanMap.colorGradient.length - 1;
    return UzbekistanMap.colorGradient[rank.clamp(0, UzbekistanMap.colorGradient.length - 1)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = _scaleFor(size);
    canvas.save();
    canvas.scale(scale);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 1 / scale;

    for (final region in UzbekistanMap.regions) {
      final path = _paths[region.id]!;
      canvas.drawPath(path, Paint()..color = _colorFor(region.id));
      canvas.drawPath(path, stroke);
    }
    canvas.restore();

    // Labels sit above the fills so they stay legible on the darkest regions.
    for (final region in UzbekistanMap.regions) {
      // The site skips the Tashkent city label — the shape is too small to hold it.
      if (region.id == 'tashkent_city') continue;
      final painter = TextPainter(
        text: TextSpan(
          text: region.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 2)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final centre = region.center * scale;
      painter.paint(canvas, centre - Offset(painter.width / 2, painter.height / 2));
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.selected != selected || old.hasPrices != hasPrices || old.ranking != ranking;
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.title,
    required this.highest,
    required this.average,
    required this.lowest,
  });

  final String title;
  final String highest;
  final String average;
  final String lowest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(color: AppColors.dark)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The nine-step colour bar, darkest (priciest) at the top.
              SizedBox(
                width: 12,
                child: Column(
                  children: [
                    for (final color in UzbekistanMap.colorGradient.take(9))
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 1),
                          color: color,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _LegendRow(label: 'Eng yuqori:', value: highest),
                    const SizedBox(height: 8),
                    _LegendRow(label: "O'rtacha:", value: average),
                    const SizedBox(height: 8),
                    _LegendRow(label: 'Eng past:', value: lowest),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.only(top: 12, bottom: 8), child: Divider(height: 1)),
          Text(
            "* Ma'lumotlar so'nggi 3 oy asosida",
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: AppColors.dark.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.6)),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.dark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RegionPanel extends StatelessWidget {
  const _RegionPanel({
    required this.region,
    required this.price,
    required this.format,
    required this.onBack,
  });

  final MapRegion region;
  final RegionPrice? price;
  final String Function(num) format;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBack,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 16, color: AppColors.dark.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(
                  "Narxlar ro'yxatiga qaytish",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.dark.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            region.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          Text(
            region.category,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          if (price == null)
            Text(
              "Bu hudud uchun ma'lumot yo'q",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            )
          else ...[
            _LegendRow(label: 'Eng yuqori:', value: format(price!.highest)),
            const SizedBox(height: 8),
            _LegendRow(label: "O'rtacha:", value: format(price!.average)),
            const SizedBox(height: 8),
            _LegendRow(label: 'Eng past:', value: format(price!.lowest)),
          ],
        ],
      ),
    );
  }
}
