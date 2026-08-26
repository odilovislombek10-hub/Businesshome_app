import '../../core/i18n/translate.dart';

/// Kirish va ro'yxatdan o'tish matnlari — `core/i18n/translations/uz.ts` dagi `auth.*` kalitlari.
abstract final class AuthTexts {
  static const brand = 'BusinessHome';

  static String get loginTitle => t('auth.loginTitle');
  static String get phone => t('auth.phone');
  static const phoneHint = '90 123 45 67';
  static String get password => t('auth.password');
  static String get passwordPlaceholder => t('auth.passwordPlaceholder');
  static String get forgotPassword => t('auth.forgotPassword');
  static String get continueLabel => t('auth.continue');
  static String get loggingIn => t('auth.loggingIn');
  static String get noAccount => t('auth.noAccount');
  static String get createAccount => t('auth.registerTitle');
  static String get or => t('auth.or');

  static String get continueWithGoogle => t('auth.continueWithGoogle');
  static String get continueWithApple => t('auth.continueWithApple');
  static String get continueWithFacebook => t('auth.continueWithFacebook');

  static String get byContinuing => t('auth.byContinuing');
  static String get termsOfUse => t('auth.termsOfUse');

  static String get loginError => t('auth.loginError');

  /// Saytda yo'q — u tarmoq xatosini ham "parol noto'g'ri" deb ko'rsatadi. Ilovada bu chalg'itadi.
  static const connectionError = "Serverga ulanib bo'lmadi. Internetni tekshirib qayta urining.";

  static String get errorPhone => t('auth.errorPhone');
  static String get errorPassword => t('auth.errorPassword');

  // ── ro'yxatdan o'tish (5 qadamli sehrgar) ──────────────────────────────────
  static const stepOf = 'Qadam';

  /// `stepTitle()` — bosqich sarlavhalari, tartibi shablondagidek.
  static List<String> get stepTitles => <String>[
    t('auth.accountType'),
    'Ism va parol',
    'Hududingiz',
    t('cabinet.phone'),
    t('auth.verifyCode'),
  ];

  /// Saytda `t('common.next')` ishlatilgan, lekin bu kalit `uz.ts` da **yo'q** — dictionary
  /// topolmagan kalitni o'zini qaytaradi, ya'ni jonli saytda tugmada "common.next →" chiqadi.
  /// Ilovada to'g'ri matn qo'yildi.
  static const next = 'Keyingisi →';
  static const back = '← Orqaga';
  static String get sendCode => t('auth.sendCode');
  static String get verifying => t('auth.verifying');
  static String get verifyAndLogin => t('auth.verifyAndLogin');

  static const roleStepDesc = "O'zingizga mos rolni tanlang";
  static const nameStepDesc = 'Ismingiz va xavfsiz parol kiriting';
  static const regionStepDesc = 'Viloyat va tumaningizni tanlang';
  static String get codeWillBeSent => t('auth.codeWillBeSent');
  static String get verificationCode => t('auth.verificationCode');

  static String get fullName => t('auth.fullName');
  static String get fullNamePlaceholder => t('auth.fullNamePlaceholder');
  static const passwordMinPlaceholder = 'Kamida 6 ta belgi';
  static String get region => t('auth.region');
  static const selectRegion = '— Viloyatni tanlang —';
  static String get district => t('auth.district');
  static String get selectDistrict => t('auth.selectDistrict');
  static const smsCodeLabel = 'SMS kodi';
  static const codePlaceholder = '000000';
  static const resend = 'Kodni qayta yuborish';
  static String get resending => t('birja.submitting');
  static String get resendIn => t('auth.resendCode');
  static const sentTo = 'raqamiga SMS yuborildi';

  static String get agreeWith => t('auth.agreeWith');
  static String get termsLink => t('auth.termsLink');
  static String get and => t('auth.and');
  static String get privacyLink => t('auth.privacyLink');

  static String get hasAccount => t('auth.hasAccount');
  static String get loginLink => t('auth.loginButton');

  /// Rol tanlash kartalari — belgi va yorliq saytdagi `roles` massividan.
  static List<(String, String, String)> get roles => <(String, String, String)>[
    ('user', t('auth.roleUser'), '👤'),
    ('agent', t('auth.roleAgent'), '🏢'),
    ('designer', t('auth.roleDesigner'), '🎨'),
    ('master', t('auth.roleMaster'), '🔧'),
    ('developer', t('auth.roleDeveloper'), '🏗️'),
  ];

