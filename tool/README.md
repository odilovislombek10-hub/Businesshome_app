# Tarjima skriptlari

Saytning `market/src/app/core/i18n/translations/{uz,ru,ky}.ts` fayllarini ilovaga ko'chiradi va
kodda qattiq yozilgan matnlarni `t('kalit')` ga o'giradi. Bir marta ishlatilgan (2026-08-27),
lekin sayt lug'ati yangilansa yana kerak bo'ladi.

| Skript | Nima qiladi |
|---|---|
| `parse_i18n.py` | `uz.ts`/`ru.ts`/`ky.ts` → `scratchpad/i18n/*.json` |
| `gen_dart_i18n.py` | JSON → `lib/core/i18n/translations_*.dart` |
| `dartlex.py` | Dart faylidagi satr literallarini topadi (izoh va interpolyatsiyani hisobga olib) |
| `i18n_texts.py` | `*Texts` klasslaridagi `static const` larni `static String get ... => t(...)` ga o'giradi |
| `i18n_inline.py` | Ekranlardagi qattiq yozilgan matnlarni `t(...)` ga o'giradi |
| `fix_const.py` | `t()` sabab `const` bo'lolmay qolgan joylardan `const` ni olib tashlaydi |
| `repair_decls.py` | `fix_const.py` buzgan e'lonlarni to'g'irlaydi (tur nomini qayta hisoblaydi) |
| `check_keys.py` | Ishlatilgan kalitlarni tekshiradi: lug'atda bormi, bir xil matnli kalitlar chalkashmaganmi |

Lug'atni yangilash: `python tool/parse_i18n.py && python tool/gen_dart_i18n.py`
(ikkalasi ham `scratchpad/i18n/` papkasidan foydalanadi — yo'lni skript ichida to'g'irlang).

## Tekshiruv skriptlari (2026-08-27)

Butun ilovani tekshirish uchun. Har biri `python tool/<nom>.py`.

| Skript | Nima tekshiradi |
|---|---|
| `check_routes.py` | Ilovadagi barcha `context.go/push` yo'llari router'da bormi |
| `check_endpoints.py` | Chaqirilgan API yo'llari backend router'larida bormi (metodi bilan) |
| `check_params.py` | Query parametr nomlari backend imzosiga mos kelyaptimi |
| `check_payloads.py` | POST/PUT tanasidagi maydonlar backend sxemasida bormi |
| `check_fields.py` | Model o'qiydigan kalitlar jonli API javobida bormi |
| `fix_nav.py` | Ro'yxatdan tafsilotga o'tishda `go` → `push` (bir martalik) |

**Diqqat:** Python 3.12 da `sys.stdout` ni `TextIOWrapper` bilan almashtirsang,
qisqa chiqish buferda qolib ketadi — `sys.stdout.reconfigure(...)` ishlat.
