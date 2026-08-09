import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'entrance.dart';
import 'property_card.dart';

/// Yuklanish paytida joyni egallab turadigan bo'sh shakl.
///
/// Ma'lumot kelmaguncha bo'limni **yashirib qo'yish** sahifani sakratadi: quyidagi bo'limlar
/// yuqoriga chiqib ketadi, javob kelgach hammasi joyidan siljiydi. O'lchamlar oldindan
/// ma'lum bo'lgani uchun har bir bo'lim o'z joyini va shaklini yuklanguncha ham saqlaydi.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height = 14, this.radius = 8});

  /// `null` — bor kenglikni egallaydi.
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.dark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Bo'lim sarlavhasi: qalin qator + ostida ingichkasi.
class SkeletonHeading extends StatelessWidget {
  const SkeletonHeading({super.key, this.width = 200, this.withSubtitle = true});

  final double width;
  final bool withSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton(width: width, height: 22),
        if (withSubtitle) ...[const SizedBox(height: 8), Skeleton(width: width * 1.3, height: 12)],
      ],
    );
  }
}

/// E'lon kartasining shakli — haqiqiy [PropertyCard] bilan bir xil nisbatda.
class PropertyCardSkeleton extends StatelessWidget {
  const PropertyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.dark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Skeleton(width: 60, height: 10, radius: 999),
            const Spacer(),
            const Skeleton(height: 12),
            const SizedBox(height: 6),
            Skeleton(width: 90, height: 10),
            const SizedBox(height: 10),
            const Skeleton(height: 28, radius: 12),
          ],
        ),
      ),
    );
  }
}

/// Ikki ustunli e'lon kartalari to'ri — sarlavhasi bilan.
///
/// Bosh sahifadagi "Tanlangan binolar" va shunga o'xshash bloklar shu shaklda.
class SkeletonCardGrid extends StatelessWidget {
  const SkeletonCardGrid({
    super.key,
    this.count = 4,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 24),
    this.headingWidth = 200,
  });

  final int count;
  final EdgeInsets padding;
  final double headingWidth;

  @override
  Widget build(BuildContext context) {
    return Pulse(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonHeading(width: headingWidth),
            const SizedBox(height: 16),
            GridView.count(
              // Ichma-ich GridView atrofdagi paddingni meros qiladi.
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: PropertyCard.compactAspectRatio,
              children: [for (var i = 0; i < count; i++) const PropertyCardSkeleton()],
            ),
          ],
        ),
      ),
    );
  }
}

/// Gorizontal suriladigan blok (quruvchilar, reels) — sarlavha + bir qator karta.
class SkeletonRowSection extends StatelessWidget {
  const SkeletonRowSection({
    super.key,
    required this.itemWidth,
    required this.itemHeight,
    this.count = 3,
    this.padding = const EdgeInsets.symmetric(vertical: 40),
    this.headingWidth = 220,
  });

  final double itemWidth;
  final double itemHeight;
  final int count;
  final EdgeInsets padding;
  final double headingWidth;

  @override
  Widget build(BuildContext context) {
    return Pulse(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SkeletonHeading(width: headingWidth),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: itemHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: count,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (_, _) =>
                    Skeleton(width: itemWidth, height: itemHeight, radius: AppRadius.lg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Butun bo'lim o'rniga turadigan bitta to'rtburchak (banner, statistika chizig'i).
class SkeletonBand extends StatelessWidget {
  const SkeletonBand({
    super.key,
    required this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    this.radius = AppRadius.lg,
  });

  final double height;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Pulse(
      child: Padding(
        padding: padding,
        child: Skeleton(height: height, radius: radius),
      ),
    );
  }
}
