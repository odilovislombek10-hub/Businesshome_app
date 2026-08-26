import '../../core/i18n/translate.dart';

/// BU FAYL SAYT MANBASIDAN AVTOMATIK YARATILGAN — qo'lda tahrirlamang.
/// Manba: `features/create-specialist/create-specialist.component.ts` va `uz.ts`.
abstract final class CreateSpecialistTexts {
  /// `createSpecialist.addTag`
  static String get addTag => t('createSpecialist.addTag');

  /// `createSpecialist.cancel`
  static String get cancel => t('createSpecialist.cancel');

  /// `createSpecialist.city`
  static String get city => t('createSpecialist.city');

  /// `createSpecialist.description`
  static String get description => t('createSpecialist.description');

  /// `createSpecialist.descriptionPlaceholder`
  static String get descriptionPlaceholder => t('createSpecialist.descriptionPlaceholder');

  /// `createSpecialist.experience`
  static String get experience => t('createSpecialist.experience');

  /// `createSpecialist.experiencePlaceholder`
  static String get experiencePlaceholder => t('createSpecialist.experiencePlaceholder');

  /// `createSpecialist.fullName`
  static String get fullName => t('createSpecialist.fullName');

  /// `createSpecialist.fullNamePlaceholder`
  static String get fullNamePlaceholder => t('createSpecialist.fullNamePlaceholder');

  /// `createSpecialist.imagesCount`
  static String get imagesCount => t('createSpecialist.imagesCount');

  /// `createSpecialist.phone`
  static String get phone => t('createSpecialist.phone');

  /// `createSpecialist.price`
  static String get price => t('createSpecialist.price');

  /// `createSpecialist.pricePlaceholder`
  static String get pricePlaceholder => t('createSpecialist.pricePlaceholder');

  /// `createSpecialist.priceSuffix`
  static String get priceSuffix => t('createSpecialist.priceSuffix');

  /// `createSpecialist.roleLockedNote`
  static String get roleLockedNote => t('createSpecialist.roleLockedNote');

  /// `createSpecialist.sectionPersonal`
  static String get sectionPersonal => t('createSpecialist.section1');

  /// `createSpecialist.sectionPortfolio`
  static String get sectionPortfolio => t('createSpecialist.section3');

  /// `createSpecialist.sectionProfessional`
  static String get sectionProfessional => t('createSpecialist.section2');

  /// `createSpecialist.sectionTags`
  static String get sectionTags => t('createSpecialist.section4');

  /// `createSpecialist.selectCity`
  static String get selectCity => t('createSpecialist.selectCity');

  /// `createSpecialist.specialization`
  static String get specialization => t('createSpecialist.specialization');

  /// `createSpecialist.submit`
  static String get submit => t('createSpecialist.submit');

  /// `createSpecialist.subtitle`
  static String get subtitle => t('createSpecialist.subtitle');

  /// `createSpecialist.suggestedTags`
  static String get suggestedTags => t('createSpecialist.suggestedTags');

  /// `createSpecialist.tagPlaceholder`
  static String get tagPlaceholder => t('createSpecialist.tagPlaceholder');

  /// `createSpecialist.title`
  static String get title => t('createSpecialist.pageTitle');

  /// `createSpecialist.type`
  static String get type => t('createSpecialist.type');

  /// `createSpecialist.typeDesigner`
  static String get typeDesigner => t('createSpecialist.designer');

  /// `createSpecialist.typeMaster`
  static String get typeMaster => t('createSpecialist.master');

  /// `createSpecialist.update`
  static String get update => t('createSpecialist.update');

  /// `createSpecialist.uploadHint`
  static String get uploadHint => t('createSpecialist.uploadHint');

  /// `createSpecialist.uploadTitle`
  static String get uploadTitle => t('createSpecialist.uploadTitle');

  /// `createSpecialist.years`
  static String get years => t('createSpecialist.years');

  /// Dizayner mutaxassisliklari (`designerSpecs`).
  static List<(String, String)> get designerSpecs => <(String, String)>[
    ('interior', t('createSpecialist.specInterior')),
    ('exterior', t('createSpecialist.specExterior')),
    ('landscape', t('createSpecialist.specLandscape')),
    ('architecture', t('createSpecialist.specArchitecture')),
  ];

  /// Usta mutaxassisliklari (`masterSpecs`).
  static List<(String, String)> get masterSpecs => <(String, String)>[
    ('santexnik', t('createSpecialist.specPlumber')),
    ('elektrik', t('createSpecialist.specElectrician')),
    ('boyoqchi', t('createSpecialist.specPainter')),
    ('duradgor', t('createSpecialist.specCarpenter')),
    ('plitachi', t('createSpecialist.specTiler')),
    ('payvandchi', t('createSpecialist.specWelder')),
  ];

  /// Tayyor teglar (`predefinedTagKeys`) — saytdagi tartibda.
  static List<String> get suggestedTagList => <String>[
    t('createSpecialist.tagFast'),
    t('createSpecialist.tagQuality'),
    t('createSpecialist.tagAffordable'),
    t('createSpecialist.tagExperienced'),
    t('createSpecialist.tagWarranty'),
    t('createSpecialist.tag247'),
    t('createSpecialist.tagFreeConsult'),
    t('createSpecialist.tagMobile'),
  ];
}
