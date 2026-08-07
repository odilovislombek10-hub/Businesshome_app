import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/models/region.dart';
import '../../core/services/regions_service.dart';
import '../../features/home/components/site_footer.dart';

/// Saytning `<app-footer />` i — **har bir sahifa** shablonining oxirida turadi
/// (`/secondary`, `/rent`, `/designers`, `/masters`, `/birja`, bosh sahifa …).
///
/// [SiteFooter] ga viloyatlar ro'yxati va aloqa telefoni kerak; bosh sahifada ular sahifaning
/// o'z so'rovidan keladi. Boshqa sahifalar uchun shu qobiq ularni o'zi yuklaydi — ikkalasi ham
/// kesh'langan/arzon so'rov, va yiqilsa footer shunchaki telefonsiz chiziladi.
class SiteFooterSection extends StatefulWidget {
  const SiteFooterSection({super.key});

  @override
  State<SiteFooterSection> createState() => _SiteFooterSectionState();
}

class _SiteFooterSectionState extends State<SiteFooterSection> {
  List<Region> _regions = const [];
  String? _phone;

  @override
  void initState() {
    super.initState();
    RegionsService.instance.regions().then((regions) {
      if (mounted) setState(() => _regions = regions);
    });
    _loadPhone();
  }

  Future<void> _loadPhone() async {
    try {
      final res = await ApiClient.instance.get<dynamic>('/market/content/settings');
      final data = res.data;
      final phone = data is Map ? data['contact_phone']?.toString() : null;
      if (mounted && phone != null && phone.isNotEmpty) setState(() => _phone = phone);
    } catch (_) {
      // Telefonsiz footer ham to'g'ri chiziladi.
    }
  }

  @override
  Widget build(BuildContext context) => SiteFooter(regions: _regions, contactPhone: _phone);
}
