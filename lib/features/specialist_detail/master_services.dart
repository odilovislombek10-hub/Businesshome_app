import 'specialist_detail_models.dart';
import 'specialist_detail_texts.dart';

/// Usta sahifasidagi narx jadvali uchun qatorlar.
///
/// Saytdagi `master-detail.component.ts` → `serviceTypes` mantig'i:
/// usta kabinetdan paket kiritgan bo'lsa shular ko'rsatiladi, aks holda
/// mutaxassisligiga qarab standart taklif chiziladi. Standart taklifning
/// narxlari ustaning `priceFrom` iga ko'paytma qo'llab hisoblanadi.
/// Mutaxassisligi ro'yxatda bo'lmasa — jadval umuman chizilmaydi.
List<ServiceRow> masterServiceRows(SpecialistDetail s) {
  if (s.servicePackages.isNotEmpty) {
    return [
      for (final p in s.servicePackages)
        ServiceRow(
          name: p.title,
          price: p.price,
          unit: '${p.deliveryDays} ${SpecialistDetailTexts.days}',
          description: p.features.join(', '),
        ),
    ];
  }

  final from = s.priceFrom;
  ServiceRow row(String name, num multiplier, String unit, String description) =>
      ServiceRow(name: name, price: from * multiplier, unit: unit, description: description);

  return switch (s.specialization) {
    'plumber' => [
      row(
        'Quvur o\'rnatish',
        1,
        SpecialistDetailTexts.unitPerService,
        'Yangi suv quvurlarini o\'rnatish',
      ),
      row(
        'Quvur ta\'mirlash',
        0.7,
        SpecialistDetailTexts.unitPerService,
        'Eski quvurlarni ta\'mirlash va almashtirish',
      ),
      row(
        'Unitaz o\'rnatish',
        1.5,
        SpecialistDetailTexts.unitPerService,
        'Yangi unitaz o\'rnatish va ulash',
      ),
      row(
        'To\'liq hammom remonti',
        5,
        SpecialistDetailTexts.unitPerProject,
        'Santexnikaning to\'liq o\'rnatilishi',
      ),
    ],
    'electrician' => [
      row(
        'Elektr kabeli tortish',
        1,
        SpecialistDetailTexts.unitPerM,
        'Yangi elektr liniyalarni o\'rnatish',
      ),
      row(
        'Rozetka o\'rnatish',
        0.5,
        SpecialistDetailTexts.unitPerPiece,
        'Rozetka va vyklyuchatellarni o\'rnatish',
      ),
      row(
        'Yoritish',
        2,
        SpecialistDetailTexts.unitPerRoom,
        'Lyustra va yoritish moslamalarini o\'rnatish',
      ),
      row(
        'To\'liq elektr o\'rnatish',
        8,
        SpecialistDetailTexts.unitPerProject,
        'Butun kvartira elektr ishlari',
      ),
    ],
    'painter' => [
      row(
        'Devor bo\'yash',
        1,
        SpecialistDetailTexts.unitPerM2,
        'Interyer bo\'yoq bilan devorlarni bo\'yash',
      ),
      row(
        'Oboy yopishtirish',
        1.2,
        SpecialistDetailTexts.unitPerM2,
        'Devorlarga oboy yopishtirish',
      ),
      row(
        'Dekorativ shtukaturka',
        2,
        SpecialistDetailTexts.unitPerM2,
        'Venetsiya shtukaturkasi va dekor',
      ),
      row(
        'To\'liq kvartira bo\'yash',
        10,
        SpecialistDetailTexts.unitPerProject,
        'Barcha xonalar bo\'yash va tayyorlash',
      ),
    ],
    'tiler' => [
      row('Pol plitkasi', 1, SpecialistDetailTexts.unitPerM2, 'Polga keramik plitka qo\'yish'),
      row(
        'Devor plitkasi',
        1.2,
        SpecialistDetailTexts.unitPerM2,
        'Devorga keramik plitka qo\'yish',
      ),
      row('Mozaika', 2, SpecialistDetailTexts.unitPerM2, 'Mozaika va nozik naqsh ishlari'),
    ],
    'carpenter' => [
      row(
        'Eshik o\'rnatish',
        1,
        SpecialistDetailTexts.unitPerPiece,
        'Ichki va tashqi eshiklarni o\'rnatish',
      ),
      row(
        'Mebel yig\'ish',
        2,
        SpecialistDetailTexts.unitPerService,
        'Tayyor mebelni yig\'ish va o\'rnatish',
      ),
      row('Parket qo\'yish', 1.5, SpecialistDetailTexts.unitPerM2, 'Parket va laminat o\'rnatish'),
    ],
    'welder' => [
      row(
        'Metall darvoza',
        1,
        SpecialistDetailTexts.unitPerPiece,
        'Metall darvoza va eshik yasash',
      ),
      row('Panjara', 0.8, SpecialistDetailTexts.unitPerM, 'Zina panjarasi va balkon panjarasi'),
      row(
        'Metall konstruksiya',
        3,
        SpecialistDetailTexts.unitPerService,
        'Maxsus metall ishlar va payvandlash',
      ),
    ],
    _ => const [],
  };
}
