import 'package:flutter/painting.dart';

/// "Mening uyim" sahifasining matnlari — `my-home.component.html` dan aynan olingan.
abstract final class MyHomeTexts {
  static const title = 'Mening uyim';
  static const subtitle = "Siz sotib olgan xonadon, shartnoma, to'lovlar va qurilish jarayoni";
  static const listTitle = 'Mening uylarim';
  static String listSubtitle(int count) =>
      "Siz sotib olgan mulklar ($count) — ko'rish uchun birini tanlang";
  static const backToList = "Mulklar ro'yxatiga qaytish";
  static String myProperties(int count) => 'Sizning mulklaringiz ($count)';
  static const open = "Ochish →";
  static const apartment = 'Kvartira';
  static const shop = "Do'kon";
  static const totalPriceShort = 'Jami narx';

  static const errorTitle = "Ma'lumotni yuklab bo'lmadi";
  static const errorText = 'Server bilan aloqada xatolik. Iltimos qayta urinib ko\'ring.';
  static const retry = 'Qayta urinish';

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
  static const linkOr = 'yoki';
  static const linkPhone = 'CRM dagi telefon raqamingiz';
  static const linkPhoneHint = 'Quruvchi kompaniyasiga taqdim etgan telefon raqam';
  static const linkOneId = 'OneID orqali (tez orada)';
  static const linkCancel = 'Bekor qilish';
  static const linkSubmit = "Topish va bog'lash";
  static const linkSearching = 'Qidirilmoqda...';
  static const linkNotFound = "Shartnoma topilmadi. Ma'lumotlarni tekshirib qayta urining.";
  static String linkSuccess(String? number) =>
      "Shartnoma ${number ?? ''} muvaffaqiyatli bog'landi!".replaceAll('  ', ' ');

  // ── bo'limlar ─────────────────────────────────────────────────────────────
  static const tabs = <(String, String)>[
    ('overview', 'Umumiy'),
    ('contract', 'Shartnoma'),
    ('payments', "To'lov grafigi"),
    ('construction', 'Qurilish jarayoni'),
    ('market', 'Bozor analizi'),
    ('documents', 'Hujjatlar'),
  ];

  // Xonadon xulosasi
  static const block = 'Blok';
  static const entrance = "Pod'yezd";
  static const floor = 'Qavat';
  static const apartmentNo = 'Xonadon';
  static const rooms = 'Xonalar';
  static const area = 'Maydon';
  static const delivery = 'Topshirilish';
  static const constructionProgress = 'Qurilish progressi';
  static const project = 'Loyiha';
  static const address = 'Manzil';
  static const propertyInfo = "Xonadon ma'lumotlari";
  static const layout = 'Planirovka';
  static const statusSection = 'Holat';
  static const contractWord = 'Shartnoma';
  static const construction = 'Qurilish';
  static const remainingSum = 'Qolgan summa';
  static const pay = "To'lash";

  // Moliya kartasi
  static const remaining = 'Qoldiq';
  static const nextPayment = "Keyingi to'lov";
  static const soum = "so'm";
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
  static const warranty = 'Kafolat';
  static String warrantyMonths(int months) => '$months oy';
  static const lateTerms = "Kechikish shartlari";
  static const notes = "Qo'shimcha";
  static const contractPdf = 'Shartnoma PDF';
  static const view = "Ko'rish";
  static const downloading = 'Yuklanmoqda...';
  static const downloadFailed = "Faylni yuklab bo'lmadi";

  // To'lov grafigi
  static const totalLabel = 'Umumiy';
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
    'pending' => ('Kutilmoqda', Color(0xFFB45309), Color(0xFFFFFBEB)),
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
  static const download = 'Yuklab olish';

  /// `docCategories` — kalit, yorliq va belgi.
  static const documentCategories = <(String, String, String)>[
    ('contract', 'Shartnoma', '📄'),
    ('receipts', 'Cheklar', '🧾'),
    ('cadastre', 'Kadastr', '🗺️'),
    ('warranty', 'Kafolat', '🛡️'),
    ('layout', 'Planirovka', '📐'),
    ('design', 'Dizayn', '🎨'),
    ('other', 'Boshqa', '📁'),
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
