import '../../core/i18n/translate.dart';

/// `uz.ts` dagi `rentDetail.*` va u bilan ishlatiladigan `detail.*` kalitlari.
abstract final class RentDetailTexts {
  static String get forRent => t('rent.forRent');
  static String get monthlyRent => t('rentDetail.monthlyRent');
  static String get somMonth => t('rentDetail.somMonth');
  static String get yearlyTotal => t('rentDetail.yearlyTotal');
  static String get rentalTerms => t('rentDetail.rentalTerms');

  static String get deposit => t('rentDetail.deposit');
  static String get depositHint => t('rentDetail.depositHint');
  static String get minLease => t('rentDetail.minLease');
  static String get minLeaseValue => t('rentDetail.minLeaseValue');
  static String get longTermDiscount => t('rentDetail.longTermDiscount');
  static String get utilities => t('rentDetail.utilities');
  static String get utilitiesNotIncluded => t('rentDetail.utilitiesNotIncluded');
  static String get moveIn => t('rentDetail.moveIn');
  static String get availableNow => t('rentDetail.availableNow');
  static String get moveInHint => t('rentDetail.moveInHint');
  static String get petPolicy => t('rentDetail.petPolicy');
  static String get petsNegotiable => t('rentDetail.petsNegotiable');
  static String get petDiscuss => t('rentDetail.petDiscuss');
  static String get furnishing => t('rentDetail.furnishing');
  static String get furnished => t('rentDetail.furnishing');
  static String get unfurnished => t('rentDetail.unfurnished');
  static String get furnishingHint => t('rentDetail.furnishingHint');
  static String get totalMoveIn => t('rentDetail.totalMoveIn');
  static String get firstMonth => t('rentDetail.firstMonth');
  static String get similarRentals => t('rentDetail.similarRentals');

  /// Saytda kommunal izohi qattiq yozilgan.
  static const utilitiesHint = "~300,000-500,000 so'm/oy";

  // `detail.*` va `breadcrumb.*`
  static String get breadcrumbHome => t('rent.home');
  static String get breadcrumbRent => t('rent.pageTitle');
  static String get about => t('detail.aboutTitle');
  static String get rooms => t('detail.rooms');
  static String get floor => t('detail.floor');
  static String get roomShort => t('detail.roomShort');
  static String get virtualTour => t('detail.virtualTour');
  static String get withBalcony => t('detail.withBalcony');
  static String get som => t('detail.som');
  static String get notFound => t('detail.notFound');
  static String get notFoundDesc => t('detail.notFoundDesc');
  static String get backToList => t('detail.backToList');
  static const amenities = 'Qulayliklar';
  static String get location => t('map.locationTitle');
}
