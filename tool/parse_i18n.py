"""Saytning uz.ts / ru.ts / ky.ts fayllarini JSON'ga o'giradi."""
import re
import pathlib
import json

SRC = pathlib.Path('C:/src/bh_prod/market/src/app/core/i18n/translations')
OUT = pathlib.Path(__file__).with_name('i18n')
OUT.mkdir(exist_ok=True)

BS = chr(92)
PAT = r"^\s*(['\"])((?:[^BS]|BS.)*?)\1\s*:\s*(['\"])((?:[^BS]|BS.)*?)\3\s*,?\s*$".replace('BS', BS + BS)
LINE = re.compile(PAT)


def unescape(s):
    return re.sub(BS + BS + '(.)', lambda m: {'n': '\n', 't': '\t'}.get(m.group(1), m.group(1)), s)


def parse(name):
    out, bad = {}, []
    for i, line in enumerate(SRC.joinpath(name).read_text(encoding='utf-8').splitlines(), 1):
        t = line.strip()
        if not t or t.startswith('//') or t.startswith('export') or t in ('};', '}'):
            continue
        m = LINE.match(line)
        if not m:
            bad.append((i, t[:90]))
            continue
        out[unescape(m.group(2))] = unescape(m.group(4))
    return out, bad


for lang in ('uz', 'ru', 'ky'):
    d, bad = parse(lang + '.ts')
    print(lang, len(d), 'kalit,', len(bad), 'qator tushunilmadi')
    for i, t in bad[:10]:
        print('   ', i, t)
    (OUT / (lang + '.json')).write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding='utf-8')
