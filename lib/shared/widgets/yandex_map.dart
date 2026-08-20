import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/theme.dart';

/// Xaritada bitta nuqta — `/map` sahifasidagi e'lonlar uchun.
class MapMarker {
  const MapMarker({
    required this.id,
    required this.lat,
    required this.lng,
    this.label,
    this.selected = false,
  });

  final String id;
  final double lat;
  final double lng;

  /// Belgining ustidagi yozuv (saytda narx ko'rsatiladi).
  final String? label;
  final bool selected;

  Map<String, dynamic> toJson() => {
    'id': id,
    'lat': lat,
    'lng': lng,
    'label': label,
    'selected': selected,
  };
}

/// Saytdagi Yandex xaritasi — aynan o'sha JS API 2.1 va o'sha kalit bilan.
///
/// Mobil uchun `yandex_mapkit` paketi ham bor, lekin u **boshqa** (MapKit SDK) kalitini
/// talab qiladi va uslubi saytdagidan farq qiladi. WebView esa saytning o'z sahifasini
/// ishlatadi: bir xil plitalar, bir xil boshqaruv elementlari, bir xil xatti-harakat.
///
/// Dart tomonga xabar `BHMap` kanali orqali keladi.
class YandexMapView extends StatefulWidget {
  const YandexMapView({
    super.key,
    this.center = const (41.3111, 69.2797), // Toshkent — saytdagi `defaultCenter`
    this.zoom = 12,
    this.pickedLat,
    this.pickedLng,
    this.markers = const [],
    this.onPicked,
    this.onMarkerTap,
    this.pickMode = false,
  });

  final (double, double) center;
  final double zoom;

  /// Tanlangan nuqta (tanlash rejimida).
  final double? pickedLat;
  final double? pickedLng;

  final List<MapMarker> markers;

  /// Tanlash rejimida xaritaga bosilganda yoki belgi sudralganda chaqiriladi.
  final void Function(double lat, double lng)? onPicked;

  /// Belgiga bosilganda chaqiriladi.
  final void Function(String id)? onMarkerTap;

  /// `true` — bosilgan joyga belgi qo'yiladi (e'lon yaratish sahifasi).
  final bool pickMode;

  @override
  State<YandexMapView> createState() => _YandexMapViewState();
}

class _YandexMapViewState extends State<YandexMapView> {
  /// Saytning `index.html` dagi kaliti — boshqa kalit olinsa xarita boshqacha hisoblanadi.
  static const _apiKey = '57cd694b-cb63-4a8c-943a-0c03b146bb63';

  late final WebViewController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.surfaceMutedLight)
      ..addJavaScriptChannel(
        'BHMap',
        onMessageReceived: (message) {
          final data = jsonDecode(message.message);
          if (data is! Map) return;
          switch (data['type']) {
            case 'ready':
              setState(() => _ready = true);
            case 'pick':
              widget.onPicked?.call(
                (data['lat'] as num).toDouble(),
                (data['lng'] as num).toDouble(),
              );
            case 'marker':
              widget.onMarkerTap?.call(data['id'].toString());
          }
        },
      )
      ..loadHtmlString(_html(), baseUrl: 'https://businesshome.uz/');
  }

  @override
  void didUpdateWidget(YandexMapView old) {
    super.didUpdateWidget(old);
    if (!_ready) return;
    if (widget.pickedLat != old.pickedLat || widget.pickedLng != old.pickedLng) {
      final lat = widget.pickedLat;
      final lng = widget.pickedLng;
      _controller.runJavaScript(
        lat == null || lng == null ? 'bhClear()' : 'bhSetPoint($lat, $lng)',
      );
    }
    if (widget.markers != old.markers) {
      _controller.runJavaScript(
        'bhSetMarkers(${jsonEncode([for (final m in widget.markers) m.toJson()])})',
      );
    }
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);

  String _html() {
    final (lat, lng) = widget.center;
    final markers = jsonEncode([for (final m in widget.markers) m.toJson()]);
    final picked = widget.pickedLat != null && widget.pickedLng != null
        ? '[${widget.pickedLat}, ${widget.pickedLng}]'
        : 'null';

    // Saytdagi sozlamalar: `controls: ['zoomControl', 'geolocationControl']`,
    // `suppressMapOpenBlock: true`, belgisi `islands#dotIcon` va zaytun rangda.
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>
  html, body, #map { margin: 0; padding: 0; width: 100%; height: 100%; background: #f3f4f6; }
</style>
<script src="https://api-maps.yandex.ru/2.1/?apikey=$_apiKey&lang=ru_RU"></script>
</head>
<body>
<div id="map"></div>
<script>
  var map = null, point = null, markerObjects = [];
  var PICK = ${widget.pickMode};

  function send(payload) { BHMap.postMessage(JSON.stringify(payload)); }

  function bhSetPoint(lat, lng, animate) {
    if (!map) return;
    if (point) map.geoObjects.remove(point);
    point = new ymaps.Placemark([lat, lng], {}, {
      preset: 'islands#dotIcon',
      iconColor: '#999966',
      draggable: true
    });
    point.events.add('dragend', function () {
      var c = point.geometry.getCoordinates();
      send({ type: 'pick', lat: c[0], lng: c[1] });
    });
    map.geoObjects.add(point);
    if (animate !== false) map.setCenter([lat, lng], 15, { duration: 300 });
  }

  function bhClear() {
    if (point && map) { map.geoObjects.remove(point); point = null; }
  }

  function bhSetMarkers(list) {
    if (!map) return;
    markerObjects.forEach(function (m) { map.geoObjects.remove(m); });
    markerObjects = [];
    list.forEach(function (item) {
      var mark = new ymaps.Placemark([item.lat, item.lng], {
        iconContent: item.label || ''
      }, {
        preset: item.label ? 'islands#blueStretchyIcon' : 'islands#dotIcon',
        iconColor: item.selected ? '#3D3D3D' : '#87885C'
      });
      mark.events.add('click', function () { send({ type: 'marker', id: item.id }); });
      map.geoObjects.add(mark);
      markerObjects.push(mark);
    });
  }

  function init() {
    map = new ymaps.Map('map', {
      center: [$lat, $lng],
      zoom: ${widget.zoom},
      controls: ['zoomControl', 'geolocationControl']
    }, { suppressMapOpenBlock: true });

    if (PICK) {
      map.events.add('click', function (e) {
        var c = e.get('coords');
        bhSetPoint(c[0], c[1]);
        send({ type: 'pick', lat: c[0], lng: c[1] });
      });
    }

    var start = $picked;
    if (start) bhSetPoint(start[0], start[1], false);
    bhSetMarkers($markers);
    send({ type: 'ready' });
  }

  // Kalit noto'g'ri yoki tarmoq yo'q bo'lsa `ymaps` umuman kelmaydi — jimgina kutamiz.
  if (typeof ymaps !== 'undefined') ymaps.ready(init);
</script>
</body>
</html>
''';
  }
}
