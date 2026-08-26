import '../../core/i18n/translate.dart';

/// `uz.ts` dagi `news.*` kalitlari — aynan o'sha qiymatlar.
abstract final class NewsTexts {
  static String get title => t('news.title');
  static String get heroDesc => t('news.heroDesc');
  static String get totalCount => t('news.totalCount');
  static String get loading => t('news.loading');
  static String get empty => t('news.empty');
  static String get emptyDesc => t('news.emptyDesc');
  static String get backHome => t('news.backHome');
  static String get backToNews => t('news.backToNews');
  static String get featured => t('news.featured');
  static String get readMore => t('news.readMore');
  static String get notFound => t('news.notFound');
  static String get notFoundDesc => t('news.notFoundDesc');
  static String get linkedProject => t('news.linkedProject');

  /// Bog'langan loyiha kartasidagi xonadonlar soni.
  static String apartments(int count) => '$count xonadon';
}
