/// BU FAYL SAYT MANBASIDAN AVTOMATIK YARATILGAN — qo'lda tahrirlamang.
/// Manba: `features/create-specialist/create-specialist.component.ts` va `uz.ts`.
abstract final class CreateSpecialistTexts {
  /// `createSpecialist.addTag`
  static const addTag = "Teg qo'shish";

  /// `createSpecialist.cancel`
  static const cancel = 'Bekor qilish';

  /// `createSpecialist.city`
  static const city = 'Shahar';

  /// `createSpecialist.description`
  static const description = "O'zingiz haqingizda";

  /// `createSpecialist.descriptionPlaceholder`
  static const descriptionPlaceholder = 'Tajribangiz va xizmatlaringiz haqida yozing';

  /// `createSpecialist.experience`
  static const experience = 'Tajriba (yil)';

  /// `createSpecialist.experiencePlaceholder`
  static const experiencePlaceholder = 'Tajribangizni kiriting';

  /// `createSpecialist.fullName`
  static const fullName = "To'liq ism";

  /// `createSpecialist.fullNamePlaceholder`
  static const fullNamePlaceholder = 'Ismingizni kiriting';

  /// `createSpecialist.imagesCount`
  static const imagesCount = 'ta rasm yuklangan';

  /// `createSpecialist.phone`
  static const phone = 'Telefon raqam';

  /// `createSpecialist.price`
  static const price = 'Narx';

  /// `createSpecialist.pricePlaceholder`
  static const pricePlaceholder = 'Narxni kiriting';

  /// `createSpecialist.priceSuffix`
  static const priceSuffix = "so'm dan";

  /// `createSpecialist.roleLockedNote`
  static const roleLockedNote = 'Sizning rolingiz allaqachon belgilangan';

  /// `createSpecialist.sectionPersonal`
  static const sectionPersonal = "Shaxsiy ma'lumotlar";

  /// `createSpecialist.sectionPortfolio`
  static const sectionPortfolio = 'Portfolio';

  /// `createSpecialist.sectionProfessional`
  static const sectionProfessional = "Kasbiy ma'lumotlar";

  /// `createSpecialist.sectionTags`
  static const sectionTags = 'Teglar';

  /// `createSpecialist.selectCity`
  static const selectCity = 'Shaharni tanlang';

  /// `createSpecialist.specialization`
  static const specialization = 'Mutaxassislik';

  /// `createSpecialist.submit`
  static const submit = "E'lon joylash";

  /// `createSpecialist.subtitle`
  static const subtitle = 'Kasbiy profilingizni yarating va mijozlarni toping';

  /// `createSpecialist.suggestedTags`
  static const suggestedTags = 'Tavsiya etiladigan teglar';

  /// `createSpecialist.tagPlaceholder`
  static const tagPlaceholder = 'Teg kiriting';

  /// `createSpecialist.title`
  static const title = "Mutaxassis sifatida ro'yxatdan o'tish";

  /// `createSpecialist.type`
  static const type = 'Mutaxassislik turi';

  /// `createSpecialist.typeDesigner`
  static const typeDesigner = 'Dizayner';

  /// `createSpecialist.typeMaster`
  static const typeMaster = 'Usta';

  /// `createSpecialist.update`
  static const update = 'Saqlash';

  /// `createSpecialist.uploadHint`
  static const uploadHint = 'JPG, PNG formatda, max 5MB';

  /// `createSpecialist.uploadTitle`
  static const uploadTitle = 'Portfolio rasmlarini yuklang';

  /// `createSpecialist.years`
  static const years = 'yil';

  /// Dizayner mutaxassisliklari (`designerSpecs`).
  static const designerSpecs = <(String, String)>[
    ('interior', 'Interer dizayn'),
    ('exterior', 'Eksterer dizayn'),
    ('landscape', 'Landshaft'),
    ('architecture', 'Arxitektura'),
  ];

  /// Usta mutaxassisliklari (`masterSpecs`).
  static const masterSpecs = <(String, String)>[
    ('santexnik', 'Santexnik'),
    ('elektrik', 'Elektrik'),
    ('boyoqchi', "Bo'yoqchi"),
    ('duradgor', 'Duradgor'),
    ('plitachi', 'Plitachi'),
    ('payvandchi', 'Payvandchi'),
  ];

  /// Tayyor teglar (`predefinedTagKeys`) — saytdagi tartibda.
  static const suggestedTagList = <String>[
    'Tez ishlash',
    'Sifatli',
    'Arzon',
    'Tajribali',
    'Kafolat',
    '24/7',
    'Bepul konsultatsiya',
    'Chiqib borish',
  ];
}
