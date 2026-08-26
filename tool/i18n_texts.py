"""`*Texts` klasslaridagi qattiq yozilgan matnlarni `t('kalit')` ga o'giradi.

Kalit qiymat bo'yicha topiladi; bir nechta kalit bir xil matnga ega bo'lsa, fayl nomiga
mos prefiks afzal ko'riladi.
"""
import json
import pathlib
import re
import sys
import collections

HERE = pathlib.Path(__file__).parent
ROOT = pathlib.Path('c:/src/business_home')
UZ = json.loads((HERE / 'i18n' / 'uz.json').read_text(encoding='utf-8'))

BY_VALUE = collections.defaultdict(list)
for k, v in UZ.items():
    BY_VALUE[v].append(k)

BS = chr(92)
STR = r"'(?:[^'" + BS + BS + r"]|" + BS + BS + r".)*'|\"(?:[^\"" + BS + BS + r"]|" + BS + BS + r".)*\""
CONST = re.compile(
    r"^(?P<indent>[ ]*)static const (?P<name>\w+) =\s*(?P<value>(?:" + STR + r")(?:\s*\n?\s*(?:" + STR + r"))*)\s*;",
    re.MULTILINE,
)
LITERAL = re.compile(STR)

# Fayl -> kalit prefiksi (bir nechtasi bo'lishi mumkin, tartib bo'yicha sinaladi)
PREFIX = {
    'ads_texts.dart': ['ads'],
    'auth_texts.dart': ['auth', 'register', 'completeProfile', 'authModal', 'kyc'],
    'birja_texts.dart': ['birja'],
    'cabinet_texts.dart': ['cabinet', 'orders', 'myOrders', 'favorites', 'kyc'],
    'create_listing_texts.dart': ['createListing', 'amenity'],
    'create_specialist_texts.dart': ['createSpecialist'],
    'designers_texts.dart': ['designers'],
    'map_search_texts.dart': ['map'],
    'masters_texts.dart': ['masters'],
    'my_home_texts.dart': ['myHome', 'hl', 'mortgage'],
    'news_texts.dart': ['news'],
    'new_projects_texts.dart': ['newProjects'],
    'project_detail_texts.dart': ['detail', 'arch', 'highlights', 'smart', 'docs', 'gallery',
                                  'viewer3d', 'present', 'panorama', 'tour', 'tours'],
    'rent_detail_texts.dart': ['rentDetail', 'detail', 'rent'],
    'secondary_texts.dart': ['secondary', 'rent', 'detail'],
    'specialist_detail_texts.dart': ['designerDetail', 'masterDetail', 'specialist', 'services',
                                     'reviews', 'pf'],
    'chat_thread_screen.dart': ['chat'],
    'create_reel_screen.dart': ['createReel'],
    'order_detail_screen.dart': ['order', 'orders'],
    'reels_screen.dart': ['reels', 'reelsPage'],
    'property_price_map.dart': ['map', 'home'],
}


def unescape(lit):
    body = lit[1:-1]
    return re.sub(BS + BS + '(.)', lambda m: {'n': '\n', 't': '\t'}.get(m.group(1), m.group(1)),
                  body)


def literal_value(chunk):
    return ''.join(unescape(m.group(0)) for m in LITERAL.finditer(chunk))


def pick_key(value, prefixes):
    keys = BY_VALUE.get(value)
    if not keys:
        return None
    for p in prefixes:
        for k in keys:
            if k.startswith(p + '.'):
                return k
    for k in keys:
        if k.startswith('common.'):
            return k
    return keys[0]


def main(apply):
    total = done = 0
    missing = collections.defaultdict(list)
    for path, prefixes in PREFIX.items():
        files = list(ROOT.glob('lib/features/**/' + path))
        if not files:
            print('TOPILMADI:', path)
            continue
        f = files[0]
        s = f.read_text(encoding='utf-8')
        out = []
        last = 0
        for m in CONST.finditer(s):
            total += 1
            value = literal_value(m.group('value'))
            key = pick_key(value, prefixes)
            if key is None:
                missing[path].append((m.group('name'), value[:60]))
                continue
            done += 1
            out.append(s[last:m.start()])
            out.append("%sstatic String get %s => t('%s');" % (m.group('indent'), m.group('name'), key))
            last = m.end()
        out.append(s[last:])
        new = ''.join(out)
        if apply and new != s:
            if "import '" in new and 'i18n/translate.dart' not in new:
                depth = len(f.relative_to(ROOT / 'lib').parts) - 1
                imp = "import '%score/i18n/translate.dart';" % ('../' * depth)
                first = re.search(r"^import .*;$", new, re.MULTILINE)
                new = new[:first.start()] + imp + '\n' + new[first.start():]
            elif 'i18n/translate.dart' not in new:
                depth = len(f.relative_to(ROOT / 'lib').parts) - 1
                imp = "import '%score/i18n/translate.dart';\n\n" % ('../' * depth)
                new = imp + new
            f.write_text(new, encoding='utf-8')
    print('jami %d ta const, %d tasi kalitga bog\'landi' % (total, done))
    for path, items in missing.items():
        print('\n--', path, len(items), 'ta kalitsiz')
        for name, value in items[:200]:
            print('   ', name, '=', value)


main(apply='--apply' in sys.argv)
