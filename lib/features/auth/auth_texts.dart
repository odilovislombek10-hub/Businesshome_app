/// Kirish va ro'yxatdan o'tish matnlari — `core/i18n/translations/uz.ts` dagi `auth.*` kalitlari.
abstract final class AuthTexts {
  static const brand = 'BusinessHome';

  static const loginTitle = 'Tizimga kirish';
  static const phone = 'Telefon raqam';
  static const phoneHint = '90 123 45 67';
  static const password = 'Parol';
  static const passwordPlaceholder = 'Parolni kiriting';
  static const forgotPassword = 'Parolni unutdingizmi?';
  static const continueLabel = 'Davom etish';
  static const loggingIn = 'Kirilmoqda...';
  static const noAccount = "Hisobingiz yo'qmi?";
  static const createAccount = "Ro'yxatdan o'tish";
  static const or = 'yoki';

  static const continueWithGoogle = 'Google bilan davom etish';
  static const continueWithApple = 'Apple bilan davom etish';
  static const continueWithFacebook = 'Facebook bilan davom etish';

  static const byContinuing = "Davom etish orqali siz BusinessHome'ning";
  static const termsOfUse = 'foydalanish shartlarini';

  static const loginError = "Telefon raqam yoki parol noto'g'ri";

  /// Saytda yo'q — u tarmoq xatosini ham "parol noto'g'ri" deb ko'rsatadi. Ilovada bu chalg'itadi.
  static const connectionError = "Serverga ulanib bo'lmadi. Internetni tekshirib qayta urining.";

  static const errorPhone = "Telefon raqamni to'liq kiriting";
  static const errorPassword = 'Parolni kiriting (kamida 6 belgi)';

  // ── ro'yxatdan o'tish (5 qadamli sehrgar) ──────────────────────────────────
  static const stepOf = 'Qadam';

  /// `stepTitle()` — bosqich sarlavhalari, tartibi shablondagidek.
  static const stepTitles = <String>[
    'Hisob turi',
    'Ism va parol',
    'Hududingiz',
    'Telefon',
    'Tasdiqlash',
  ];

  /// Saytda `t('common.next')` ishlatilgan, lekin bu kalit `uz.ts` da **yo'q** — dictionary
  /// topolmagan kalitni o'zini qaytaradi, ya'ni jonli saytda tugmada "common.next →" chiqadi.
  /// Ilovada to'g'ri matn qo'yildi.
  static const next = 'Keyingisi →';
  static const back = '← Orqaga';
  static const sendCode = 'Kod yuborish';
  static const verifying = 'Tasdiqlanmoqda...';
  static const verifyAndLogin = 'Tasdiqlash va kirish';

  static const roleStepDesc = "O'zingizga mos rolni tanlang";
  static const nameStepDesc = 'Ismingiz va xavfsiz parol kiriting';
  static const regionStepDesc = 'Viloyat va tumaningizni tanlang';
  static const codeWillBeSent = 'Tasdiqlash kodi yuboriladi';
  static const verificationCode = 'Tasdiqlash kodi';

  static const fullName = "To'liq ism";
  static const fullNamePlaceholder = 'Ismingizni kiriting';
  static const passwordMinPlaceholder = 'Kamida 6 ta belgi';
  static const region = 'Viloyat';
  static const selectRegion = '— Viloyatni tanlang —';
  static const district = 'Tuman';
  static const selectDistrict = 'Tumanni tanlang';
  static const smsCodeLabel = 'SMS kodi';
  static const codePlaceholder = '000000';
  static const resend = 'Kodni qayta yuborish';
  static const resending = 'Yuborilmoqda...';
  static const resendIn = 'Qayta yuborish';
  static const sentTo = 'raqamiga SMS yuborildi';

  static const agreeWith = 'Men';
  static const termsLink = 'foydalanish shartlari';
  static const and = ' va ';
  static const privacyLink = 'maxfiylik siyosati';

  static const hasAccount = 'Hisobingiz bormi?';
  static const loginLink = 'Kirish';

