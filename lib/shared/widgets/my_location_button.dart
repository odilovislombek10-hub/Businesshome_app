import '../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/theme.dart';
import 'entrance.dart';
import 'site_icon.dart';

/// `my-location-button.component.ts` — "Mening joylashuvim".
///
/// Saytda brauzerning `navigator.geolocation` i so'raladi; ilovada `geolocator`
/// bir vaqtning o'zida ruxsatni ham, koordinatani ham beradi. Xato matnlari
/// saytdagi to'rt holatdan aynan olingan; xabar tugma tagida chiqib, 4 soniyada
/// yo'qoladi (`showError` da `setTimeout(..., 4000)`).
class MyLocationButton extends StatefulWidget {
  const MyLocationButton({super.key, required this.onLocated, this.showLabel = false});

  final void Function(double lat, double lng) onLocated;

  /// `@Input() showLabel` — faqat ikonka yoki matn bilan.
  final bool showLabel;

  @override
  State<MyLocationButton> createState() => _MyLocationButtonState();
}

class _MyLocationButtonState extends State<MyLocationButton> {
  bool _loading = false;
  String? _error;

  Future<void> _locate() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showError('Joylashuv aniqlanmadi');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showError('Joylashuv ruxsati berilmadi');
        return;
      }
      // Saytdagi `{ enableHighAccuracy: true, timeout: 10000 }`.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onLocated(position.latitude, position.longitude);
    } catch (_) {
      _showError('Vaqt tugadi, qayta urining');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = message;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _error == message) setState(() => _error = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topRight,
      children: [
        Pressable(
          onTap: _loading ? null : _locate,
          scale: 0.95,
          child: Opacity(
            opacity: _loading ? 0.5 : 1,
            child: Container(
              height: 40,
              width: widget.showLabel ? null : 40,
              padding: widget.showLabel
                  ? const EdgeInsets.symmetric(horizontal: 12)
                  : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
                border: Border.all(color: AppColors.borderLight),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000), // shadow-lg
                    blurRadius: 15,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_loading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.dark,
                        backgroundColor: AppColors.dark.withValues(alpha: 0.25),
                      ),
                    )
                  else
                    SiteIcon(SiteIcons.crosshair, size: 20, color: AppColors.dark),
                  if (widget.showLabel) ...[
                    const SizedBox(width: 8), // ml-2
                    Text(
                      t('map.myLocation'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (_error case final message?)
          Positioned(
            top: 48, // top-full mt-2
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2), // rose-50
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: const Color(0xFFFECDD3)), // rose-200
              ),
              child: Text(
                message,
                maxLines: 1,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: const Color(0xFFBE123C), // rose-700
                ),
              ),
            ),
          ),
      ],
    );
  }
}
