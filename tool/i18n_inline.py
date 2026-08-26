"""Ekranlardagi qattiq yozilgan matnlarni `t('kalit')` ga o'giradi."""
import collections
import json
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from dartlex import literals, unescape  # noqa: E402

HERE = pathlib.Path(__file__).parent
ROOT = pathlib.Path('c:/src/business_home')
UZ = json.loads((HERE / 'i18n' / 'uz.json').read_text(encoding='utf-8'))

BY_VALUE = collections.defaultdict(list)
for k, v in UZ.items():
    BY_VALUE[v].append(k)

# Papka -> kalit prefikslari (afzallik tartibida)
FOLDER = {
    'ads': ['ads'],
    'auth': ['auth', 'register', 'completeProfile', 'authModal'],
    'birja': ['birja'],
    'cabinet': ['cabinet', 'orders', 'myOrders', 'favorites', 'kyc', 'services', 'reviews'],
    'chat': ['chat'],
    'create_listing': ['createListing', 'amenity'],
    'create_reel': ['createReel'],
    'create_specialist': ['createSpecialist'],
    'designers': ['designers'],
    'home': ['home', 'hero', 'categories', 'featured', 'stats', 'promo', 'developers',
             'appDownload', 'footer', 'map'],
    'map_search': ['map'],
    'masters': ['masters'],
    'my_home': ['myHome', 'hl', 'mortgage'],
    'new_projects': ['newProjects'],
    'news': ['news'],
    'not_found': ['notFound'],
    'order_detail': ['order', 'orders'],
    'project_detail': ['detail', 'arch', 'highlights', 'smart', 'docs', 'gallery', 'viewer3d',
                       'present', 'panorama', 'tour', 'featuresSection'],
    'reels': ['reels', 'reelsPage'],
    'rent': ['rentDetail', 'rent', 'detail', 'amenity'],
    'secondary': ['secondary', 'rent', 'detail', 'amenity'],
    'specialist_detail': ['designerDetail', 'masterDetail', 'specialist', 'services', 'reviews',
                          'pf'],
    'agent_public': ['agentProfile'],
    'payments': ['cabinet'],
    'legal': ['footer'],
    'shared': ['common', 'header', 'propertyCard', 'report', 'contact', 'tours', 'ai', 'share',
               'breadcrumb', 'amenity'],
}

SKIP_FILES = {'translate.dart', 'language_service.dart'}
# Kalit sifatida ishlatiladigan, matn bo'lmagan qiymatlar
SKIP_VALUES = {'', ' '}


def prefixes_for(path):
    parts = path.relative_to(ROOT / 'lib').parts
    if parts[0] == 'features' and len(parts) > 1:
        return FOLDER.get(parts[1], []) + ['common', 'header']
    return FOLDER.get('shared', [])


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


def convert(path, apply):
    src = path.read_text(encoding='utf-8')
    hits = []
    for start, end, quote, body in literals(src):
        value = unescape(body)
        if value in SKIP_VALUES or len(value) < 2:
            continue
        # `t('...')` / `tp('...')` ichidagi kalitni tegmaymiz. Diqqat: `Text(` ham "t(" bilan
        # tugaydi, shuning uchun oldingi belgini ham tekshiramiz.
        j = start - 1
        while j >= 0 and src[j] in ' \n\t':
            j -= 1
        if j >= 0 and src[j] == '(':
            k = j - 1
            name = ''
            while k >= 0 and (src[k].isalnum() or src[k] == '_'):
                name = src[k] + name
                k -= 1
            if name in ('t', 'tp'):
                continue
        # import/export
        line_start = src.rfind('\n', 0, start) + 1
        line = src[line_start:start]
        if line.lstrip().startswith(('import ', 'export ', 'part ')):
            continue
        key = pick_key(value, prefixes_for(path))
        if key is None:
            continue
        hits.append((start, end, key, value))

    if not hits:
        return 0
    if apply:
        out = []
        last = 0
        for start, end, key, _ in hits:
            out.append(src[last:start])
            out.append("t('%s')" % key)
            last = end
        out.append(src[last:])
        new = ''.join(out)
        if 'core/i18n/translate.dart' not in new:
            depth = len(path.relative_to(ROOT / 'lib').parts) - 1
            imp = "import '%score/i18n/translate.dart';" % ('../' * depth)
            first = re.search(r"^import .*;$", new, re.MULTILINE)
            if first:
                new = new[:first.start()] + imp + '\n' + new[first.start():]
            else:
                new = imp + '\n\n' + new
        path.write_text(new, encoding='utf-8')
    else:
        print('--', path.relative_to(ROOT), len(hits))
        for _, _, key, value in hits[:400]:
            print('    %-42s %s' % (key, value[:60]))
    return len(hits)


def main():
    apply = '--apply' in sys.argv
    only = [a for a in sys.argv[1:] if not a.startswith('--')]
    total = 0
    for path in sorted(ROOT.glob('lib/**/*.dart')):
        rel = str(path.relative_to(ROOT)).replace('\\', '/')
        if '/i18n/' in rel or path.name in SKIP_FILES:
            continue
        if only and not any(o in rel for o in only):
            continue
        total += convert(path, apply)
    print('jami', total)


main()
