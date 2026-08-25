/// `uz.ts` dagi `designerDetail.*` va `masterDetail.*` kalitlari.
abstract final class SpecialistDetailTexts {
  // umumiy
  static const breadcrumbHome = 'Bosh sahifa';
  static const som = "so'm";
  static const notFound = 'Mutaxassis topilmadi';
  static const backToList = "Ro'yxatga qaytish";
  static const clientReviews = 'Mijozlar sharhlari';
  static const hireMe = 'Yollash';
  static const call = "Qo'ng'iroq";

  // dizayner
  static const breadcrumbDesigners = 'Dizaynerlar';
  static const reviews = 'sharhlar';
  static const projects = 'loyiha';
  static const years = 'yil tajriba';
  static const completedProjects = 'Tugatilgan loyihalar';
  static const yearsExperience = 'Tajriba yillari';
  static const avgRating = "O'rtacha reyting";
  static const responseRate = 'Javob darajasi';
  static const responseTime = 'Javob vaqti';
  static const hour = 'soat';
  static const availability = 'Mavjudligi';
  static const available = 'Mavjud';
  static const busy = 'Hozir band';
  static const portfolio = 'Portfolio';
  static const projectsCount = 'ta loyiha';
  static const aboutMe = 'Men haqimda';
  static const specializations = 'Mutaxassisligim';
  static const servicePackages = 'Xizmat paketlari';
  static const packagesHint = 'Sizga mos paketni tanlang';
  static const noPackages = "Mutaxassis hali xizmat paketlarini qo'shmagan";
  static const popular = 'Mashhur';
  static const days = 'kun';
  static const selectPackage = 'Tanlash';
  static const priceStartsFrom = "Boshlang'ich narx";

  // usta
  static const breadcrumbMasters = 'Ustalar';
  static const jobs = 'ish';
  static const completedJobs = 'Tugatilgan ishlar';
  static const emergency = 'Shoshilinch';
  static const completedWork = 'Bajarilgan ishlar';
  static const photosCount = 'ta rasm';
  static const aboutMaster = 'Usta haqida';
  static const skills = "Ko'nikmalar";
  static const priceList = 'Narx jadvali';
  static const priceListHint = 'Narxlar taxminiy, murojaatdan keyin aniqlashtiriladi';
  static const serviceArea = "Xizmat ko'rsatadigan hududlar";
  static const startingFrom = "Boshlang'ich narx";
  static const somPerService = "1 xizmat uchun so'm";
  static const emergencyCall = 'Shoshilinch chaqiriq';
  static const emergencyHint = '24/7 ishlaydi, 30-60 daqiqada keladi';
  static const arrivalTime = 'Kelish vaqti';
  static const minute = 'daq';
  static const warranty = 'Kafolat';
  static const months = 'oy';
  static const serviceRadius = 'Xizmat radiusi';
  static const availableToday = 'Bugun mavjud';
  static const callNow = "Hozir qo'ng'iroq qilish";

  // `masterDetail.unit.*`
  static const unitPerService = '1 xizmat';
  static const unitPerProject = '1 loyiha';
  static const unitPerM = '1 metr';
  static const unitPerM2 = '1 m\u00b2';
  static const unitPerPiece = '1 dona';
  static const unitPerRoom = '1 xona';

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
    'interior' => 'Interer dizayn',
    'exterior' => 'Eksterer dizayn',
    'landscape' => 'Landshaft',
    'architecture' => 'Arxitektura',
    _ => code,
  };
}
