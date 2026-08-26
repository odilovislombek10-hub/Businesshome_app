"""Model o'qiydigan maydonlar API javobida bormi — jonli tekshiruv."""
import io
import sys
import re
import json
import pathlib
import subprocess

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
APP = pathlib.Path('c:/src/business_home/lib')
BASE = 'https://businesshome.uz/api'

# (nomi, URL, model fayli, javobdagi ro'yxat kaliti)
CASES = [
    ('secondary', '/market/secondary?per_page=1', 'core/models/property_listing.dart', 'items'),
    ('rent', '/market/rent?per_page=1', 'core/models/property_listing.dart', 'items'),
    ('ads', '/market/ads?per_page=1', 'features/ads/ads_repository.dart', 'items'),
    ('projects', '/market/projects', 'core/models/project.dart', None),
    ('designers', '/market/designers?per_page=1', 'features/designers/designers_repository.dart', 'items'),
    ('masters', '/market/masters?per_page=1', 'features/masters/masters_repository.dart', 'items'),
    ('reels', '/market/reels?limit=1', 'core/models/reel.dart', None),
    ('news', '/market/content/news?per_page=1', 'features/news/news_repository.dart', 'items'),
    ('birja', '/market/birja/orders?per_page=1', 'features/birja/birja_repository.dart', 'items'),
    ('developers', '/market/developers', 'core/models/developer.dart', None),
    ('homepage', '/market/homepage', 'core/models/page_content.dart', None),
]


def fetch(url):
    out = subprocess.run(['curl', '-s', '-m', '30', BASE + url], capture_output=True, text=True,
                         encoding='utf-8', errors='replace').stdout
    try:
        return json.loads(out)
    except Exception:
        return None


def keys_of(sample):
    if isinstance(sample, dict):
        return set(sample.keys())
    return set()


for name, url, model, list_key in CASES:
    data = fetch(url)
    if data is None:
        print('%-12s javob o\'qilmadi' % name)
        continue
    row = data
    if list_key and isinstance(data, dict):
        row = (data.get(list_key) or [None])[0]
    elif isinstance(data, list):
        row = data[0] if data else None
    if row is None:
        print('%-12s bo\'sh ro\'yxat' % name)
        continue
    have = keys_of(row)
    src = (APP / model).read_text(encoding='utf-8')
    used = set(re.findall(r"json\['([\w\.]+)'\]|row\['([\w\.]+)'\]|data\['([\w\.]+)'\]", src))
    used = {a or b or c for a, b, c in used}
    missing = sorted(k for k in used if k not in have)
    print('%-12s javobda %2d kalit, model %2d ta o\'qiydi, %d tasi javobda yo\'q'
          % (name, len(have), len(used), len(missing)))
    if missing:
        print('             ' + ', '.join(missing))
