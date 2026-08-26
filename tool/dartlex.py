"""Dart faylini oddiy leksik ajratish: satr literallari qayerda ekanini topadi.

Izohlarni va interpolyatsiyani hisobga oladi, shuning uchun o'zbekcha izohdagi apostrof
(`bo'sh`) satr deb o'qilmaydi.
"""

BS = chr(92)


def literals(src):
    """(start, end, quote, body) — faqat oddiy (interpolyatsiyasiz) literallar."""
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        # izohlar
        if c == '/' and i + 1 < n and src[i + 1] == '/':
            while i < n and src[i] != '\n':
                i += 1
            continue
        if c == '/' and i + 1 < n and src[i + 1] == '*':
            i += 2
            depth = 1
            while i < n and depth:
                if src.startswith('/*', i):
                    depth += 1
                    i += 2
                elif src.startswith('*/', i):
                    depth -= 1
                    i += 2
                else:
                    i += 1
            continue
        if c in ('"', "'"):
            raw = i > 0 and src[i - 1] == 'r'
            triple = src.startswith(c * 3, i)
            quote = c * 3 if triple else c
            start = i
            i += len(quote)
            body = []
            simple = True
            while i < n:
                if not raw and src[i] == BS:
                    body.append(src[i:i + 2])
                    i += 2
                    continue
                if not raw and src[i] == '$':
                    simple = False
                    # interpolyatsiya: ${...} yoki $name
                    if i + 1 < n and src[i + 1] == '{':
                        depth = 0
                        i += 1
                        while i < n:
                            if src[i] == '{':
                                depth += 1
                            elif src[i] == '}':
                                depth -= 1
                                if depth == 0:
                                    i += 1
                                    break
                            i += 1
                        continue
                    i += 1
                    continue
                if src.startswith(quote, i):
                    i += len(quote)
                    break
                if src[i] == '\n' and not triple:
                    break  # yopilmagan satr — xatolikdan qochamiz
                body.append(src[i])
                i += 1
            if simple and not raw and not triple:
                out.append((start, i, quote, ''.join(body)))
            continue
        i += 1
    return out


def unescape(body):
    out = []
    i = 0
    while i < len(body):
        if body[i] == BS and i + 1 < len(body):
            nxt = body[i + 1]
            out.append({'n': '\n', 't': '\t'}.get(nxt, nxt))
            i += 2
        else:
            out.append(body[i])
            i += 1
    return ''.join(out)
