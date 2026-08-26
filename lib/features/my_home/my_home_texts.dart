import '../../core/i18n/translate.dart';
import 'package:flutter/painting.dart';

/// "Mening uyim" sahifasining matnlari — `my-home.component.html` dan aynan olingan.
abstract final class MyHomeTexts {
  static String get title => t('myHome.title');
  static const subtitle = "Siz sotib olgan xonadon, shartnoma, to'lovlar va qurilish jarayoni";
  static const listTitle = 'Mening uylarim';
  static String listSubtitle(int count) =>
      "Siz sotib olgan mulklar ($count) — ko'rish uchun birini tanlang";
  static const backToList = "Mulklar ro'yxatiga qaytish";
  static String myProperties(int count) => 'Sizning mulklaringiz ($count)';
  static const open = "Ochish →";
  static String get apartment => t('header.dropdown.apartment');
  static String get shop => t('header.dropdown.shop');
  static const totalPriceShort = 'Jami narx';

  static const errorTitle = "Ma'lumotni yuklab bo'lmadi";
  static const errorText = 'Server bilan aloqada xatolik. Iltimos qayta urinib ko\'ring.';
  static String get retry => t('panorama.retry');

  static const emptyTitle = "Sizda hali aktiv xonadon yo'q";
  static const emptyText =
      "Yangi qurilayotgan uy sotib olganingizdan keyin shartnoma ma'lumotlari shu yerda "
      "avtomatik ko'rinadi. Sotuvchi siz bilan ro'yxatdan o'tgan telefon raqamiga shartnoma "
      'rasmiylashtirgach, hammasi bu yerda paydo bo\'ladi.';
  static const emptySeeProjects = "Loyihalarni ko'rish";
  static const emptyLinkManually = "Shartnomamni qo'lda bog'lash";

  // ── shartnomani bog'lash ──────────────────────────────────────────────────
  static const linkTitle = "Shartnomamni bog'lash";
  static const linkSubtitle = "Pasport ma'lumotlari orqali tizimda shartnomangizni topamiz";
  static const linkPassportSeries = 'Pasport seriya';
  static const linkPassportNumber = 'Pasport raqami';
  static String get linkOr => t('auth.or');
  static const linkPhone = 'CRM dagi telefon raqamingiz';
  static const linkPhoneHint = 'Quruvchi kompaniyasiga taqdim etgan telefon raqam';
  static const linkOneId = 'OneID orqali (tez orada)';
  static String get linkCancel => t('common.cancel');
  static const linkSubmit = "Topish va bog'lash";
  static String get linkSearching => t('map.amenity.searching');
  static const linkNotFound = "Shartnoma topilmadi. Ma'lumotlarni tekshirib qayta urining.";
  static String linkSuccess(String? number) =>
      "Shartnoma ${number ?? ''} muvaffaqiyatli bog'landi!".replaceAll('  ', ' ');

  // ── bo'limlar ─────────────────────────────────────────────────────────────
  static List<(String, String)> get tabs => <(String, String)>[
    ('overview', t('createListing.bathroomShared')),
    ('contract', 'Shartnoma'),
    ('payments', "To'lov grafigi"),
    ('construction', 'Qurilish jarayoni'),
    ('market', 'Bozor analizi'),
    ('documents', t('order.documents')),
  ];

  // Xonadon xulosasi
  static String get block => t('newProjects.blocks');
  static const entrance = "Pod'yezd";
  static String get floor => t('detail.floor');
  static const apartmentNo = 'Xonadon';
  static String get rooms => t('detail.rooms');
  static String get area => t('cabinet.projects.area');
  static const delivery = 'Topshirilish';
  static const constructionProgress = 'Qurilish progressi';
  static String get project => t('order.project');
  static String get address => t('detail.address');
  static const propertyInfo = "Xonadon ma'lumotlari";
  static const layout = 'Planirovka';
  static String get statusSection => t('common.status');
  static const contractWord = 'Shartnoma';
  static const construction = 'Qurilish';
  static const remainingSum = 'Qolgan summa';
  static const pay = "To'lash";

