---
name: sahifa-kochirish
description: businesshome.uz saytining bir bo'limini (sahifa yoki komponentini) Flutter'ga 1:1 ko'chirish. Foydalanuvchi "/secondary ni ko'chir", "ijara sahifasini yoz", "dizaynerlar bo'limini qil", "shu komponentni Flutter'ga o'tkaz" degan topshiriq berganda yoki bosh sahifadan keyingi navbatdagi bo'limga o'tilganda ishlatiladi.
---

# Saytdan Flutter'ga ko'chirish tartibi

Angular shablonini o'qib, o'lchov-o'lchov Flutter'ga ko'chirish usuli. **Hech narsani o'zingdan
o'ylab topma** — har bir raqam, matn va endpoint saytda bor.

## Manbalar qayerda

| Nima | Yo'l |
|---|---|
| Sayt kodi | `C:\src\bh_prod\market\src\app` |
| Backend | `C:\src\bh_prod\api` (routerlar `routers/`, sxemalar `schemas/`) |
| Matnlar | `market/src/app/core/i18n/translations/uz.ts` |
| Ranglar, shriftlar | `market/tailwind.config.js` |
| API metodlari | `core/services/api.service.ts`, `core/services/content.service.ts` |
| Route'lar | `core/../app.routes.ts` |

Shablon ba'zan `.component.html` da, ba'zan `.component.ts` ichida `template:` bo'lib turadi —
ikkalasini ham tekshir.

## Qadamlar

### 1. Shablonni o'qi

```bash
# .html bo'lsa
grep -vE "^\s*<(svg|path|circle|polyline|rect|line)|^\s*</svg>|^\s*$" <komp>.component.html
# inline bo'lsa
sed -n "/template: \`/,/^  \`/p" <komp>.component.ts
```

**Faqat mobil ko'rinishni ol.** `sm:`, `md:`, `lg:`, `xl:` prefiksli klasslar kattaroq ekran
uchun — ularni tashla. `grid-cols-1 sm:grid-cols-2 lg:grid-cols-3` → mobilda **bitta ustun**.
`hidden lg:flex` → mobilda **umuman yo'q**. `lg:hidden` → **faqat mobilda bor**.

### 2. Tailwind → Flutter

Tailwind birligi 4px. `py-10` = vertical 40, `p-5` = all 20, `gap-3` = 12, `mb-8` = 32.

| Tailwind | Flutter |
|---|---|
| `text-xs` 12 · `text-sm` 14 · `text-base` 16 · `text-lg` 18 | `fontSize:` |
| `text-xl` 20 · `text-2xl` 24 · `text-3xl` 30 · `text-4xl` 36 | `fontSize:` |
| `rounded-lg` 8 · `rounded-xl` 12 · `rounded-2xl` 16 · `rounded-3xl` 24 · `rounded-full` | `AppRadius.sm/md/lg/xl/pill` |
| `font-display` | `theme.textTheme.displaySmall` (Playfair) |
| `font-bold` w700 · `font-semibold` w600 · `font-medium` w500 | `fontWeight:` |
| `bg-cream` `bg-dark` `bg-olive` `bg-bronze` | `AppColors.*` |
| `text-dark/60` | `AppColors.dark.withValues(alpha: 0.6)` |
| `aspect-square` 1 · `aspect-[4/3]` · `aspect-video` 16/9 | `AspectRatio` |
| `line-clamp-2` | `maxLines: 2, overflow: TextOverflow.ellipsis` |
| `absolute inset-0` | `Positioned.fill` / `Stack(fit: StackFit.expand)` |

### 2.5. Ikki o'xshash sahifani HECH QACHON bir xil deb hisoblama

Ikkita sahifa (masalan `/secondary` va `/rent`) bir xil ko'rinsa ham, **birini ikkinchisiga
nusxalab qo'yma**. Ular orasida ataylab qilingan farqlar bor va ular ko'zga tashlanmaydi.

Har doim ikkalasini **dastur bilan** solishtir — ko'z bilan emas:

```python
# har bir shablondan chiqarib, yonma-yon qo'y:
#  - filtr maydonlari va ularning TARTIBI
#  - har bir <option> ro'yxati (const propertyTypes, segments, sellers, payments ...)
#  - signal'lar ro'yxati (filterX = signal) — bittasi kam bo'lsa, o'sha maydon yo'q demakdir
#  - saralash variantlari, perPage, roomOptions, bathroomOptions
#  - har bir tugma/checkbox matni
```

Namuna farqlar (haqiqiy misollar):

