import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Rasm keshi — diskda 30 kun, 1000 tagacha fayl.
///
/// **Nega o'zimizniki kerak:** `businesshome.uz/api/market/media/...` rasm so'raganda
/// `302 Found` + `Cache-Control: no-cache` qaytaradi (haqiqiy fayl Cloudflare R2 da). Sukut
/// bo'yicha kesh menejeri server aytgan qoidaga bo'ysunadi va faylni **umuman saqlamaydi** —
/// tekshirdik: kesh papkasi bo'sh edi, ya'ni har safar ilova ochilganda barcha rasmlar qaytadan
/// yuklanardi. Bu sekin internetda katta yo'qotish.
///
/// [Config.stalePeriod] serverning ko'rsatmasi o'rniga bizning muddatimizni qo'yadi.
///
/// **To'g'ri yechim baribir serverda:** media redirecti `Cache-Control: public, max-age=...`
/// yuborishi kerak, shunda brauzer/CDN ham keshlaydi.
final imageCacheManager = CacheManager(
  Config('bh_images', stalePeriod: const Duration(days: 30), maxNrOfCacheObjects: 1000),
);

/// Tarmoqdan keladigan rasm — ilovadagi barcha rasmlar shu orqali chiziladi.
///
/// [CachedNetworkImage] ning ustidagi yupqa qobiq, uchta farq bilan:
///
/// 1. **O'z kesh menejeri** — yuqoridagi izohga qarang.
///
/// 2. **Paydo bo'lish animatsiyasi o'chirilgan.** Paketning sukut bo'yicha 500 ms li
///    "fade-in" i keshdagi rasmga ham qo'llanadi. Ro'yxatni pastga surib qaytganda widget
///    qayta quriladi va o'sha yarim soniyalik oqarish "rasm qaytadan yuklanyapti" bo'lib
///    ko'rinadi.
///
/// 3. **`memCacheWidth`** — rasm ekrandagi o'lchamiga qarab dekodlanadi. Serverdan 1920px li
///    surat kelsa ham, 172px li kartaga to'liq o'lchamda dekodlash xotirani behuda yeydi.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        final logicalWidth = width ?? constraints.maxWidth;
        // Cheksiz kenglikda (masalan gorizontal ro'yxatda) dekodlash cheklanmaydi.
        final cacheWidth = logicalWidth.isFinite ? (logicalWidth * devicePixelRatio).round() : null;

        return CachedNetworkImage(
          imageUrl: imageUrl,
          cacheManager: imageCacheManager,
          fit: fit,
          width: width,
          height: height,
          memCacheWidth: cacheWidth,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: placeholder,
          errorWidget: errorWidget,
        );
      },
    );
  }
}