  // Qadam tekshiruvlari — saytdagi `validateStep` matnlari.
  static const errorFullName = "Ism kamida 2 ta belgidan iborat bo'lsin";
  static const errorPasswordShort = "Parol kamida 6 ta belgi bo'lsin";
  static String get errorRegion => t('auth.selectRegion');
  static String get errorDistrict => t('auth.selectDistrict');
  static const errorPhoneDigits = "Telefon raqami 9 ta raqam bo'lsin (998 sizdan keyin)";
  static const errorTerms = 'Shartlarga rozilik bering';
  static const errorCode = '6 xonali kodni kiriting';
  static const errorPhoneTaken = "Bu raqam allaqachon ro'yxatdan o'tgan";
  static const errorSmsFailed = "SMS yuborib bo'lmadi. Qayta urining.";
  static const errorTooMany = "Juda ko'p urinish. Birozdan keyin qayta urining.";
  static const errorCodeWrong = "Kod noto'g'ri yoki muddati o'tgan";
  static String get registerError => t('auth.registerError');

  // Quruvchi (yuridik shaxs) formasi — faqat `role=developer` da ko'rinadi.
  static const companyInfo = "Kompaniya ma'lumotlari";
  static const companyName = 'Quruvchi nomi (LLC)';
  static const companyNamePlaceholder = 'OOO "Buyuk Quruvchi"';
  static String get inn => t('detail.inn');
  static const mfo = 'MFO';
  static const oked = 'OKED';
  static const vatRegCode = 'NDS reg.kod';
  static const contactPerson = "Mas'ul shaxs";
  static const contactPersonPlaceholder = 'Ism Familya';
  static const position = 'Lavozim';
  static String get companyPhone => t('cabinet.phone');
  static const email = 'Email';
  static const legalAddress = 'Yuridik manzil';
  static const legalAddressPlaceholder = 'Kompaniya yuridik manzili';
  static const companyLogo = 'Quruvchi logotipi';
  static const uploadLogo = 'Logo yuklash';
  static const adminApprovalTitle = "Admin tasdig'idan keyin hisob faollashadi";
  static const adminApprovalDesc =
      "Kiritgan ma'lumotlaringizni admin tekshiradi va siz bilan bog'lanib hisob yaratishga "
      'ruxsat beradi.';
  static const errorCompanyName = 'Kompaniya nomini kiriting';
  static const errorContactPerson = "Mas'ul shaxsni kiriting";
  static List<String> get positions => <String>[
    t('detail.director'),
    'Bosh direktor',
    'Boshqaruvchi',
    "Mas'ul shaxs",
  ];

  // ── parolni tiklash ────────────────────────────────────────────────────────
  static String get resetTitle => t('auth.resetTitle');
  static String get resetStepPhone => t('auth.resetStepPhone');
  static String get resetStepCode => t('auth.resetStepCode');
  static String get resetStepPassword => t('auth.resetStepPassword');
  static String get sendSms => t('auth.sendSms');
  static String get smsCode => t('auth.smsCode');
  static String get smsHint => t('auth.smsHint');
  static String get resendCode => t('auth.resendCode');
  static String get resendPrefix => t('auth.resendIn');
  static String get sec => t('auth.sec');
  static String get verifyCode => t('auth.verifyCode');
  static String get newPassword => t('auth.newPassword');
  static String get createPasswordPlaceholder => t('auth.createPasswordPlaceholder');
  static String get confirmPassword => t('auth.confirmPassword');
  static String get confirmPasswordPlaceholder => t('auth.confirmPasswordPlaceholder');
  static String get resetButton => t('auth.resetButton');
  static String get resetSuccess => t('auth.resetSuccess');
  static String get resetSuccessDesc => t('auth.resetSuccessDesc');
  static String get loginButton => t('auth.loginButton');
  static String get backToLogin => t('auth.backToLogin');
  static String get errorSmsCode => t('auth.errorSmsCode');
  static String get errorSendCode => t('auth.errorSendCode');
  static String get resetError => t('auth.resetError');
  static String get errorPasswordMin => t('auth.errorPasswordMin');
  static String get errorPasswordMatch => t('auth.errorPasswordMatch');

  /// Tilni tanlash tugmasi — saytda uch til bor.
  static List<(String, String, String)> get languages => <(String, String, String)>[
    ('uz', "O'zbekcha", '🇺🇿'),
    ('ru', 'Русский', '🇷🇺'),
    ('ky', 'Кыргызча', '🇰🇬'),
  ];
}