- `/secondary` da **To'lov** filtri bor, `/rent` da **yo'q** (`filterPayment` signali ham yo'q).
- Mebel/remont variantlari `Ha`/`Yo'q` emas — `Meblangan`/`Mebelsiz`, `Remontli`/`Remontsiz`.
- Maydon yorlig'i o'zgaruvchan: `areaLabelKey()` uy/yer tanlansa `Yer maydoni (sotix)`,
  aks holda `Kvadratura (m²)`.

**Bu qoida faqat filtrlarga emas** — sarlavha, kartalar, tugmalar, bo'limlar tartibi, endpoint,
animatsiya, ikonka: hammasini shu tarzda tekshir. Yuzaki qarash katta xatoga olib keladi.

### 3. Matnlarni i18n'dan ol

`{{ 'x.y' | translate }}` ko'rsang, `uz.ts` dan aynan qiymatni ol. **Tarjima qilma, qisqartirma,
ikki nuqtasini tushirib qoldirma.** Ko'p matn bo'lsa ularni bitta `abstract final class ...Texts`
ga yig'.

### 4. Endpointni tekshir

Komponent `api.getX()` chaqirsa, `api.service.ts` dan **aniq yo'lni va parametr nomini** top.

- Sayt **ikkita bazadan** foydalanadi: `/api/market/...` va `/api/viewer/projects`.
- Parametr nomi har xil: ba'zi joyda `per_page`, ba'zi joyda `limit`. Taxmin qilma.
- Javob shakli har xil: goh ro'yxat, goh `{items, total, page, pages}`.
- Ba'zi endpointlar camelCase qaytaradi (`/rent`, `/secondary`), ba'zilari snake_case.
- Chaqirilgan endpoint shablonda **ishlatilmasligi** mumkin (o'lik kod) — `@for` ichida
  ishlatilganini tekshir, keyin yoz.

Jonli javobni ko'rish: `curl -s -m 25 "https://businesshome.uz/api/market/..." | head -c 400`

### 5. Mavjud narsani qayta yozma

Bular allaqachon bor, ishlat:

| Kerak bo'lsa | Fayl |
|---|---|
| Mulk kartasi | `shared/widgets/property_card.dart` + `shared/models/property_view.dart` |
| Sayt header'i | `shared/widgets/site_header.dart` |
| Ikonkalar | `shared/widgets/site_icon.dart` — yangi ikonka kerak bo'lsa shablondagi `<path d="...">` ni `SiteIcons` ga qo'sh |
| Animatsiyalar | `shared/widgets/entrance.dart` — `Entrance.fadeIn/slideUp`, `Pressable`, `ZoomOnPress`, `Pulse` |
| Xato/bo'sh holat | `shared/widgets/error_view.dart` |
| Narx formati | `core/services/currency_service.dart` |
| Viloyatlar | `core/services/regions_service.dart` |
| Shahar kodi → nomi | `core/constants/city_labels.dart` — backend `city` da **kod** qaytaradi (`tashkent_city`), saytda u `t(getCityLabel(...))` bilan yorliqqa aylanadi |
| Raqam ajratish | `core/utils/format.dart` — `formatNumber`, saytning `formatPrice` i (valyutasiz) |
| Rasm yo'li | `core/api/media_url.dart` — `absoluteMediaUrl()` |

Animatsiya klasslarining mosligi: `animate-fade-in` → `Entrance.fadeIn`, `animate-slide-up` →
`Entrance.slideUp`, `animation-delay: N` → `delay:`, `active:scale-95` → `Pressable(scale: 0.95)`,
`group-hover:scale-105` → `ZoomOnPress`, `animate-pulse` → `Pulse`.

### 6. Dinamik bo'lsin

Adminkadan o'zgaradigan hamma narsa API'dan kelsin: matn, rasm, telefon, havola. Kodga faqat
saytning o'zi ham qattiq yozgan narsalarni yoz (masalan footer havolalari `footer.component.ts` da
turadi). Ikkilanma — saytda qayerda turganini tekshir.

Har bir so'rov alohida yuklansin va xatosi yutilsin: bitta endpoint yiqilsa sahifa oqarmasin,
faqat o'sha bo'lim chizilmasin — saytda ham shunday.

### 7. Route qo'sh

`app/router.dart` da URL sayt bilan **aynan bir xil** bo'lsin (`/property/rent/:id`,
`/cabinet/:tab`). `PlaceholderScreen` o'rniga haqiqiy ekranni qo'y.

### 8. Tekshir

```bash
dart format --line-length 100 lib/
flutter analyze                 # toza bo'lishi shart
flutter test
flutter build apk --debug
DEV=$(adb devices | awk '/emulator/{print $1; exit}')
adb -s $DEV install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s $DEV shell am force-stop uz.businesshome.business_home
adb -s $DEV shell monkey -p uz.businesshome.business_home -c android.intent.category.LAUNCHER 1
sleep 35 && adb -s $DEV exec-out screencap -p > /tmp/ekran.png
```

