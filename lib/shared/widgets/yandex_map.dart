import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/theme.dart';

/// Xaritada bitta e'lon — saytdagi narx "pin"i.
class MapMarker {
  const MapMarker({
    required this.id,
    required this.lat,
    required this.lng,
    this.label,
    this.hint,
    this.rent = false,
    this.selected = false,
  });

  final String id;
  final double lat;
  final double lng;

  /// Pin ustidagi yozuv — saytda narx (`formatPriceLabel`).
  final String? label;

  /// Yandex "hint"i — saytda e'lon sarlavhasi.
  final String? hint;

  /// Ijara pinlari ko'k, sotuvniki zaytun (`.price-pin.rent` / `.sell`).
  final bool rent;
  final bool selected;

  Map<String, dynamic> toJson() => {
    'id': id,
    'lat': lat,
    'lng': lng,
    'label': label,
    'hint': hint,
    'rent': rent,
    'selected': selected,
  };
}

/// Backend zoom past bo'lganda alohida e'lon o'rniga klaster qaytaradi.
class MapCluster {
  const MapCluster({required this.lat, required this.lng, required this.count});

  final double lat;
  final double lng;
  final int count;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'count': count};
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
    this.clusters = const [],
    this.onPicked,
    this.onMarkerTap,
    this.onViewportChanged,
    this.pickMode = false,
  });

  final (double, double) center;
  final double zoom;

  /// Tanlangan nuqta (tanlash rejimida).
  final double? pickedLat;
  final double? pickedLng;

  final List<MapMarker> markers;

  /// Backend qaytargan klasterlar — bosilganda xarita yaqinlashadi.
  final List<MapCluster> clusters;

  /// Tanlash rejimida xaritaga bosilganda yoki belgi sudralganda chaqiriladi.
  final void Function(double lat, double lng)? onPicked;

  /// Belgiga bosilganda chaqiriladi.
  final void Function(String id)? onMarkerTap;

  /// Xarita surilganda/yaqinlashtirilganda — saytda shu chegaralar bilan qayta so'raladi.
  final void Function(double latMin, double latMax, double lngMin, double lngMax, double zoom)?
  onViewportChanged;

  /// `true` — bosilgan joyga belgi qo'yiladi (e'lon yaratish sahifasi).
  final bool pickMode;

  @override
  YandexMapViewState createState() => YandexMapViewState();
}

