import 'package:go_router/go_router.dart';

import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/birja/birja_screen.dart';
import '../features/cabinet/cabinet_screen.dart';
import '../features/designers/designers_screen.dart';
import '../features/home/home_screen.dart';
import '../features/masters/masters_screen.dart';
import '../features/secondary/secondary_detail_screen.dart';
import '../features/secondary/listings_config.dart';
import '../features/secondary/secondary_screen.dart';
import '../features/create_listing/create_listing_screen.dart';
import '../features/legal/legal_screen.dart';
import '../features/map_search/map_search_screen.dart';
import '../features/my_home/my_home_screen.dart';
import '../features/news/news_detail_screen.dart';
import '../features/news/news_screen.dart';
import '../features/project_detail/project_detail_screen.dart';
import '../features/rent/rent_detail_screen.dart';
import '../features/specialist_detail/specialist_detail_screen.dart';
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
    GoRoute(path: '/map', builder: (_, _) => const MapSearchScreen()),
    GoRoute(
      path: '/rent',
      builder: (_, state) => SecondaryScreen(
        config: ListingsConfig.rent,
        initialCity: state.uri.queryParameters['city'],
        openFilters: state.uri.queryParameters['filters'] == 'open',
      ),
    ),
    GoRoute(
      path: '/property/rent/:id',
      builder: (_, state) =>
          RentDetailScreen(id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
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
      builder: (_, state) =>
          SecondaryDetailScreen(id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
    ),
    GoRoute(path: '/new-projects', builder: (_, _) => const NewProjectsScreen()),
    GoRoute(
      path: '/property/:id',
      builder: (_, state) =>
          ProjectDetailScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
    ),
    GoRoute(path: '/my-home', builder: (_, _) => const MyHomeScreen()),

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
      builder: (_, state) => CabinetScreen(tab: state.pathParameters['tab'] ?? 'dashboard'),
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
    // Saytda `/ads` `redirectTo: 'secondary'` — alohida sahifasi yo'q.
    GoRoute(path: '/ads', redirect: (_, _) => '/secondary'),
    GoRoute(path: '/ads/create', builder: (_, _) => const CreateListingScreen()),
    GoRoute(
      path: '/ads/:id/edit',
      builder: (_, state) => CreateListingScreen(
        editId: int.tryParse(state.pathParameters['id'] ?? ''),
        editKind: state.uri.queryParameters['kind'],
      ),
    ),
    GoRoute(
      path: '/agent/:id',
      builder: (_, _) => const PlaceholderScreen(title: 'Agent'),
    ),
    GoRoute(path: '/designers', builder: (_, _) => const DesignersScreen()),
    GoRoute(
      path: '/designers/:id',
      builder: (_, state) => SpecialistDetailScreen(
        id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        kind: SpecialistKind.designer,
      ),
    ),
    GoRoute(path: '/masters', builder: (_, _) => const MastersScreen()),
    GoRoute(
      path: '/masters/:id',
      builder: (_, state) => SpecialistDetailScreen(
        id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        kind: SpecialistKind.master,
      ),
    ),
    GoRoute(
      path: '/specialists/create',
      builder: (_, _) => const PlaceholderScreen(title: 'Mutaxassis yaratish'),
    ),
    GoRoute(path: '/birja', builder: (_, _) => const BirjaScreen()),

    // ── Content ───────────────────────────────────────────────────────────────
    GoRoute(path: '/news', builder: (_, _) => const NewsScreen()),
    GoRoute(
      path: '/news/:id',
      builder: (_, state) =>
          NewsDetailScreen(id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
    ),
    // Ikkalasi ham bitta sahifa; farqi `slug` da.
    GoRoute(
      path: '/privacy',
      builder: (_, _) => const LegalScreen(slug: 'privacy'),
    ),
    GoRoute(
      path: '/terms',
      builder: (_, _) => const LegalScreen(slug: 'terms'),
    ),

    // Vanity project URL — businesshome.uz/<quruvchi>/<loyiha>.
    GoRoute(
      path: '/:developerCode/:projectCode',
      builder: (_, state) => ProjectDetailScreen(
        developerCode: state.pathParameters['developerCode'],
        projectCode: state.pathParameters['projectCode'],
      ),
    ),
  ],
  errorBuilder: (_, state) =>
      PlaceholderScreen(title: 'Sahifa topilmadi', note: state.uri.toString()),
);
