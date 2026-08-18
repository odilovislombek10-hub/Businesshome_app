/// `uz.ts` dagi `news.*` kalitlari — aynan o'sha qiymatlar.
abstract final class NewsTexts {
  static const title = 'Yangiliklar';
  static const heroDesc = "Ko'chmas mulk bozori va loyihalar haqida so'nggi yangiliklar";
  static const totalCount = 'ta yangilik';
  static const loading = 'Yangiliklar yuklanmoqda...';
  static const empty = 'Yangiliklar hozircha mavjud emas';
  static const emptyDesc = "Tez orada yangi ma'lumotlar paydo bo'ladi";
  static const backHome = 'Bosh sahifaga qaytish';
  static const backToNews = 'Yangiliklarга qaytish';
  static const featured = 'Tanlangan';
  static const readMore = "Batafsil o'qish";
  static const notFound = 'Yangilik topilmadi';
  static const notFoundDesc = 'Bu yangilik mavjud emas yoki olib tashlangan';
  static const linkedProject = "Bog'langan loyiha";

  /// Bog'langan loyiha kartasidagi xonadonlar soni.
  static String apartments(int count) => '$count xonadon';
}
