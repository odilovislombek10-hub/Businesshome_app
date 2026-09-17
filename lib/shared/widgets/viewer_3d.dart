import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../features/project_detail/project_detail_texts.dart';
import '../utils/breakpoints.dart';
import 'ai_assistant.dart';
import 'app_image.dart';
import 'entrance.dart';
import 'site_icon.dart';

/// Loyihaning 3D ko'ruvchisi — saytdagi `viewer3d.component.ts`.
///
/// Ko'ruvchining o'zi alohida ilova (`3d.businesshome.uz`); bu yerda faqat uni o'rab turgan
/// qism: poster + "3D'ni ko'rish" tugmasi, fon rejimidagi preload, to'liq ekran va
/// `postMessage` ko'prigi.

/// Sevimlilardagi 3D kvartiradan to'g'ridan-to'g'ri ko'ruvchini ochish
/// (`?apartment=<id>` bilan) — saytdagi `onFavoriteCardClick()`.
Future<void> openViewer3d(BuildContext context, String url) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => _Viewer3dStandalone(url: url)));
}

/// Ko'ruvchi manzili — saytdagi `buildUrl()`.
String viewer3dUrl({required String developerCode, required String projectCode, int? apartmentId}) {
  final path = developerCode.isEmpty || projectCode.isEmpty
      ? 'test/test'
      : '$developerCode/$projectCode';
  final apartment = apartmentId == null ? '' : '&apartment=$apartmentId';
  return 'https://3d.businesshome.uz/$path/?autostart=1$apartment';
}

/// Saytda iframe sahifa ochilishi bilan **fon rejimida** yuklanadi, ustida esa poster va
/// "3D'ni ko'rish" tugmasi turadi; yuklanib bo'lgach "Ko'rish uchun bosing" yoziladi.
/// Ilovada ham xuddi shunday: WebView darrov yuklanadi, lekin ko'rinmaydi.
class Viewer3dSection extends StatefulWidget {
  const Viewer3dSection({super.key, required this.url, required this.poster});

  final String url;
  final String? poster;

  @override
  State<Viewer3dSection> createState() => Viewer3dSectionState();
}

class Viewer3dSectionState extends State<Viewer3dSection> {
  late final WebViewController _controller;
  bool _ready = false;

  /// To'liq ekran ochilganda WebView o'sha yerga ko'chadi — bitta kontroller ikki
  /// joyda tura olmaydi.
  bool _movedToFullscreen = false;

