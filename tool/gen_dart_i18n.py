"""JSON lug'atlarni Dart fayllariga yozadi."""
import json
import pathlib

HERE = pathlib.Path(__file__).parent
DEST = pathlib.Path('c:/src/business_home/lib/core/i18n')
DEST.mkdir(parents=True, exist_ok=True)
BS = chr(92)


def dart_string(s):
    s = s.replace(BS, BS + BS)
    s = s.replace("'", BS + "'")
    s = s.replace('$', BS + '$')
    s = s.replace('\n', BS + 'n')
    s = s.replace('\t', BS + 't')
    return "'" + s + "'"


NAMES = {'uz': "O'zbekcha", 'ru': 'Русский', 'ky': 'Кыргызча'}

for lang in ('uz', 'ru', 'ky'):
    d = json.loads((HERE / 'i18n' / (lang + '.json')).read_text(encoding='utf-8'))
    lines = [
        '// AVTOMATIK YARATILGAN — qo\'lda tahrirlamang.',
        '//',
        '// Manba: `market/src/app/core/i18n/translations/%s.ts` (%s).' % (lang, NAMES[lang]),
        '// Yangilash: `scratchpad/parse_i18n.py` va `gen_dart_i18n.py`.',
        '',
        'const Map<String, String> %sTranslations = {' % lang,
    ]
    for k, v in d.items():
        lines.append('  %s: %s,' % (dart_string(k), dart_string(v)))
    lines.append('};')
    lines.append('')
    (DEST / ('translations_%s.dart' % lang)).write_text('\n'.join(lines), encoding='utf-8')
    print(lang, len(d))