Skrinshotni **albatta ko'r** — overflow, yuklanmagan rasm, noto'g'ri joylashuv shu yerda chiqadi.

### 9. Solishtirib chiq

Tugatgach shablon bilan qatorma-qator taqqosla:

- [ ] Bo'limlar tartibi shablondagidek
- [ ] Har bo'limning padding'i (`py-*`, `p-*`)
- [ ] Sarlavha `fontSize` lari
- [ ] Fon ranglari
- [ ] Endpoint yo'llari va parametr nomlari
- [ ] Matnlar `uz.ts` bilan bir xil
- [ ] Ikonkalar `SiteIcon` orqali
- [ ] Animatsiya va bosilish effektlari

### 10. Commit

O'zbekcha, nima o'zgargani va **nega** — ayniqsa shablon bilan solishtirishda topilgan farqlarni
yoz.

### 11. Muammo chiqsa — avval O'QI, keyin fikrla

Biror narsa kutilganidek ishlamasa, darrov sabab o'ylab topma. Avval:

1. **Suhbatning oldingi qismini o'qi** — bu narsa haqida allaqachon nima aytilgan? Sen o'zing
   qanday tushuntirgansan? Sening xotirangda o'zing aytgan gaping saqlanmaydi, lekin suhbatda
   turadi.
2. **Qilingan ishlarni ko'r** — `git log`, `worklog` hotirasi, joriy holat fayli. Bu qism tayyor
   deb aytilganmi yoki yo'qmi?
3. **Keyin** tekshir va xulosa qil.

Misol: `/rent` da "Tayyorlanmoqda" chiqdi. Oldin `/property/:id` uchun "detal sahifasi hali
ko'chirilmagan" deb tushuntirilgandi — ikkisi boshqa-boshqa sabab. O'qimasdan xulosa qilsang,
noto'g'ri joyni tuzatasan.

### 12. "Tayyor" degin — faqat EMULYATORDA ko'rganingdan keyin

`flutter analyze` toza bo'lishi va skript `ok` yozishi **hech narsani anglatmaydi**.

- Fayl almashtiruvchi skript mos kelmasa ham `ok` yozib o'tib ketishi mumkin — shuning uchun
  `assert old in s` qo'y va almashtirgandan keyin natijani `grep` bilan tekshir.
- `dart format` fayllarni qayta formatlaydi, shuning uchun oldingi almashtiruv matni mos
  kelmay qolishi mumkin.
- Har bir route'ni ilovada **ochib ko'r**. Ochilmasa — route ulanmagan.

Haqiqiy misol: `/rent` route'i almashtirilmay qolgan (formatter qatorni bo'lib yuborgan edi),
skript `ok` yozgan, `analyze` toza, lekin ilovada "Tayyorlanmoqda" chiqardi. Emulyatorda
tekshirmasdan "tayyor" deb aytilgandi.

### 13. Telefonga moslash — kelishilgan chekinishlar

Bular saytdan **ataylab** farq qiladi, foydalanuvchi so'ragan. Yangi sahifada ham shunday qil:

- **E'lon kartalari 2 ustunda** (`PropertyCard.compact`) — bir ekranda 4 ta karta.
- **Filtr paneli har doim pastki oynada**, qidiruv qatoridagi "Filterlar" tugmasi bilan ochiladi
  — saytda mobilda doim ochiq `aside` bo'lsa ham (dizayner/usta shunday). Ochiq panel telefonda
  ekranning yarmini egallaydi.
- **Hero'ning ustki-ostki bo'shliqlari qisqartirilgan** (`pt-32 py-12` → ~88px + 20px), toolbar
  `py-5` → `py-2.5`, ro'yxat `mt-6` → `mt-3`.

Qolgan hamma narsa shablonday. Bu ro'yxatga o'zingdan yangi chekinish **qo'shma** — avval so'ra.

### 14. Yuklanish holati

Saytda ro'yxat sahifalarida spinner **yo'q**: yangi so'rov ketganda eski ro'yxat ekranda
turaveradi, `loading()` faqat "topilmadi" blokini bosib turadi. `FutureBuilder` bunday
qilmaydi — oxirgi javobni `_last` da saqlab, `snapshot.data ?? _last` bilan chiz. Spinner faqat
birinchi yuklashda (hali hech qanday ma'lumot yo'q).

## Tuzoqlar

