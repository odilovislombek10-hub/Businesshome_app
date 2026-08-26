"""POST/PUT tanasidagi maydonlarni backend sxemasi bilan solishtiradi."""
import io
import sys
import re
import pathlib

sys.stdout.reconfigure(encoding='utf-8', errors='replace')
APP = pathlib.Path('c:/src/business_home/lib')
API = pathlib.Path('C:/src/bh_prod/api')


def norm(p):
    p = re.sub(r'\{[^}]*\}', 'X', p)
    p = re.sub(r'\$\{[^}]*\}|\$\w+', 'X', p)
    return p.rstrip('/')


# ── backend: yo'l -> (fayl, funksiya matni) ─────────────────────────────────
routes = {}
for f in sorted(API.glob('routers/*.py')):
    src = f.read_text(encoding='utf-8', errors='replace')
    root = '/market' if f.name.startswith('market_') else ''
    m = re.search(r'APIRouter\([^)]*prefix\s*=\s*[\'"]([^\'"]*)[\'"]', src, re.S)
    prefix = m.group(1) if m else ''
    for mm in re.finditer(
            r'@router\.(post|put|patch)\(\s*[\'"]([^\'"]*)[\'"][^\n]*\n(?:@[^\n]*\n)*'
            r'(?:async\s+)?def\s+\w+\(([^)]*)\)', src):
        routes[(mm.group(1).upper(), norm(root + prefix + mm.group(2)))] = (f, mm.group(3))

# ── sxemalar: klass -> maydonlar ────────────────────────────────────────────
schemas = {}
for f in list(API.glob('schemas/*.py')) + list(API.glob('routers/*.py')):
    src = f.read_text(encoding='utf-8', errors='replace')
    for mm in re.finditer(r'class (\w+)\(BaseModel\):(.*?)(?=\nclass |\Z)', src, re.S):
        fields = re.findall(r'^\s{4}(\w+)\s*:', mm.group(2), re.M)
        alias = re.findall(r'alias\s*=\s*[\'"](\w+)[\'"]', mm.group(2))
        schemas[mm.group(1)] = set(fields) | set(alias)

CALL = re.compile(r"ApiClient\.instance\.(post|put|patch)<[^>]*>\(\s*'([^']*)'(.*?)\n\s*\);", re.S)
KEY = re.compile(r"'([\w\.]+)':")

for f in sorted(APP.rglob('*.dart')):
    rel = str(f).replace(chr(92), '/').split('/lib/')[-1]
    src = f.read_text(encoding='utf-8')
    consts = dict(re.findall(r"static const (\w+)\s*=\s*'([^']*)'", src))
    for m in CALL.finditer(src):
        method, path, tail = m.group(1).upper(), m.group(2), m.group(3)
        for k, v in consts.items():
            path = path.replace('$' + k, v).replace('${' + k + '}', v)
        dm = re.search(r'data:\s*\{(.*)', tail, re.S)
        if not dm:
            continue
        keys = sorted(set(KEY.findall(dm.group(1))))
        if not keys:
            continue
        info = routes.get((method, norm(path)))
        if not info:
            print('%-46s %-5s %-44s ROUTE YO\'Q' % (rel, method, path))
            continue
        rf, args = info
        models = [c for c in re.findall(r':\s*(\w+)', args) if c in schemas]
        if not models:
            print('%-46s %-5s %-44s sxema topilmadi (%s)' % (rel, method, path, rf.name))
            continue
        allowed = set()
        for c in models:
            allowed |= schemas[c]
        print('OK %-44s %-5s %-40s %s' % (rel, method, path, ','.join(models)))
        unknown = [k for k in keys if k not in allowed]
        if unknown:
            print('%-46s %-5s %s' % (rel, method, path))
            print('      sxema: %s (%s)' % (', '.join(models), rf.name))
            print('      NOMA\'LUM: %s' % ', '.join(unknown))
