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

## Tuzoqlar

- **Sayt vaqti-vaqti bilan javob bermaydi** (`curl` `000`, 2-3 daqiqa). Rasm yuklanmasa avval
  shuni tekshir, kodni ayblama.
- **Windows MAX_PATH** — arxivni uzun yo'lga ochma, `%TEMP%\atmp` ga och.
- Emulyator: AEHD drayveri o'rnatilgan, AVD `bh_pixel`.
- Heredoc ichida uzun Dart kodi bo'lsa bash yiqiladi — skriptni faylga yozib, `python fayl.py`
  bilan ishlat.
- Dart formatter fayllarni qayta formatlaydi; `replace` qilishdan oldin joriy holatni o'qi.
