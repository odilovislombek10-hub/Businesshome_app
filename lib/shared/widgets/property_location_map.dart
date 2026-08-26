import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/theme.dart';
import 'entrance.dart';
import 'my_location_button.dart';

/// `property-map.component.ts` — mulk joylashuvi va "Yaqin atrofda" qidiruvi.
///
/// Saytdagidek Yandex JS API 2.1: bitta belgi mulk ustida, yorliq bosilganda
/// yashirin `SearchControl` orqali atrofdan izlanadi (`кафе, ресторан` kabi
/// so'rovlar ham saytdan aynan olingan).
class PropertyLocationMap extends StatefulWidget {
  const PropertyLocationMap({
    super.key,
    required this.lat,
    required this.lng,
    required this.address,
    required this.title,
  });

  final double lat;
  final double lng;
  final String address;
  final String title;

  @override
  State<PropertyLocationMap> createState() => _PropertyLocationMapState();
}

class _PropertyLocationMapState extends State<PropertyLocationMap> {
  /// Saytning `index.html` dagi kaliti.
  static const _apiKey = '57cd694b-cb63-4a8c-943a-0c03b146bb63';

  static const _categories = <({String id, String label, String icon, String query})>[
    (id: 'food', label: 'Kafelar', icon: '🍽️', query: 'кафе, ресторан'),
    (id: 'school', label: 'Maktablar', icon: '🏫', query: 'школа'),
    (id: 'kindergarten', label: "Bog'chalar", icon: '👶', query: 'детский сад'),
    (id: 'hospital', label: 'Shifoxonalar', icon: '🏥', query: 'больница, поликлиника'),
    (id: 'shopping', label: 'Savdo markazlari', icon: '🛒', query: 'торговый центр, магазин'),
    (id: 'park', label: 'Parklar', icon: '🌳', query: 'парк'),
    (id: 'metro', label: 'Metro', icon: '🚇', query: 'метро'),
    (id: 'gym', label: 'Fitnes', icon: '🏋️', query: 'фитнес, спортзал'),
  ];

  late final WebViewController _controller;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.surfaceMutedLight)
      ..loadHtmlString(_html(), baseUrl: 'https://businesshome.uz/');
  }

  void _toggle(({String id, String label, String icon, String query}) category) {
    if (_selected == category.id) {
      setState(() => _selected = null);
      _controller.runJavaScript('bhClearNearby()');
      return;
    }
    setState(() => _selected = category.id);
    _controller.runJavaScript("bhSearchNearby('${category.query}')");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceMutedLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20), // p-5
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.surfaceMutedLight)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Joylashuv',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4), // mt-1
                Text(
                  widget.address,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 400, // h-[400px]
            child: Stack(
              children: [
                Positioned.fill(child: WebViewWidget(controller: _controller)),
                // Saytdagi `absolute top-3 right-3` — mulk joyi o'zgarmaydi, faqat
                // ko'rinish siljiydi (`onMyLocation`).
                Positioned(
                  top: 12,
                  right: 12,
                  child: MyLocationButton(
                    onLocated: (lat, lng) => _controller.runJavaScript('bhCenter($lat, $lng)'),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.surfaceMutedLight)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yaqin atrofda',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 12), // mb-3
                Wrap(
                  spacing: 8, // gap-2
                  runSpacing: 8,
                  children: [for (final category in _categories) _chip(theme, category)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(ThemeData theme, ({String id, String label, String icon, String query}) category) {
    final active = _selected == category.id;
    return Pressable(
      scale: 0.97,
      onTap: () => _toggle(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // px-3 py-2
        decoration: BoxDecoration(
          color: active ? AppColors.olive : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: active ? AppColors.olive : AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6), // gap-1.5
            Text(
              category.label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _html() {
    final hint = widget.title.replaceAll("'", r"\'");
    final body = widget.address.replaceAll("'", r"\'");
    return """
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>html, body, #map { margin:0; padding:0; width:100%; height:100%; background:#f3f4f6; }</style>
<script src="https://api-maps.yandex.ru/2.1/?apikey=$_apiKey&lang=uz_UZ"></script>
</head>
<body>
<div id="map"></div>
<script>
var map, searchControl;

function bhCenter(lat, lng) {
  if (map) map.setCenter([lat, lng], 14, { duration: 400 });
}

ymaps.ready(function () {
  map = new ymaps.Map('map', {
    center: [${widget.lat}, ${widget.lng}],
    zoom: 15,
    controls: ['zoomControl'],
  }, { suppressMapOpenBlock: true });

  map.geoObjects.add(new ymaps.Placemark([${widget.lat}, ${widget.lng}], {
    hintContent: '$hint',
    balloonContentHeader: '$hint',
    balloonContentBody: '$body',
  }, { preset: 'islands#greenHomeCircleIcon' }));

  // Yashirin qidiruv boshqaruvi — natijalar xaritada belgi bo'lib chiqadi.
  searchControl = new ymaps.control.SearchControl({
    options: {
      provider: 'yandex#search',
      noPlacemark: true,
      noCentering: true,
      noPopup: true,
      noSuggestPanel: true,
      resultsPerPage: 15,
      visible: false,
    },
  });
  map.controls.add(searchControl);
});

function bhSearchNearby(query) {
  if (!map || !searchControl) return;
  bhClearNearby();
  var d = 0.02;
  map.setBounds([[${widget.lat} - d, ${widget.lng} - d], [${widget.lat} + d, ${widget.lng} + d]],
                { checkZoomRange: true });
  searchControl.search(query);
}

function bhClearNearby() {
  if (!searchControl) return;
  try { searchControl.clear(); } catch (e) {}
  if (map) map.setCenter([${widget.lat}, ${widget.lng}], 15, { duration: 300 });
}
</script>
</body>
</html>
""";
  }
}