- **`Stack` ichidagi `SiteHeader` ni `Positioned` bilan qo'y.** Joylashtirilmagan `Stack` bolasi
  bo'sh cheklov oladi va butun maydonni egallab, ostidagi tarkibni yopib qo'yadi — sahifa oppoq
  chiqadi, logda hech qanday xato bo'lmaydi.
- **9-qadamni alohida o'tkaz, yozayotganda "tekshirdim" deb o'ylama.** Yozish paytida tekshirgandek
  tuyuladi, lekin alohida o'tkazilganda har safar 4-6 ta chetlanish chiqadi.
- **Matnlarni ko'z bilan emas, dastur bilan solishtir** — `uz.ts` dan regex bilan olib, `...Texts`
  dagi qiymat bilan `==` qilib. Saytning o'z xatolari (masalan `Yangiliklarга` dagi kirilcha "га")
  ham aynan ko'chirilishi kerak.
- **Bosilish effektini o'zingdan qo'shma.** Saytda `active:scale` bo'lmasa, `Pressable(scale:)` ham
  bo'lmaydi. Rasmda `group-hover:scale-105` bo'lsa — `Pressable.builder` + `ZoomOnPress`.
- **Zaxira rasm, oy nomlari, format funksiyalari modelda bormi — avval qara.** `NewsItem` da
  `fallbackImage` va `dateLabel` allaqachon bor edi.
- **Saytning o'zida ham xato bor.** `/privacy`, `/terms` va `/news/:id` shablonlarida hech qanday
  `pt-*` yo'q, header esa `fixed` (mobilda `h-14` = 56px) — sarlavha uning ostida qolib ketadi.
  Bunday joyda 1:1 emas, to'g'ri qilib, izohda **nega** chetlanganingni yoz.
- **`pt-32` = 128, `pt-20` = 80** — bu qiymat qat'iy header (56) ustiga qo'shilgan bo'shliqni ham
  o'z ichiga oladi. Ilovada ustiga holat paneli (`MediaQuery.paddingOf(context).top`) qo'shiladi.
- **Shablon `<app-footer />` bilan tugaydimi — tekshir.** Bu allaqachon olti sahifada tushib
  qolgan; `SiteFooterSection` qo'shilsin.
- **`position: sticky` uchun ro'yxat o'rtasida `SliverPersistentHeader(pinned: true)` ishlatma.**
  Viewport sliverlarni **teskari tartibda** chizadi — birinchi sliver eng ustida bo'ladi. Shuning
  uchun qadalgan sarlavhaning **tepasidagi** tarkib uning ustiga chizilib, panel yarim ko'rinib
  qoladi (`SliverAppBar` ishlaydi, chunki u birinchi sliver). Yechim: panelni ro'yxat ichida
  oddiy `SliverToBoxAdapter` qilib qo'y, `ScrollController` bilan o'rnini o'lchab, tepaga
  yetganda `Stack` ustiga nusxasini chiqar — CSS `sticky` bilan aynan bir xil.
- **Fayl yuklab olish `launchUrl` bilan ishlamaydi**, agar sayt uni `responseType: 'blob'` orqali
  olsa: bunday havolalar `Authorization` sarlavhasini talab qiladi. `ApiClient.downloadBytes` +
  `downloadAndOpen` ishlat. Backend `/api/...` ko'rinishidagi nisbiy yo'l qaytaradi —
  `ApiClient.resolveUrl` bilan to'liq URL yasa, aks holda `/api/api/...` chiqadi.
- **Sayt vaqti-vaqti bilan javob bermaydi** (`curl` `000`, 2-3 daqiqa). Rasm yuklanmasa avval
  shuni tekshir, kodni ayblama.
- **Windows MAX_PATH** — arxivni uzun yo'lga ochma, `%TEMP%\atmp` ga och.
- Emulyator: AEHD drayveri o'rnatilgan, AVD `bh_pixel`.
- Heredoc ichida uzun Dart kodi bo'lsa bash yiqiladi — skriptni faylga yozib, `python fayl.py`
  bilan ishlat.
- Dart formatter fayllarni qayta formatlaydi; `replace` qilishdan oldin joriy holatni o'qi.
- **`ListView` ichida `Row(crossAxisAlignment: stretch)` qo'yma** — bola cheksiz balandlik oladi va
  butun ro'yxat **xatosiz, jimgina** chizilmay qoladi (logda ham hech nima yo'q). `IntrinsicHeight`
  bilan o'rab qo'y. Shu sabab birja tafsilot oynasi bo'm-bo'sh chiqqan edi.
- **Bo'sh ekran ko'rsang darrov kodni ayblama, lekin skrinshotni albatta oxirigacha ko'r** — bu xato
  faqat ekranda bilinadi, `flutter analyze` ham, `flutter test` ham tutmaydi.
