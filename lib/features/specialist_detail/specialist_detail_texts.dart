import '../../core/i18n/translate.dart';

/// `uz.ts` dagi `designerDetail.*` va `masterDetail.*` kalitlari.
abstract final class SpecialistDetailTexts {
  // umumiy
  static String get breadcrumbHome => t('cabinet.tab.dashboard');
  static String get som => t('hero.currency');
  static const notFound = 'Mutaxassis topilmadi';
  static String get backToList => t('detail.backToList');
  static String get clientReviews => t('designerDetail.clientReviews');
  static String get hireMe => t('designerDetail.hireMe');
  static String get call => t('cabinet.call');

  // dizayner
  static String get breadcrumbDesigners => t('home.sector.designers.title');
  static String get reviews => t('designerDetail.reviews');
  static String get projects => t('designerDetail.projects');
  static String get years => t('designerDetail.years');
  static String get completedProjects => t('designerDetail.completedProjects');
  static String get yearsExperience => t('designerDetail.yearsExperience');
  static String get avgRating => t('designerDetail.avgRating');
  static String get responseRate => t('designerDetail.responseRate');
  static String get responseTime => t('designerDetail.responseTime');
  static String get hour => t('designerDetail.hour');
  static String get availability => t('designerDetail.availability');
  static String get available => t('designerDetail.available');
  static String get busy => t('designerDetail.busy');
  static String get portfolio => t('designerDetail.portfolio');
  static String get projectsCount => t('designerDetail.projectsCount');
  static String get aboutMe => t('designerDetail.aboutMe');
  static String get specializations => t('designerDetail.specializations');
  static String get servicePackages => t('designerDetail.servicePackages');
  static String get packagesHint => t('designerDetail.packagesHint');
  static String get noPackages => t('designerDetail.noPackages');
  static String get popular => t('designerDetail.popular');
  static String get days => t('designerDetail.days');
  static String get selectPackage => t('designerDetail.selectPackage');
  static String get priceStartsFrom => t('designerDetail.priceStartsFrom');

  // usta
  static String get breadcrumbMasters => t('header.nav.masters');
  static String get jobs => t('masterDetail.jobs');
  static String get completedJobs => t('masterDetail.completedJobs');
  static String get emergency => t('masterDetail.emergency');
  static String get completedWork => t('masterDetail.completedWork');
  static String get photosCount => t('masterDetail.photosCount');
  static String get aboutMaster => t('masterDetail.aboutMaster');
  static String get skills => t('masterDetail.skills');
  static String get priceList => t('masterDetail.priceList');
  static String get priceListHint => t('masterDetail.priceListHint');
  static String get serviceArea => t('masterDetail.serviceArea');
  static String get startingFrom => t('designerDetail.priceStartsFrom');
  static String get somPerService => t('masterDetail.somPerService');
  static String get emergencyCall => t('masterDetail.emergencyCall');
  static String get emergencyHint => t('masterDetail.emergencyHint');
  static String get arrivalTime => t('masterDetail.arrivalTime');
  static String get minute => t('masterDetail.minute');
  static String get warranty => t('masterDetail.warranty');
  static String get months => t('masterDetail.months');
  static String get serviceRadius => t('masterDetail.serviceRadius');
  static String get availableToday => t('masterDetail.availableToday');
  static String get callNow => t('masterDetail.callNow');

  // `masterDetail.unit.*`
  static String get unitPerService => t('masterDetail.unit.perService');
  static String get unitPerProject => t('masterDetail.unit.perProject');
  static String get unitPerM => t('masterDetail.unit.perM');
  static const unitPerM2 = '1 m\u00b2';
  static String get unitPerPiece => t('masterDetail.unit.perPiece');
  static String get unitPerRoom => t('masterDetail.unit.perRoom');

  /// Saytda ham qattiq yozilgan — har bir usta uchun bir xil ro'yxat
  /// (`master-detail.component.ts` dagi `serviceAreas`).
  static const serviceAreas = [
    'Yunusobod',
    "Mirzo Ulug'bek",
    'Chilonzor',
    'Yakkasaroy',
    'Shayxontohur',
    'Sergeli',
    'Mirobod',
    'Olmazor',
  ];

  /// `designers.spec.*` — dizayner mutaxassisligi.
  static String designerSpec(String code) => switch (code) {
    'interior' => t('designers.specInterior'),
    'exterior' => t('designers.specExterior'),
    'landscape' => t('designers.specLandscape'),
    'architecture' => t('designers.specArchitecture'),
    _ => code,
  };
}
