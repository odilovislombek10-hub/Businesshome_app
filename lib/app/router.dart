import 'package:go_router/go_router.dart';

import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/secondary/secondary_screen.dart';
import '../features/new_projects/new_projects_screen.dart';
import '../shared/widgets/placeholder_screen.dart';

/// The app mirrors businesshome.uz path-for-path.
///
/// Same URLs means a link shared from the website opens the matching screen here, and the two
/// codebases can be compared route by route.
///
/// Flat, like the site's own route table: `LayoutComponent` is only a router outlet, and each
/// page draws the header itself (see `SiteHeader`). There is no persistent shell to nest into.
/// Order matters — `/:developerCode/:projectCode` is two bare segments, so it goes last or it
/// swallows every other two-segment path.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),

    // ── Auth ──────────────────────────────────────────────────────────────────
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
    GoRoute(
      path: '/auth/oneid/callback',
      builder: (_, _) => const PlaceholderScreen(title: 'OneID natija'),
    ),
    GoRoute(
      path: '/auth/:provider/callback',
      builder: (_, _) => const PlaceholderScreen(title: 'Social login'),
    ),

    // ── Property catalogue ────────────────────────────────────────────────────
    GoRoute(
      path: '/map',
      builder: (_, _) => const PlaceholderScreen(
        title: 'Xaritada qidirish',
        note: 'Saytdagi Leaflet xaritasi — mulklarni xarita ustidan qidirish.',
      ),
    ),
    GoRoute(
      path: '/rent',
      builder: (_, _) => const PlaceholderScreen(title: 'Ijara'),
    ),
    GoRoute(
      path: '/property/rent/:id',
      builder: (_, _) => const PlaceholderScreen(title: 'Ijara mulk'),
    ),
    GoRoute(
      path: '/secondary',
      builder: (_, state) => SecondaryScreen(
        // `?city=` from the map and footer, `?filters=open` from the header button.
        initialCity: state.uri.queryParameters['city'],
        openFilters: state.uri.queryParameters['filters'] == 'open',
      ),
    ),
    GoRoute(
      path: '/property/secondary/:id',
      builder: (_, _) => const PlaceholderScreen(title: 'Ikkilamchi mulk'),
    ),
    GoRoute(path: '/new-projects', builder: (_, _) => const NewProjectsScreen()),
    GoRoute(
      path: '/property/:id',
      builder: (_, _) => const PlaceholderScreen(title: 'Mulk'),
    ),
    GoRoute(
      path: '/my-home',
      builder: (_, _) => const PlaceholderScreen(title: 'Mening uyim'),
    ),

    // ── Reels ─────────────────────────────────────────────────────────────────
    // `/reels/create` before `/reels/:id`, otherwise "create" is read as an id.
    GoRoute(
      path: '/reels',
      builder: (_, _) => const PlaceholderScreen(title: 'Reels'),
    ),
    GoRoute(
      path: '/reels/create',
      builder: (_, _) => const PlaceholderScreen(title: 'Reel yaratish'),
    ),
    GoRoute(
      path: '/reels/:id',
      builder: (_, _) => const PlaceholderScreen(title: 'Reels'),
    ),

    // ── Cabinet ───────────────────────────────────────────────────────────────
    GoRoute(
      path: '/cabinet/orders/:id',
      builder: (_, _) => const PlaceholderScreen(title: 'Buyurtma'),
    ),
    // The site redirects the bare `/cabinet` to its dashboard tab.
    GoRoute(path: '/cabinet', redirect: (_, _) => '/cabinet/dashboard'),
    GoRoute(
      path: '/cabinet/:tab',
      builder: (_, _) => const PlaceholderScreen(title: 'Shaxsiy kabinet'),
    ),
    GoRoute(
      path: '/cabinet-preview',
      builder: (_, _) => const PlaceholderScreen(title: 'Cabinet Preview'),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (_, _) => const PlaceholderScreen(title: 'Suhbat'),
    ),

    // ── Listings & specialists ────────────────────────────────────────────────
    GoRoute(
      path: '/ads',
      builder: (_, _) => const PlaceholderScreen(title: "E'lonlar"),
    ),
    GoRoute(
      path: '/ads/create',
      builder: (_, _) => const PlaceholderScreen(title: "E'lon yaratish"),
    ),
    GoRoute(
      path: '/ads/:id/edit',
      builder: (_, _) => const PlaceholderScreen(title: "E'lonni tahrirlash"),
    ),
    GoRoute(
      path: '/agent/:id',
      builder: (_, _) => const PlaceholderScreen(title: 'Agent'),
    ),
    GoRoute(
      path: '/designers',
      builder: (_, _) => const PlaceholderScreen(title: 'Dizaynerlar'),
    ),
    GoRoute(
      path: '/designers/:id',
      builder: (_, _) => const PlaceholderScreen(title: 'Dizayner'),
    ),
    GoRoute(
      path: '/masters',
      builder: (_, _) => const PlaceholderScreen(title: 'Ustalar'),
    ),
    GoRoute(
      path: '/masters/:id',
      builder: (_, _) => const PlaceholderScreen(title: 'Usta'),
    ),
    GoRoute(
      path: '/specialists/create',
      builder: (_, _) => const PlaceholderScreen(title: 'Mutaxassis yaratish'),
    ),
    GoRoute(
      path: '/birja',
      builder: (_, _) => const PlaceholderScreen(
        title: 'Birja',
        note: 'Mijoz buyurtmalari — ustalar va dizaynerlar uchun.',
      ),
    ),

    // ── Content ───────────────────────────────────────────────────────────────
    GoRoute(
      path: '/news',
      builder: (_, _) => const PlaceholderScreen(title: 'Yangiliklar'),
    ),
    GoRoute(
      path: '/news/:id',
      builder: (_, _) => const PlaceholderScreen(title: 'Yangilik'),
    ),
    GoRoute(
      path: '/privacy',
      builder: (_, _) => const PlaceholderScreen(title: 'Maxfiylik siyosati'),
    ),
    GoRoute(
      path: '/terms',
      builder: (_, _) => const PlaceholderScreen(title: 'Foydalanish shartlari'),
    ),

    // Vanity project URL — businesshome.uz/<quruvchi>/<loyiha>.
    GoRoute(
      path: '/:developerCode/:projectCode',
      builder: (_, state) => PlaceholderScreen(
        title: state.pathParameters['projectCode'] ?? 'Loyiha',
        note: 'Quruvchi: ${state.pathParameters['developerCode']}',
      ),
    ),
  ],
  errorBuilder: (_, state) =>
      PlaceholderScreen(title: 'Sahifa topilmadi', note: state.uri.toString()),
);
