"""Ilova chaqiradigan API yo'llarini backend router'lari bilan solishtiradi."""
import io
import sys
import re
import pathlib

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
APP = pathlib.Path('c:/src/business_home/lib')
API = pathlib.Path('C:/src/bh_prod/api')

# ── backend: @router.get("/x") + include_router(prefix=...) ──────────────────
routes = set()
for f in API.rglob('*.py'):
    src = f.read_text(encoding='utf-8', errors='replace')
    prefix = ''
    m = re.search(r'APIRouter\([^)]*prefix\s*=\s*[\'"]([^\'"]*)[\'"]', src, re.S)
    if m:
        prefix = m.group(1)
    # main.py: `market_router = APIRouter(prefix="/market")` ichiga qo'shiladi
    root = '/market' if f.name.startswith('market_') else ''
    for mm in re.finditer(r'@router\.(get|post|put|patch|delete)\(\s*[\'"]([^\'"]*)[\'"]', src):
        routes.add((mm.group(1).upper(), root + prefix + mm.group(2), f.name))

# include_router prefikslari
includes = []
for f in API.rglob('*.py'):
    src = f.read_text(encoding='utf-8', errors='replace')
    for mm in re.finditer(r'include_router\(\s*([\w\.]+)[^)]*?prefix\s*=\s*[\'"]([^\'"]*)[\'"]', src, re.S):
        includes.append((mm.group(1), mm.group(2)))

print('backend yo\'llari:', len(routes), '| include_router:', len(includes))
for name, pref in includes[:40]:
    print('   include %-28s %s' % (name, pref))


def norm(p):
    p = re.sub(r'\{[^}]*\}', 'X', p)
    p = re.sub(r'\$\{[^}]*\}|\$\w+', 'X', p)
    return p.rstrip('/')


BACK = {}
for method, path, fname in routes:
    BACK.setdefault(norm(path), set()).add(method)

# ── ilova: ApiClient.instance.get<...>('/x') ─────────────────────────────────
CALL = re.compile(r"ApiClient\.instance\.(get|post|put|patch|delete)<[^>]*>\(\s*'([^']*)'")
used = []
for f in sorted(APP.rglob('*.dart')):
    rel = str(f).replace(chr(92), '/').split('/lib/')[-1]
    src = f.read_text(encoding='utf-8')
    # `_base` kabi o'zgaruvchilar
    consts = dict(re.findall(r"static const (\w+)\s*=\s*'([^']*)'", src))
    for m in CALL.finditer(src):
        method, path = m.group(1).upper(), m.group(2)
        for k, v in consts.items():
            path = path.replace('$' + k, v).replace('${' + k + '}', v)
        line = src[:m.start()].count('\n') + 1
        used.append((rel, line, method, path))

print('\nilova chaqiruvlari:', len(used))
missing = []
for rel, line, method, path in used:
    n = norm(path)
    if n in BACK:
        if method not in BACK[n]:
            missing.append((rel, line, method, path, 'metod boshqa: ' + ','.join(sorted(BACK[n]))))
        continue
    missing.append((rel, line, method, path, 'topilmadi'))

print('mos kelmagan:', len(missing))
for rel, line, method, path, why in missing:
    print('  %-46s %4d  %-6s %-52s %s' % (rel, line, method, path, why))
