"""Ilovadagi barcha o'tish (navigatsiya) yo'llarini router bilan solishtiradi."""
import io
import sys
import re
import pathlib

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
ROOT = pathlib.Path('c:/src/business_home/lib')

router = (ROOT / 'app' / 'router.dart').read_text(encoding='utf-8')
ROUTES = re.findall(r"path:\s*'([^']+)'", router)
print('Router yo\'llari:', len(ROUTES))


def to_regex(route):
    parts = []
    for seg in route.strip('/').split('/'):
        parts.append(r'[^/]+' if seg.startswith(':') else re.escape(seg))
    return re.compile('^/' + '/'.join(parts) + '$')


MATCHERS = [(r, to_regex(r)) for r in ROUTES]

NAV = re.compile(r"context\.(?:go|push|replace)\(\s*'([^']*)'")
NAV_INTERP = re.compile(r"context\.(?:go|push|replace)\(\s*'([^']*\$[^']*)'")

problems = []
for path in sorted(ROOT.rglob('*.dart')):
    rel = str(path).replace(chr(92), '/').split('/lib/')[-1]
    src = path.read_text(encoding='utf-8')
    for i, line in enumerate(src.splitlines(), 1):
        if line.strip().startswith('//'):
            continue
        for m in NAV.finditer(line):
            raw = m.group(1)
            # interpolyatsiyani `:x` ga aylantiramiz
            probe = re.sub(r'\$\{[^}]*\}|\$\w+', 'X', raw)
            probe = probe.split('?')[0]
            if not probe.startswith('/'):
                continue
            if any(rx.match(probe) for _, rx in MATCHERS):
                continue
            problems.append((rel, i, raw, probe))

print('\nRouter\'da yo\'q yo\'llar:', len(problems))
for rel, i, raw, probe in problems:
    print('  %-52s %4d  %s' % (rel, i, raw))

print('\n--- Router yo\'llari ro\'yxati ---')
for r in ROUTES:
    print('   ', r)
