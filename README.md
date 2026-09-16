# BusinessHome — mobil ilova

[businesshome.uz](https://businesshome.uz) saytining Flutter'dagi mobil ilovasi. Sayt
(Angular 17) bilan **1:1** bo'lishi talab qilinadi: o'lchov, shrift, matn, endpoint, ikonka va
animatsiyalar shablondan aynan ko'chiriladi.

## Nima bor

Saytdagi barcha bo'limlar ko'chirilgan: bosh sahifa, yangi loyihalar va loyiha tafsiloti
(3D ko'ruvchi, prezentatsiya rejimi), ikkilamchi bozor, ijara, dizaynerlar, ustalar, agent
profili, birja, e'lonlar, yangiliklar, reels, xarita qidiruvi, "Mening uyim", suhbat,
buyurtmalar va kabinetning barcha bo'limlari.

- **Tillar:** o'zbek, rus, qirg'iz — lug'atlar saytning `core/i18n/translations/*.ts` faylidan
  olingan (`lib/core/i18n/`), matn `t('kalit')` orqali chiqadi.
- **API:** `https://businesshome.uz/api` — `/market/...` va `/viewer/projects`.
- **3D ko'ruvchi:** alohida ilova (`3d.businesshome.uz`), WebView ichida saytdagi aynan o'sha
  manzil bilan ochiladi.

## Tuzilma

| Papka | Nima |
|---|---|
| `lib/app/` | Router, mavzu (tema) |
| `lib/core/` | API klient, modellar, servislar (auth, valyuta, til, sevimlilar), i18n lug'atlari |
| `lib/features/` | Har bir sahifa alohida papkada |
| `lib/shared/` | Umumiy vidjetlar: karta, header, ikonkalar, animatsiyalar, xarita |
| `tool/` | Tarjima va tekshiruv skriptlari (README ichida) |

## Ishga tushirish

```bash
flutter pub get
flutter run                 # emulyator yoki telefon
flutter analyze             # toza bo'lishi shart
flutter test
flutter build apk --release
```

## Tekshiruv skriptlari

`tool/` papkasida: yo'llar router'da bormi, API chaqiruvlari backendda bormi, query va POST
maydonlari sxemaga mos kelyaptimi, modellar o'qiydigan kalitlar jonli javobda bormi. Tafsiloti
`tool/README.md` da.

## Eslatma

Ilovada saytdan **ataylab** farq qiladigan ikkita joy bor va ular kelishilgan:
telefonda ro'yxatlar ikki ustunli (saytda bitta) va mutaxassis ro'yxatlarida filtr paneli
pastki oynada ochiladi. Bularni "xato" deb qaytarmaslik kerak — kodda izohi bor.
