"""`t()` qo'shilgach `const` bo'lolmay qolgan joylardan `const` ni olib tashlaydi.

`flutter analyze` xatolarini o'qiydi, har birining oldidagi eng yaqin `const` ni topadi.
`static const X = ...` bo'lsa — uni getter'ga aylantiradi (til o'zgarganda qayta hisoblansin).
"""
import re
import subprocess
import pathlib
import sys

ROOT = pathlib.Path('c:/src/business_home')
CODES = {
    'const_eval_method_invocation',
    'const_with_non_constant_argument',
    'non_constant_list_element',
    'non_constant_record_field',
    'const_initialized_with_non_constant_value',
    'invalid_constant',
    'non_constant_map_element',
    'non_constant_map_value',
    'non_constant_set_element',
    'const_constructor_with_field_initialized_by_non_const',
}
LINE = re.compile(r'^\s*error\s+-\s+.*?-\s+(?P<file>lib[^ ]*?):(?P<line>\d+):(?P<col>\d+)\s+-\s+(?P<code>\w+)$')


def analyze():
    out = subprocess.run(['flutter', 'analyze'], cwd=ROOT, capture_output=True, text=True,
                         encoding='utf-8', errors='replace', shell=True).stdout
    hits = []
    for line in out.splitlines():
        m = LINE.match(line)
        if m and m.group('code') in CODES:
            hits.append((m.group('file').replace('\\', '/'), int(m.group('line')), int(m.group('col'))))
    return hits, out


def offset(src, line, col):
    pos = 0
    for _ in range(line - 1):
        pos = src.index('\n', pos) + 1
    return pos + col - 1


CONST_DECL = re.compile(r'(?P<indent>[ ]*)static const (?P<name>\w+)\s*=\s*(?P<type><[^;{\[]*>)?\s*(?P<open>[\[{])')


def fix_file(path, positions):
    src = path.read_text(encoding='utf-8')
    cuts = []
    for line, col in positions:
        try:
            off = offset(src, line, col)
        except (ValueError, IndexError):
            continue
        # eng yaqin oldingi `const` (so'z sifatida)
        best = None
        for m in re.finditer(r'\bconst\b', src[:off]):
            best = m
        if best is None:
            continue
        cuts.append((best.start(), best.end()))
    if not cuts:
        return 0
    cuts = sorted(set(cuts), reverse=True)
    for start, end in cuts:
        # `static const NAME = ...` bo'lsa getter qilamiz
        line_start = src.rfind('\n', 0, start) + 1
        head = src[line_start:start]
        if head.strip() == 'static':
            decl = CONST_DECL.match(src, line_start)
            if decl:
                inner = (decl.group('type') or '').strip('<>')
                if decl.group('open') == '[':
                    typ = 'List<%s>' % inner if inner else 'List<dynamic>'
                else:
                    typ = 'Map<%s>' % inner if ',' in inner else ('Set<%s>' % inner if inner else 'dynamic')
                repl = '%sstatic %s get %s => %s%s' % (
                    decl.group('indent'), typ, decl.group('name'),
                    decl.group('type') or '', decl.group('open'))
                src = src[:line_start] + repl + src[decl.end():]
                continue
        # oddiy `const Foo(...)` — faqat so'zni olib tashlaymiz
        after = src[end:end + 1]
        src = src[:start] + src[end + (1 if after == ' ' else 0):]
    path.write_text(src, encoding='utf-8')
    return len(cuts)


def main():
    for round_no in range(1, 12):
        hits, out = analyze()
        if not hits:
            print('tugadi, %d-aylanish' % round_no)
            print(out.strip().splitlines()[-1] if out.strip() else '')
            return
        by_file = {}
        for f, line, col in hits:
            by_file.setdefault(f, []).append((line, col))
        total = 0
        for f, positions in by_file.items():
            total += fix_file(ROOT / f, positions)
        print('%d-aylanish: %d ta xato, %d ta const olib tashlandi' % (round_no, len(hits), total))
        if total == 0:
            print('qo\'lda ko\'rish kerak:', list(by_file)[:5])
            return
    print('aylanishlar tugadi')


main()