class YandexMapViewState extends State<YandexMapView> {
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
            case 'viewport':
              widget.onViewportChanged?.call(
                (data['latMin'] as num).toDouble(),
                (data['latMax'] as num).toDouble(),
                (data['lngMin'] as num).toDouble(),
                (data['lngMax'] as num).toDouble(),
                (data['zoom'] as num).toDouble(),
              );
          }
        },
      )
      ..loadHtmlString(_html(), baseUrl: 'https://businesshome.uz/');
  }

  @override
  void didUpdateWidget(covariant YandexMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready) return;
    if (widget.pickedLat != oldWidget.pickedLat || widget.pickedLng != oldWidget.pickedLng) {
      final lat = widget.pickedLat;
      final lng = widget.pickedLng;
      _controller.runJavaScript(
        lat == null || lng == null ? 'bhClear()' : 'bhSetPoint($lat, $lng)',
      );
    }
    if (widget.markers != oldWidget.markers || widget.clusters != oldWidget.clusters) {
      _controller.runJavaScript(
        'bhSetMarkers(${jsonEncode([for (final m in widget.markers) m.toJson()])}, '
        '${jsonEncode([for (final c in widget.clusters) c.toJson()])})',
      );
    }
  }

  /// Saytdagi xarita boshqaruvlari (`zoomIn`, `zoomOut`, `resetMap`, `toggleMapType`).
  void zoomIn() => _controller.runJavaScript('bhZoomIn()');
  void zoomOut() => _controller.runJavaScript('bhZoomOut()');
  void resetMap() => _controller.runJavaScript('bhResetMap()');
  void setMapType(String type) => _controller.runJavaScript("bhSetMapType('$type')");

  /// "Mening joylashuvim" — saytda `map.setCenter([lat, lng], 14, { duration: 400 })`.
  void centerOn(double lat, double lng, {double zoom = 14}) =>
      _controller.runJavaScript('bhCenter($lat, $lng, $zoom)');

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);

  String _html() {
    final (lat, lng) = widget.center;
    final markers = jsonEncode([for (final m in widget.markers) m.toJson()]);
    final clusters = jsonEncode([for (final c in widget.clusters) c.toJson()]);
    final picked = widget.pickedLat != null && widget.pickedLng != null
        ? '[${widget.pickedLat}, ${widget.pickedLng}]'
        : 'null';

    // Uslublar `styles.css` dagi `.price-pin` va `.cluster-pin` dan bir-bir ko'chirildi,
    // sozlamalar esa `map-search.component.ts` dan: `Clusterer(gridSize: 96, minClusterSize: 2)`,
    // pin o'lchami 90x36 va o'qi pastda, klaster doirasi 44px.
    return """
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>
  html, body, #map { margin: 0; padding: 0; width: 100%; height: 100%; background: #f3f4f6; }

  .price-pin {
    display: inline-flex; align-items: center; justify-content: center;
    padding: 4px 10px; border-radius: 20px;
    font-family: -apple-system, system-ui, sans-serif;
    font-size: 12px; font-weight: 700; white-space: nowrap;
    box-shadow: 0 2px 8px rgba(0,0,0,.2); cursor: pointer;
    transition: all .2s ease; position: relative;
  }
  .price-pin::after {
    content: ''; position: absolute; bottom: -6px; left: 50%;
    transform: translateX(-50%); width: 0; height: 0;
    border-left: 6px solid transparent; border-right: 6px solid transparent;
  }
  .price-pin.rent { background: #3b82f6; color: #fff; }
  .price-pin.rent::after { border-top: 6px solid #3b82f6; }
  .price-pin.sell { background: #999966; color: #fff; }
  .price-pin.sell::after { border-top: 6px solid #999966; }
  .price-pin.active { transform: scale(1.15); z-index: 1000 !important; }
  .price-pin.active.rent { background: #1d4ed8; box-shadow: 0 4px 12px rgba(59,130,246,.4); }
  .price-pin.active.rent::after { border-top-color: #1d4ed8; }
  .price-pin.active.sell { background: #3D3D3D; box-shadow: 0 4px 12px rgba(135,136,92,.4); }
  .price-pin.active.sell::after { border-top-color: #3D3D3D; }

  .cluster-pin {
    display: inline-flex; align-items: center; justify-content: center;
    width: 44px; height: 44px; border-radius: 50%;
    background: #999966; color: #fff;
    font-family: -apple-system, system-ui, sans-serif;
    font-size: 14px; font-weight: 700;
    box-shadow: 0 2px 8px rgba(0,0,0,.25); border: 3px solid #fff;
    transform: translate(-50%, -50%);
  }
</style>
<script src="https://api-maps.yandex.ru/2.1/?apikey=$_apiKey&lang=ru_RU"></script>
</head>
<body>
<div id="map"></div>
<script>
  var map = null, point = null, clusterer = null, clusterPins = [];
  var PICK = ${widget.pickMode};

  function send(payload) { BHMap.postMessage(JSON.stringify(payload)); }

  // Bo'sh SVG — haqiqiy ko'rinish `iconContentLayout` dagi HTML orqali chiziladi.
  function blank(w, h) {
    return 'data:image/svg+xml;utf8,' + encodeURIComponent(
      '<svg xmlns="http://www.w3.org/2000/svg" width="' + w + '" height="' + h + '"></svg>');
  }

  function bhSetPoint(lat, lng, animate) {
    if (!map) return;
    if (point) map.geoObjects.remove(point);
    point = new ymaps.Placemark([lat, lng], {}, {
      preset: 'islands#dotIcon', iconColor: '#999966', draggable: true
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

  function bhZoomIn() { if (map) map.setZoom(map.getZoom() + 1, { duration: 200 }); }
function bhZoomOut() { if (map) map.setZoom(map.getZoom() - 1, { duration: 200 }); }
function bhResetMap() { if (map) map.setCenter(BH_CENTER, BH_ZOOM, { duration: 300 }); }
function bhCenter(lat, lng, zoom) { if (map) map.setCenter([lat, lng], zoom, { duration: 400 }); }
function bhSetMapType(type) {
  if (map) map.setType(type === 'satellite' ? 'yandex#satellite' : 'yandex#map');
}

function bhSetMarkers(list, clusters) {
    if (!map) return;
    if (clusterer) { map.geoObjects.remove(clusterer); clusterer = null; }
    clusterPins.forEach(function (pm) { try { map.geoObjects.remove(pm); } catch (e) {} });
    clusterPins = [];

    clusterer = new ymaps.Clusterer({
      groupByCoordinates: false,
      gridSize: 96,
      minClusterSize: 2,
      clusterDisableClickZoom: false,
      clusterOpenBalloonOnClick: false,
      clusterIconLayout: ymaps.templateLayoutFactory.createClass(
        '<div class="cluster-pin">{{ properties.geoObjects.length }}</div>'),
      clusterIconShape: { type: 'Circle', coordinates: [0, 0], radius: 22 }
    });

    var pins = list.map(function (item) {
      var css = 'price-pin ' + (item.rent ? 'rent' : 'sell') + (item.selected ? ' active' : '');
      var pm = new ymaps.Placemark([item.lat, item.lng], { hintContent: item.hint || '' }, {
        hasBalloon: false,
        iconLayout: 'default#imageWithContent',
        iconImageHref: blank(90, 36),
        iconImageSize: [90, 36],
        iconImageOffset: [-45, -36],
        iconContentOffset: [0, 0],
        iconContentLayout: ymaps.templateLayoutFactory.createClass(
          '<div class="' + css + '">' + (item.label || '') + '</div>')
      });
      pm.events.add('click', function () { send({ type: 'marker', id: item.id }); });
      return pm;
    });
    clusterer.add(pins);
    map.geoObjects.add(clusterer);

    (clusters || []).forEach(function (c) {
      var label = c.count >= 1000 ? Math.round(c.count / 1000) + 'K' : String(c.count);
      var pm = new ymaps.Placemark([c.lat, c.lng], { hintContent: c.count + " ta e'lon" }, {
        hasBalloon: false,
        iconLayout: 'default#imageWithContent',
        iconImageHref: blank(44, 44),
        iconImageSize: [44, 44],
        iconImageOffset: [-22, -22],
        iconContentOffset: [0, 0],
        iconContentLayout: ymaps.templateLayoutFactory.createClass(
          '<div class="cluster-pin">' + label + '</div>')
      });
      // Saytdagidek — klaster bosilsa ikki pog'ona yaqinlashadi.
      pm.events.add('click', function () {
        var z = Math.min((map.getZoom ? map.getZoom() : 12) + 2, 17);
        map.setCenter([c.lat, c.lng], z, { duration: 300 });
      });
      map.geoObjects.add(pm);
      clusterPins.push(pm);
    });
  }

  function reportViewport() {
    if (!map) return;
    var b = map.getBounds();
    send({
      type: 'viewport',
      latMin: b[0][0], lngMin: b[0][1],
      latMax: b[1][0], lngMax: b[1][1],
      zoom: map.getZoom()
    });
  }

  function init() {
    window.BH_CENTER = [$lat, $lng];
  window.BH_ZOOM = ${widget.zoom};
  map = new ymaps.Map('map', {
      center: [$lat, $lng],
      zoom: ${widget.zoom},
      // Saytda `/map` sahifasi o'z tugmalarini chizadi (`controls: []`), e'lon
      // yaratishda esa Yandex'ning masshtab va joylashuv tugmalari turadi.
      controls: ${widget.pickMode ? "['zoomControl', 'geolocationControl']" : '[]'}
    }, { suppressMapOpenBlock: true, yandexMapDisablePoiInteractivity: true });

    if (PICK) {
      map.events.add('click', function (e) {
        var c = e.get('coords');
        bhSetPoint(c[0], c[1]);
        send({ type: 'pick', lat: c[0], lng: c[1] });
      });
    }

    var start = $picked;
    if (start) bhSetPoint(start[0], start[1], false);
    bhSetMarkers($markers, $clusters);

    // Sayt xarita to'xtagach qayta so'rov yuboradi.
    map.events.add('boundschange', function () {
      clearTimeout(window.__bhVp);
      window.__bhVp = setTimeout(reportViewport, 400);
    });

    send({ type: 'ready' });
  }

  // Kalit noto'g'ri yoki tarmoq yo'q bo'lsa `ymaps` umuman kelmaydi — jimgina kutamiz.
  if (typeof ymaps !== 'undefined') ymaps.ready(init);
</script>
</body>
</html>
""";
  }
}
