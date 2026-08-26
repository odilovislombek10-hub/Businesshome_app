"""Ilova yuboradigan query parametrlarini backend imzosi bilan solishtiradi."""
import io
import sys
import re
import pathlib

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
APP = pathlib.Path('c:/src/business_home/lib')
API = pathlib.Path('C:/src/bh_prod/api/routers')


def norm(p):
    p = re.sub(r'\{[^}]*\}', 'X', p)
    p = re.sub(r'\$\{[^}]*\}|\$\w+', 'X', p)
    return p.rstrip('/')


# ── backend: yo'l -> (fayl, funksiya parametrlari) ───────────────────────────
back = {}
for f in API.glob('*.py'):
    src = f.read_text(encoding='utf-8', errors='replace')
    root = '/market' if f.name.startswith('market_') else ''
    m = re.search(r'APIRouter\([^)]*prefix\s*=\s*[\'"]([^\'"]*)[\'"]', src, re.S)
    prefix = m.group(1) if m else ''
    for mm in re.finditer(
            r'@router\.(get|post|put|patch|delete)\(\s*[\'"]([^\'"]*)[\'"][^\n]*\n(?:@[^\n]*\n)*'
            r'(?:async\s+)?def\s+\w+\(([^)]*)\)', src):
        method, path, args = mm.group(1).upper(), mm.group(2), mm.group(3)
        names = re.findall(r'(?:^|,)\s*(\w+)\s*:', args)
        back[(method, norm(root + prefix + path))] = (f.name, names)

CALL = re.compile(
    r"ApiClient\.instance\.(get|post|put|patch|delete)<[^>]*>\(\s*'([^']*)'(.*?)\n\s*\);",
    re.S)
KEY = re.compile(r"'([\w\.]+)':")

for f in sorted(APP.rglob('*.dart')):
    rel = str(f).replace(chr(92), '/').split('/lib/')[-1]
    src = f.read_text(encoding='utf-8')
    consts = dict(re.findall(r"static const (\w+)\s*=\s*'([^']*)'", src))
    for m in CALL.finditer(src):
        method, path, tail = m.group(1).upper(), m.group(2), m.group(3)
        for k, v in consts.items():
            path = path.replace('$' + k, v).replace('${' + k + '}', v)
        qm = re.search(r'query:\s*\{(.*)', tail, re.S)
        if not qm:
            continue
        keys = sorted(set(KEY.findall(qm.group(1))))
        if not keys:
            continue
        info = back.get((method, norm(path)))
        if not info:
            print('%-44s %-6s %-46s BACKEND YO\'Q' % (rel, method, path))
            continue
        fname, names = info
        unknown = [k for k in keys if k not in names]
        if unknown:
            print('%-44s %-6s %-46s' % (rel, method, path))
            print('        ilova: %s' % ', '.join(keys))
            print('        backend (%s): %s' % (fname, ', '.join(names)))
            print('        NOMA\'LUM: %s' % ', '.join(unknown))