  @override
  void initState() {
    super.initState();
    // iOS'da WKWebView video'ni sukut bo'yicha **tizim pleyerida** to'liq ekranda ochadi —
    // sahifadagi `playsinline` atributi `allowsInlineMediaPlayback` yoqilmasa e'tiborga
    // olinmaydi. 3D ichidagi o'tish videolari shu sababli pleyerga sakrab chiqardi.
    // `mediaTypesRequiringUserAction` bo'sh — Android'dagi
    // `setMediaPlaybackRequiresUserGesture(false)` ning o'rni.
    final params = WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          )
        : const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.dark)
      // 3D ichidagi o'tish videolari brauzerdagi kabi o'zi o'ynashi kerak.
      // Busiz WebView ularni to'xtatib turadi va ekranda "play" belgisi chiqadi.
      ..addJavaScriptChannel('BHViewer', onMessageReceived: _onViewerMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          // 2026-09-17 dan beri ko'ruvchining "3D dan chiqish" tugmasi iframe ichida
          // bo'lmasa `businesshome.uz/cabinet/favorites` ga **haqiqiy** navigatsiya qiladi
          // (`viewer.component.ts` → `exitMarketEmbed()`). Ilovada ko'ruvchi iframe emas,
          // shuning uchun sayt WebView ichida ochilib ketardi. Bunday o'tishni ushlaymiz:
          // ko'ruvchini yopib, ilovaning o'z sahifasiga o'tamiz.
          onNavigationRequest: (request) {
            final target = Uri.tryParse(request.url);
            final viewer = Uri.tryParse(widget.url);
            if (target == null || viewer == null || target.host == viewer.host) {
              return NavigationDecision.navigate;
            }
            _leaveViewer(target);
            return NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _ready = true);
            _installBridge();
            _installVideoPosterFix();
            // Ko'ruvchi o'zini qayta yuklashi mumkin (uning `version.json` ni kuzatuvchi
            // skripti yangi versiyada keshni tozalab `location.reload()` qiladi). Bunda
            // sahifaga qo'yilgan uslub yo'qoladi — shuning uchun har yuklanishda qayta
            // qo'yiladi, aks holda tugmalar yana holat qatori ostiga tushib qoladi.
            _applySafeArea(_movedToFullscreen);
            // Uslublar jadvali `onPageFinished` paytida hali to'liq o'qilmagan bo'lishi
            // mumkin — bir oz keyin yana bir marta qo'yiladi.
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) _applySafeArea(_movedToFullscreen);
            });
            _sendAuth();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    if (_controller.platform case final AndroidWebViewController android) {
      android.setMediaPlaybackRequiresUserGesture(false);
      android.setOnPlatformPermissionRequest(_onPermissionRequest);
    }

    if (_controller.platform case final WebKitWebViewController webkit) {
      webkit.setOnPlatformPermissionRequest(_onPermissionRequest);
    }

    // Saytda token o'zgarsa (kirish/chiqish) iframe'ga yangi auth yuboriladi.
    _auth = context.read<AuthService>()..addListener(_sendAuth);
  }

  AuthService? _auth;

  @override
  void dispose() {
    _auth?.removeListener(_sendAuth);
    super.dispose();
  }

  /// Saytdagi iframe `allow="... microphone; ..."` bilan ochiladi — 3D ichida sotuvchi bilan
  /// jonli suhbat shu orqali ishlaydi.
  ///
  /// Diqqat: WebView'ga ruxsat berish **yetarli emas** — Android 6 dan beri ilovaning o'zi
  /// tizimdan ruxsat olgan bo'lishi kerak, aks holda `getUserMedia` baribir yiqiladi
  /// (manifestdagi e'lon faqat so'rash huquqini beradi). Shuning uchun avval tizimdan
  /// so'raymiz va faqat berilgandan keyin tasdiqlaymiz. iOS'da tizim o'z oynasini
  /// ko'rsatadi, `permission_handler` esa holatni bir xil qilib beradi.
  Future<void> _onPermissionRequest(PlatformWebViewPermissionRequest request) async {
    final needed = <Permission>{};
    for (final type in request.types) {
      if (type == WebViewPermissionResourceType.microphone) needed.add(Permission.microphone);
      if (type == WebViewPermissionResourceType.camera) needed.add(Permission.camera);
    }
    // Fon rejimida (poster ostida jim yuklanayotganda) mikrofon so'ralsa — rad etamiz:
    // foydalanuvchi hali 3D ni ochmagan, tizim oynasi loyiha sahifasida chiqib qolishi va
    // mikrofon ko'rsatkichi yonib turishi noto'g'ri. To'liq ekranda esa so'raladi.
    if (!_movedToFullscreen && needed.isNotEmpty) {
      await request.deny();
      return;
    }
    if (needed.isEmpty) {
      // Masalan `protectedMediaId` — tizim ruxsati talab qilinmaydi.
      await request.grant();
      return;
    }
    final statuses = await needed.toList().request();
    if (statuses.values.every((status) => status.isGranted)) {
      await request.grant();
    } else {
      await request.deny();
    }
  }

  /// Saytda 3D ko'ruvchi ota oynaga `postMessage` yuboradi. WebView ichida
  /// `window.parent` — o'zi, shuning uchun xabarni shu yerda tutib Dart tomonga
  /// uzatamiz (`viewer3d.component.ts` dagi `onChildMessage` ning o'rni).
  Future<void> _installBridge() async {
    try {
      await _controller.runJavaScript('''
        if (!window.__bhBridge) {
          window.__bhBridge = true;
          window.addEventListener('message', function (e) {
            var d = e && e.data;
            if (!d || typeof d !== 'object' || !d.type) return;
            // Saytdagidek: auth xabarlari faqat ko'ruvchining o'z origin'idan qabul
            // qilinadi. `bh.exit3d` esa ko'ruvchining o'zidan keladi (origin bo'sh
            // bo'lishi mumkin), shuning uchun undan oldin tekshiriladi.
            if (d.type !== 'bh.exit3d' && e.origin && e.origin !== location.origin) return;
            try { BHViewer.postMessage(JSON.stringify(d)); } catch (err) {}
          });
        }
      ''');
    } catch (_) {}
  }

  /// Android WebView `<video>` da kadr ham, `poster` ham bo'lmasa **o'z o'rinbosarini**
  /// chizadi — kulrang fon va katta "play" uchburchagi. 3D ichida video manzili bir zumga
  /// keyin qo'yilgani uchun har bir 360 o'tishida va loop videoda o'sha o'rinbosar yonib
  /// o'tadi. Brauzerda ham shunday bo'ladi, faqat u yerda ko'zga tashlanmaydi.
  ///
  /// Yechim: har bir videoga 1×1 shaffof `poster` beriladi — bunda WebView o'z o'rinbosarini
  /// chizmaydi, ortidagi qatlam (kadr surati) ko'rinib turaveradi.
  Future<void> _installVideoPosterFix() async {
    try {
      await _controller.runJavaScript('''
        (function () {
          if (window.__bhVideoPoster) return;
          window.__bhVideoPoster = true;
          var BLANK = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAAB'
                    + 'AAEAAAIBRAA7';
          function fix() {
            var list = document.getElementsByTagName('video');
            for (var i = 0; i < list.length; i++) {
              if (!list[i].getAttribute('poster')) list[i].setAttribute('poster', BLANK);
            }
          }
          fix();
          var timer = null;
          new MutationObserver(function () {
            if (timer) return;
            timer = setTimeout(function () { timer = null; fix(); }, 100);
          }).observe(document.documentElement, { subtree: true, childList: true });
        })();
      ''');
    } catch (_) {
      // Sahifa tayyor bo'lmasa — keyingi yuklanishda qayta qo'yiladi.
    }
  }

  void _onViewerMessage(JavaScriptMessage message) {
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(message.message);
      if (decoded is! Map) return;
      data = decoded.cast<String, dynamic>();
    } catch (_) {
      return;
    }
    switch (data['type']) {
      case 'bh.exit3d':
        // Ko'ruvchi menyusidagi "3D dan chiqish".
        if (_movedToFullscreen && mounted) Navigator.of(context).pop();
      case 'bh:auth-request':
        // Saytdagi kabi 2 soniyada bir marta (halqa bo'lib qolmasligi uchun).
        final now = DateTime.now();
        if (_lastAuthRequest != null &&
            now.difference(_lastAuthRequest!) < const Duration(seconds: 2)) {
          return;
        }
        _lastAuthRequest = now;
        _sendAuth();
      case 'bh:request-login':
        if (mounted) context.push('/login');
    }
  }

  DateTime? _lastAuthRequest;

  /// Saytda token iframe'ga `postMessage({type:'bh:auth', …})` orqali beriladi — 3D ichidagi
  /// "Sevimlilar" tugmasi shuning hisobiga ishlaydi.
  Future<void> _sendAuth() async {
    if (!mounted) return;
    final user = context.read<AuthService>().user;
    final token = await ApiClient.instance.accessToken();
    final payload = jsonEncode({
      'type': 'bh:auth',
      'token': token,
      'apiUrl': ApiClient.baseUrl,
      'user': user == null
          ? null
          : {'id': user.id, 'fullName': user.fullName, 'phone': user.phone, 'role': user.role.name},
    });
    try {
      await _controller.runJavaScript('window.postMessage($payload, "*");');
    } catch (_) {
      // 3D sahifasi hali tayyor bo'lmasa — jim o'tamiz, saytda ham xatolik chiqmaydi.
    }
  }

  /// Prezentatsiya rejimi oxirida tashqaridan chaqiriladi (`reveal`).
  void open() => unawaited(_open());

  /// To'liq ekran yopilguncha kutadi — sevimlilardan to'g'ridan-to'g'ri ochishda kerak.
  Future<void> openAndWait() => _open();

  /// Ko'ruvchi saytga o'tmoqchi bo'lganda: to'liq ekranni yopamiz va manzil ilovada bor
  /// bo'lsa o'sha sahifaga o'tamiz (saytda ham "chiqish" sevimlilarga olib boradi).
  void _leaveViewer(Uri target) {
    if (!mounted) return;
    if (_movedToFullscreen) Navigator.of(context).pop();
    final path = target.path.isEmpty ? '/' : target.path;
    if (_appRoutes.any(path.startsWith)) {
      context.go(path);
    }
  }

  /// Ko'ruvchi yuborishi mumkin bo'lgan, ilovada ham bor yo'llar. Saytda ikkita joy bor:
  /// "3D dan chiqish" → `/cabinet/favorites`, kirish so'ralganda → `/login?redirect=...`
  /// (`parent-auth.service.ts` → `requestLogin()`), qolganlari ehtiyot uchun.
  static const _appRoutes = [
    '/cabinet',
    '/login',
    '/register',
    '/property',
    '/new-projects',
    '/secondary',
    '/rent',
    '/designers',
    '/masters',
    '/ads',
    '/news',
    '/birja',
    '/map',
  ];

  Future<void> _open() async {
    setState(() => _movedToFullscreen = true);
    await _applySafeArea(true);
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => _Viewer3dPage(controller: _controller)));
    await _applySafeArea(false);
    if (mounted) setState(() => _movedToFullscreen = false);
  }

  /// Ko'ruvchi notch/Dynamic Island dan qochish uchun `env(safe-area-inset-*)` ga tayanadi
  /// (`3d/src/styles.css` dagi `.notch-safe-*` klasslari va shablonlardagi inline uslublar).
  /// Brauzerda bu qiymatlarni tizim beradi, WebView ichida esa **nol** bo'lib qoladi —
  /// natijada yuqoridagi tugmalar holat qatorining ustiga chiqib ketadi.
  ///
  /// Shuning uchun Flutter'dan olingan haqiqiy o'lchamlar ko'ruvchiga uzatiladi:
  /// 1. `env(...)` ishlatadigan barcha qoidalar piksel qiymati bilan qayta yoziladi;
  /// 2. o'ng yuqoridagi boshqaruv guruhi (`data-tour="zoom-controls"`) alohida — u to'liq
  ///    ekran rejimida bo'lmaganda umuman `env()` ishlatmaydi, `top-4` (16px) bilan turadi;
  /// 3. inline uslublardagi `env(...)` ham almashtiriladi (Angular ularni qayta qo'ysa,
  ///    `MutationObserver` yana tuzatadi).
  Future<void> _applySafeArea(bool fullscreen) async {
    if (!mounted) return;
    final padding = MediaQuery.viewPaddingOf(context);
    final top = fullscreen ? padding.top.round() : 0;
    final bottom = fullscreen ? padding.bottom.round() : 0;
    final left = fullscreen ? padding.left.round() : 0;
    final right = fullscreen ? padding.right.round() : 0;
    final args = jsonEncode({'t': top, 'b': bottom, 'l': left, 'r': right});
    try {
      await _controller.runJavaScript('''
        (function (i) {
          var STATE = window.__bhSafe || (window.__bhSafe = {});
          STATE.i = i;

          function px(text) {
            return String(text)
              .replace(/env\\(\\s*safe-area-inset-top[^)]*\\)/g, i.t + 'px')
              .replace(/env\\(\\s*safe-area-inset-bottom[^)]*\\)/g, i.b + 'px')
              .replace(/env\\(\\s*safe-area-inset-left[^)]*\\)/g, i.l + 'px')
              .replace(/env\\(\\s*safe-area-inset-right[^)]*\\)/g, i.r + 'px');
          }

          // 1-2. Uslublar jadvalidagi qoidalar.
          function collect(rules, media, out) {
            for (var k = 0; k < rules.length; k++) {
              var rule = rules[k];
              if (rule.cssRules && rule.conditionText !== undefined) {
                collect(rule.cssRules, media ? media + ' and ' + rule.conditionText
                                             : rule.conditionText, out);
                continue;
              }
              if (!rule.selectorText || !rule.cssText) continue;
              if (rule.cssText.indexOf('safe-area-inset') < 0) continue;
              var decls = '';
              for (var d = 0; d < rule.style.length; d++) {
                var name = rule.style[d];
                var value = rule.style.getPropertyValue(name);
                if (value.indexOf('safe-area-inset') < 0) continue;
                decls += name + ':' + px(value) + ' !important;';
              }
              if (!decls) continue;
              var text = rule.selectorText + '{' + decls + '}';
              out.push(media ? '@media ' + media + '{' + text + '}' : text);
            }
          }

          var css = [];
          for (var n = 0; n < document.styleSheets.length; n++) {
            var sheet = document.styleSheets[n], rules;
            try { rules = sheet.cssRules; } catch (e) { continue; }
            if (rules) collect(rules, '', css);
          }
          // O'ng yuqoridagi guruh: to'liq ekran rejimida bo'lmagani uchun `top-4` bilan
          // turadi va `env()` ni umuman o'qimaydi.
          if (i.t > 0) {
            css.push('[data-tour="zoom-controls"]{top:calc(1rem + ' + i.t + 'px)!important;}');
            css.push('@media (orientation: landscape){[data-tour="zoom-controls"]' +
                     '{top:calc(6px + ' + i.t + 'px)!important;}}');
          }

          var el = document.getElementById('bh-safe-area');
          if (!el) {
            el = document.createElement('style');
            el.id = 'bh-safe-area';
            document.head.appendChild(el);
          }
          el.textContent = i.t || i.b || i.l || i.r ? css.join('\\n') : '';

          // 3. Inline uslublar.
          function fixInline() {
            var nodes = document.querySelectorAll('[style*="safe-area-inset"]');
            for (var m = 0; m < nodes.length; m++) {
              var node = nodes[m];
              var raw = node.getAttribute('style');
              if (!raw) continue;
              if (!node.__bhRaw) node.__bhRaw = raw;
              node.setAttribute('style', px(node.__bhRaw));
            }
          }
          fixInline();
          if (!STATE.observer) {
            STATE.observer = new MutationObserver(function () {
              if (STATE.timer) return;
              STATE.timer = setTimeout(function () { STATE.timer = null; fixInline(); }, 150);
            });
            STATE.observer.observe(document.documentElement,
              { subtree: true, childList: true, attributes: true, attributeFilter: ['style'] });
          }
        })($args);
      ''');
    } catch (_) {
      // Sahifa hali tayyor bo'lmasa — keyingi ochilishda qayta qo'yiladi.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final poster = widget.poster;
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
        child: SizedBox(
          // `clamp(340px, 68vh, 700px)`
          height: (MediaQuery.sizeOf(context).height * 0.68).clamp(340.0, 700.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ko'ruvchi poster **ostida** turadi. Diqqat: `Opacity(0)` bilan o'ralsa
              // Flutter platforma ko'rinishini umuman chizmaydi, Chromium esa uni
              // "ko'rinmayapti" deb hisoblab `requestAnimationFrame` ni to'xtatadi —
              // natijada 3D fon rejimida yuklanmay, 0% da qotib turadi. Saytda iframe
              // `opacity-0` bo'lsa ham brauzer uni chizadi, shuning uchun preload ketadi.
              if (!_movedToFullscreen) WebViewWidget(controller: _controller),
              IgnorePointer(
                child: poster == null || poster.isEmpty
                    ? const ColoredBox(color: AppColors.dark)
                    : AppImage(imageUrl: poster, fit: BoxFit.cover),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.dark.withValues(alpha: 0.7),
                        AppColors.dark.withValues(alpha: 0.2),
                        AppColors.dark.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Pressable(
                  scale: 0.97,
                  onTap: _open,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        // `w-16 h-16 md:w-20 md:h-20`
                        width: Bp.pick(context, base: 64.0, md: 80.0),
                        height: Bp.pick(context, base: 64.0, md: 80.0),
                        decoration: const BoxDecoration(
                          color: AppColors.olive,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4), // ml-1
                            child: SiteIcon(
                              SiteIcons.play,
                              size: Bp.pick(context, base: 32.0, md: 40.0),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12), // gap-3
                      Text(
                        ProjectDetailTexts.viewer3dView,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: Bp.pick(context, base: 18.0, md: 20.0), // text-lg md:text-xl
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _ready
                                  ? const Color(0xFF34D399) // emerald-400
                                  : const Color(0xFFFBBF24), // amber-400
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6), // gap-1.5
                          Text(
                            _ready
                                ? ProjectDetailTexts.viewer3dReady
                                : ProjectDetailTexts.viewer3dPreloading,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: Bp.pick(context, base: 12.0, md: 14.0),
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Oldindan yuklangan ko'ruvchi to'liq ekranda — saytdagi `fixed inset-0 z-[9999]`.
///
/// Saytda bu holatda ekranga **hech narsa qo'shilmaydi**: yopish tugmasi ham,
/// "Aziza" tugmasi ham ko'rinmaydi (3D `z-[9999]`, Aziza `z-[9998]`). Chiqish
/// ko'ruvchining o'z menyusidagi "3D dan chiqish" orqali bo'ladi — u ota
/// oynaga `bh.exit3d` yuboradi.
class _Viewer3dPage extends StatefulWidget {
  const _Viewer3dPage({required this.controller});

  final WebViewController controller;

  @override
  State<_Viewer3dPage> createState() => _Viewer3dPageState();
}

class _Viewer3dPageState extends State<_Viewer3dPage> {
  @override
  void initState() {
    super.initState();
    // Qurilish paytida o'zgartirilsa `ValueListenableBuilder` qayta chizilmaydi,
    // shuning uchun kadr tugagach aytamiz.
    WidgetsBinding.instance.addPostFrameCallback((_) => AiAssistant.hidden.value++);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) => AiAssistant.hidden.value--);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.dark,
    body: WebViewWidget(controller: widget.controller),
  );
}

/// Sevimlilardagi 3D kvartira bosilganda ochiladigan sahifa: poster ko'rsatilmaydi,
/// ko'ruvchi darrov to'liq ekranda ochiladi.
class _Viewer3dStandalone extends StatefulWidget {
  const _Viewer3dStandalone({required this.url});

  final String url;

  @override
  State<_Viewer3dStandalone> createState() => _Viewer3dStandaloneState();
}

class _Viewer3dStandaloneState extends State<_Viewer3dStandalone> {
  final _section = GlobalKey<Viewer3dSectionState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _section.currentState?.openAndWait();
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.dark,
    body: Viewer3dSection(key: _section, url: widget.url, poster: null),
  );
}