  // Moliya kartasi
  static const remaining = 'Qoldiq';
  static const nextPayment = "Keyingi to'lov";
  static String get soum => t('mortgage.som');
  static const bought = 'Sotib olingan';
  static const currentMarket = 'Hozirgi bozor';
  static const investmentGrowth = "Inv. o'sishi";
  static const districtGrowth = "Hudud o'sishi";
  static const priceUnchanged = "Narx o'zgarmagan";
  static const notEnoughMarket = "Bozor ma'lumotlari yetarli emas";
  static const noDistrictHistory = "Hudud bo'yicha hali tarix yo'q";
  static String lastMonths(int months) => 'oxirgi $months oy';

  // Shartnoma bo'limi
  static const contractNumber = 'Shartnoma raqami';
  static const signedAt = 'Imzolangan sana';
  static const buyer = 'Xaridor';
  static const developer = 'Developer';
  static const totalAmount = 'Umumiy summa';
  static const paymentType = "To'lov turi";
  static String get warranty => t('masterDetail.warranty');
  static String warrantyMonths(int months) => '$months oy';
  static const lateTerms = "Kechikish shartlari";
  static String get notes => t('report.reason.other');
  static const contractPdf = 'Shartnoma PDF';
  static String get view => t('designers.view');
  static String get downloading => t('common.loading');
  static const downloadFailed = "Faylni yuklab bo'lmadi";

  // To'lov grafigi
  static String get totalLabel => t('createListing.bathroomShared');
  static String paidWithPercent(int percent) => "To'langan ($percent%)";
  static const remainingLabel = 'Qolgan';
  static const nextLabel = 'Keyingi';
  static String paidMonths(int n) => "$n oy to'langan";
  static String remainingMonths(int n) => '$n oy qolgan';
  static const noPayments = "To'lov ma'lumotlari yo'q";
  static const paymentHistory = "To'lov tarixi";
  static const receipt = 'Chek';
  static const downloadReceipt = 'Chekni yuklash';

  /// `paymentStatusLabel` va rangi.
  static (String, Color, Color) paymentStatus(String status) => switch (status) {
    'paid' => ("To'langan", Color(0xFF047857), Color(0xFFECFDF5)),
    'pending' => (t('cabinet.reels.statusPending'), Color(0xFFB45309), Color(0xFFFFFBEB)),
    'overdue' => ('Kechikkan', Color(0xFFB91C1C), Color(0xFFFEF2F2)),
    _ => ('Kelgusi', Color(0xFF475569), Color(0xFFF1F5F9)),
  };

  // Qurilish
  static const overallProgress = 'Umumiy progress';
  static String fasterBy(num percent) => "+$percent% tez";
  static String slowerBy(num percent) => '$percent% kechikmoqda';
  static String updatedAt(String date) => 'Yangilangan: $date';
  static const stages = 'Bosqichlar';
  static const photoGallery = 'Foto galereyasi';
  static const aiAnalysis = 'AI tahlil';

  // Bozor
  static const yourPrice = 'Siz olgan narx';
  static const currentPrice = 'Hozirgi narx';
  static const potentialProfit = 'Potensial foyda';
  static const priceDynamics = "Narx dinamikasi (m² uchun)";
  static const similarApartments = "O'xshash xonadonlar";
  static const aiMarketInsight = 'AI Market Insight';

  // Hujjatlar
  static const noDocuments = "Hujjatlar yo'q";
  static String get download => t('order.docDownload');

  /// `docCategories` — kalit, yorliq va belgi.
  static List<(String, String, String)> get documentCategories => <(String, String, String)>[
    ('contract', 'Shartnoma', '📄'),
    ('receipts', 'Cheklar', '🧾'),
    ('cadastre', t('rent.amenity.kadastr'), '🗺️'),
    ('warranty', t('masterDetail.warranty'), '🛡️'),
    ('layout', 'Planirovka', '📐'),
    ('design', 'Dizayn', '🎨'),
    ('other', t('masters.spec.other'), '📁'),
  ];

  /// Fayl hajmi — saytdagi `fmtSize`.
  static String fileSize(int bytes) {
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  /// `dd.MM.yyyy` — saytdagi `fmtDate`.
  static String date(String? iso) {
    if (iso == null || iso.length < 10) return '—';
    final parts = iso.substring(0, 10).split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }

  static String percent(num value) => '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%';
}
