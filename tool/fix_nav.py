"""Tafsilot sahifalariga o'tishda `go` o'rniga `push` — "Orqaga" ro'yxatga qaytsin."""
import pathlib

ROOT = pathlib.Path('c:/src/business_home/lib')

EDITS = [
    ('shared/widgets/property_card.dart',
     "onTap: () => context.go(property.detailPath),",
     "onTap: () => context.push(property.detailPath),"),
    ('features/home/components/home_top_picks.dart',
     "onTap: () => context.go('/property/${isRent ? 'rent' : 'secondary'}/${listing.id}'),",
     "onTap: () => context.push('/property/${isRent ? 'rent' : 'secondary'}/${listing.id}'),"),
    ('features/home/components/home_top_picks.dart',
     "onTap: () => context.go(specialist.pathIn(section)),",
     "onTap: () => context.push(specialist.pathIn(section)),"),
    ('features/home/components/news_section.dart',
     "onTap: () => context.go('/news/${item.id}'),",
     "onTap: () => context.push('/news/${item.id}'),"),
    ('features/home/components/reels_section.dart',
     "onTap: () => context.go('/reels/${reel.id}'),",
     "onTap: () => context.push('/reels/${reel.id}'),"),
    ('features/news/news_screen.dart',
     "onTap: () => context.go('/news/${item.id}'),",
     "onTap: () => context.push('/news/${item.id}'),"),
    ('features/news/news_detail_screen.dart',
     "onTap: () => context.go('/${project.developerCode}/${project.slug}'),",
     "onTap: () => context.push('/${project.developerCode}/${project.slug}'),"),
    ('features/map_search/map_search_screen.dart',
     "onTap: () => context.go('/property/${rent ? 'rent' : 'secondary'}/${item.id}'),",
     "onTap: () => context.push('/property/${rent ? 'rent' : 'secondary'}/${item.id}'),"),
    ('features/rent/rent_detail_screen.dart',
     "onTap: () => context.go('/property/rent/${item.id}'),",
     "onTap: () => context.push('/property/rent/${item.id}'),"),
    ('features/agent_public/agent_public_screen.dart',
     "onTap: () => context.go('/property/${listing.kind}/${listing.id}'),",
     "onTap: () => context.push('/property/${listing.kind}/${listing.id}'),"),
    ('features/cabinet/cabinet_dashboard.dart',
     "onTap: () => context.go('/cabinet/orders/${order.id}'),",
     "onTap: () => context.push('/cabinet/orders/${order.id}'),"),
    ('features/cabinet/cabinet_screen.dart',
     "onOpen: (order) => context.go('/cabinet/orders/${order.id}'),",
     "onOpen: (order) => context.push('/cabinet/orders/${order.id}'),"),
    ('features/cabinet/cabinet_screen.dart',
     "onOpen: (conv) => context.go('/chat/${conv.id}'),",
     "onOpen: (conv) => context.push('/chat/${conv.id}'),"),
    ('features/order_detail/order_detail_screen.dart',
     "onTap: () => context.go('/chat/$conversationId'),",
     "onTap: () => context.push('/chat/$conversationId'),"),
]

ok = bad = 0
for rel, old, new in EDITS:
    p = ROOT / rel
    s = p.read_text(encoding='utf-8')
    if old not in s:
        print('TOPILMADI', rel, '::', old[:70])
        bad += 1
        continue
    p.write_text(s.replace(old, new), encoding='utf-8')
    ok += 1
print('almashtirildi:', ok, '| topilmadi:', bad)
