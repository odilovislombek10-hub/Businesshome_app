"""Tanlangan kalitlar to'g'rimi: bir xil o'zbekcha matnli kalitlarning ruschasi farq qilsa ko'rsat."""
import io
import sys
import json
import collections
import pathlib
import re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
HERE = pathlib.Path(__file__).parent
uz = json.loads((HERE / 'i18n' / 'uz.json').read_text(encoding='utf-8'))
ru = json.loads((HERE / 'i18n' / 'ru.json').read_text(encoding='utf-8'))
ky = json.loads((HERE / 'i18n' / 'ky.json').read_text(encoding='utf-8'))

byval = collections.defaultdict(list)
for k, v in uz.items():
    byval[v].append(k)

used = collections.Counter()
where = {}
for p in pathlib.Path('c:/src/business_home/lib').rglob('*.dart'):
    rel = str(p).replace(chr(92), '/')
    if '/i18n/' in rel:
        continue
    for m in re.finditer(r"(?<![A-Za-z0-9_])t\('([^']+)'\)", p.read_text(encoding='utf-8')):
        used[m.group(1)] += 1
        where.setdefault(m.group(1), rel.split('/lib/')[-1])

print('ishlatilgan kalitlar:', len(used), '| jami chaqiruv:', sum(used.values()))
missing = [k for k in used if k not in uz]
print('lug\'atda yo\'q kalitlar:', len(missing))
for k in missing[:20]:
    print('   ', k, '—', where[k])

amb = 0
for key in sorted(used):
    v = uz.get(key)
    if v is None:
        continue
    sibs = byval[v]
    if len(sibs) > 1 and len({ru.get(k) for k in sibs}) > 1:
        amb += 1
        print('%-36s %-24s | %s' % (key, v[:24], ' || '.join('%s=%s' % (k.split('.')[0], str(ru.get(k))[:22]) for k in sibs)))
print('ikkilanadigan joylar:', amb)

nof = [k for k in used if k in uz and (k not in ru or k not in ky)]
print('ru/ky da yo\'q kalitlar:', len(nof), nof[:10])
