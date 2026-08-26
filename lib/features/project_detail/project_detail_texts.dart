import '../../core/i18n/translate.dart';

/// `uz.ts` dagi loyiha sahifasi matnlari — qiymatlar aynan ko'chirilgan.
abstract final class ProjectDetailTexts {
  static String get back => t('detail.back');
  static String get photos => t('detail.photos');
  static String get brochure => t('detail.brochure');
  static String get selectApartment => t('detail.selectApartment');

  static String get highlightsTitle => t('highlights.title');

  static String get viewer3dView => t('viewer3d.view');
  static String get viewer3dReady => t('viewer3d.ready');
  static String get viewer3dPreloading => t('viewer3d.preloading');

  static String get smartTitle => t('smart.title');
  static String get smartDetails => t('highlights.details');
  static String get smartMainDesc => t('smart.mainDesc');

  static String get docsTitle => t('docs.title');
  static String get docsDocument => t('docs.document');

  static String get notFound => t('detail.notFoundTitle');
  static String get backHome => t('detail.backToHome');

  // `present.*` — prezentatsiya rejimi (`?present=1`)
  static String get presentLabel => t('present.label');
  static String get presentPause => t('present.pause');
  static String get presentResume => t('present.resume');
  static String get presentView3d => t('present.view3d');
  static String get presentExit => t('present.exit');

  /// Hero'dagi belgilar — saytda ham shu qo'shimchalar bilan yoziladi.
  static String get blocks => t('detail.unitBlock');
  static String get apartments => t('detail.unitApartment');
  static String get year => t('detail.year');
}