  /// Rol tanlash kartalari — belgi va yorliq saytdagi `roles` massividan.
  static const roles = <(String, String, String)>[
    ('user', 'Foydalanuvchi', '👤'),
    ('agent', 'Agent', '🏢'),
    ('designer', 'Dizayner', '🎨'),
    ('master', 'Usta', '🔧'),
    ('developer', 'Quruvchi', '🏗️'),
  ];

  // Qadam tekshiruvlari — saytdagi `validateStep` matnlari.
  static const errorFullName = "Ism kamida 2 ta belgidan iborat bo'lsin";
  static const errorPasswordShort = "Parol kamida 6 ta belgi bo'lsin";
  static const errorRegion = 'Viloyatni tanlang';
  static const errorDistrict = 'Tumanni tanlang';
  static const errorPhoneDigits = "Telefon raqami 9 ta raqam bo'lsin (998 sizdan keyin)";
  static const errorTerms = 'Shartlarga rozilik bering';
  static const errorCode = '6 xonali kodni kiriting';
  static const errorPhoneTaken = "Bu raqam allaqachon ro'yxatdan o'tgan";
  static const errorSmsFailed = "SMS yuborib bo'lmadi. Qayta urining.";
  static const errorTooMany = "Juda ko'p urinish. Birozdan keyin qayta urining.";
  static const errorCodeWrong = "Kod noto'g'ri yoki muddati o'tgan";
  static const registerError = "Ro'yxatdan o'tishda xatolik yuz berdi";

  // Quruvchi (yuridik shaxs) formasi — faqat `role=developer` da ko'rinadi.
  static const companyInfo = "Kompaniya ma'lumotlari";
  static const companyName = 'Quruvchi nomi (LLC)';
  static const companyNamePlaceholder = 'OOO "Buyuk Quruvchi"';
  static const inn = 'INN';
  static const mfo = 'MFO';
  static const oked = 'OKED';
  static const vatRegCode = 'NDS reg.kod';
  static const contactPerson = "Mas'ul shaxs";
  static const contactPersonPlaceholder = 'Ism Familya';
  static const position = 'Lavozim';
  static const companyPhone = 'Telefon';
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
  static const positions = <String>['Direktor', 'Bosh direktor', 'Boshqaruvchi', "Mas'ul shaxs"];

  // ── parolni tiklash ────────────────────────────────────────────────────────
  static const resetTitle = 'Parolni tiklash';
  static const resetStepPhone = 'Telefon raqamingizni kiriting';
  static const resetStepCode = 'SMS kodini kiriting';
  static const resetStepPassword = 'Yangi parolni kiriting';
  static const sendSms = 'SMS yuborish';
  static const smsCode = 'SMS kod';
  static const smsHint = 'Telefon raqamingizga yuborilgan 6 xonali kodni kiriting';
  static const resendCode = 'Qayta yuborish';
  static const resendPrefix = 'Qayta yuborish: ';
  static const sec = 's';
  static const verifyCode = 'Tasdiqlash';
  static const newPassword = 'Yangi parol';
  static const createPasswordPlaceholder = 'Parol yarating (kamida 6 belgi)';
  static const confirmPassword = 'Parolni tasdiqlash';
  static const confirmPasswordPlaceholder = 'Parolni qayta kiriting';
  static const resetButton = "Parolni o'zgartirish";
  static const resetSuccess = "Parol muvaffaqiyatli o'zgartirildi!";
  static const resetSuccessDesc = 'Endi yangi parol bilan tizimga kirishingiz mumkin.';
  static const loginButton = 'Kirish';
  static const backToLogin = 'Kirish sahifasiga qaytish';
  static const errorSmsCode = '6 xonali tasdiqlash kodini kiriting';
  static const errorSendCode = 'Kod yuborishda xatolik';
  static const resetError = 'Parolni tiklashda xatolik yuz berdi';
  static const errorPasswordMin = "Parol kamida 6 belgidan iborat bo'lishi kerak";
  static const errorPasswordMatch = 'Parollar mos kelmaydi';

  /// Tilni tanlash tugmasi — saytda uch til bor.
  static const languages = <(String, String, String)>[
    ('uz', "O'zbekcha", '🇺🇿'),
    ('ru', 'Русский', '🇷🇺'),
    ('ky', 'Кыргызча', '🇰🇬'),
  ];
}
