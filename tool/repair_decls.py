"""`fix_const.py` buzib qo'ygan e'lonlarni to'g'irlaydi."""
import re
import pathlib

ROOT = pathlib.Path('c:/src/business_home')


def split_top(inner):
    """Yuqori darajadagi vergullar bo'yicha bo'ladi (< > ( ) [ ] { } ichini hisobga olib)."""
    parts, depth, cur = [], 0, ''
    for ch in inner:
        if ch in '<([{':
            depth += 1
        elif ch in '>)]}':
            depth -= 1
        if ch == ',' and depth == 0:
            parts.append(cur)
            cur = ''
        else:
            cur += ch
    parts.append(cur)
    return [p.strip() for p in parts if p.strip()]


def type_of(generic, opener):
    inner = generic[1:-1]
    if opener == '[':
        return 'List<%s>' % inner
    parts = split_top(inner)
    return ('Map<%s>' % inner) if len(parts) == 2 else ('Set<%s>' % inner)


def read_generic(src, i):
    """`<`dan boshlab mos `>` gacha."""
    depth, j = 0, i
    while j < len(src):
        if src[j] == '<':
            depth += 1
        elif src[j] == '>':
            depth -= 1
            if depth == 0:
                return src[i:j + 1], j + 1
        j += 1
    return None, i


DECL = re.compile(r'^(?P<indent>[ ]*)static (?P<pre>(?:[\w<>,\[\] ]*? )?)(?:get )?(?P<name>\w+) (?:=>|=) ', re.MULTILINE)


def repair(path):
    src = path.read_text(encoding='utf-8')
    out, last, changed = [], 0, 0
    for m in DECL.finditer(src):
        rest = src[m.end():]
        if rest.startswith('<'):
            generic, after = read_generic(src, m.end())
            if generic is None:
                continue
            opener = src[after:after + 1]
            if opener not in '[{':
                continue
            typ = type_of(generic, opener)
            decl = "%sstatic %s get %s => %s%s" % (m.group('indent'), typ, m.group('name'), generic, opener)
        elif rest.startswith('t(') or rest.startswith('tp('):
            if m.group('pre').strip() in ('String', 'final'):
                continue
            decl = "%sstatic String get %s => " % (m.group('indent'), m.group('name'))
            after = m.end()
        else:
            continue
        if src[m.start():after + (1 if rest.startswith('<') else 0)] == decl:
            continue
        out.append(src[last:m.start()])
        out.append(decl)
        last = after + (1 if rest.startswith('<') else 0)
        changed += 1
    out.append(src[last:])
    if changed:
        path.write_text(''.join(out), encoding='utf-8')
    return changed


total = 0
for path in ROOT.glob('lib/**/*.dart'):
    if '/i18n/' in str(path).replace('\\', '/'):
        continue
    n = repair(path)
    if n:
        print(path.relative_to(ROOT), n)
        total += n
print('jami', total)
