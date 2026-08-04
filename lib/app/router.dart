import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/new_projects/new_projects_screen.dart';
import '../shared/widgets/placeholder_screen.dart';
import 'app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// The app mirrors businesshome.uz path-for-path.
///
/// Same URLs means a link shared from the website opens the matching screen here, and the two
/// codebases can be compared route by route.
///
/// Five of the site's destinations become bottom-bar branches; every other page is nested under
/// the branch it belongs to, so opening a listing keeps the bar visible instead of dropping the
/// user out of the shell. Auth lives outside the shell — it is a full-screen interruption, the
/// same role the site's login modal plays.
final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(navigationShell: shell),
      branches: [
        // ── 1. Bosh sahifa — also hosts every page the drawer opens ────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const HomeScreen(),
              routes: [
                GoRoute(path: 'new-projects', builder: (_, _) => const NewProjectsScreen()),
                GoRoute(path: 'rent', builder: (_, _) => const PlaceholderScreen(title: 'Ijara')),
                GoRoute(
                  path: 'property/rent/:id',
                  builder: (_, _) => const PlaceholderScreen(title: 'Ijara mulk'),
                ),
                GoRoute(
                  path: 'property/secondary/:id',
                  builder: (_, _) => const PlaceholderScreen(title: 'Ikkilamchi mulk'),
                ),
                GoRoute(
                  path: 'property/:id',
                  builder: (_, _) => const PlaceholderScreen(title: 'Mulk'),
                ),
                GoRoute(
                  path: 'map',
                  builder: (_, _) => const PlaceholderScreen(
                    title: 'Xaritada qidirish',
                    note: 'Saytdagi Leaflet xaritasi — mulklarni xarita ustidan qidirish.',
                  ),
                ),
                GoRoute(
                  path: 'designers',
                  builder: (_, _) => const PlaceholderScreen(title: 'Dizaynerlar'),
                ),
                GoRoute(
                  path: 'designers/:id',
                  builder: (_, _) => const PlaceholderScreen(title: 'Dizayner'),
                ),
                GoRoute(path: 'masters', builder: (_, _) => const PlaceholderScreen(title: 'Ustalar')),
                GoRoute(
                  path: 'masters/:id',
                  builder: (_, _) => const PlaceholderScreen(title: 'Usta'),
                ),
                GoRoute(
                  path: 'specialists/create',
                  builder: (_, _) => const PlaceholderScreen(title: 'Mutaxassis yaratish'),
                ),
                GoRoute(
                  path: 'birja',
                  builder: (_, _) => const PlaceholderScreen(
                    title: 'Birja',
                    note: 'Mijoz buyurtmalari — ustalar va dizaynerlar uchun.',
                  ),
                ),
                // `ads/create` before `ads/:id/edit` is not strictly required (different segment
                // counts) but keeps the create/edit pair adjacent and readable.
                GoRoute(path: 'ads', builder: (_, _) => const PlaceholderScreen(title: "E'lonlar")),
                GoRoute(
                  path: 'ads/create',
                  builder: (_, _) => const PlaceholderScreen(title: "E'lon yaratish"),
                ),
                GoRoute(
                  path: 'ads/:id/edit',
                  builder: (_, _) => const PlaceholderScreen(title: "E'lonni tahrirlash"),
                ),
                GoRoute(path: 'agent/:id', builder: (_, _) => const PlaceholderScreen(title: 'Agent')),
                GoRoute(
                  path: 'news',
                  builder: (_, _) => const PlaceholderScreen(title: 'Yangiliklar'),
                ),
                GoRoute(
                  path: 'news/:id',
                  builder: (_, _) => const PlaceholderScreen(title: 'Yangilik'),
                ),
                GoRoute(
                  path: 'privacy',
                  builder: (_, _) => const PlaceholderScreen(title: 'Maxfiylik siyosati'),
                ),
                GoRoute(
                  path: 'terms',
                  builder: (_, _) => const PlaceholderScreen(title: 'Foydalanish shartlari'),
                ),
                // Vanity project URL — businesshome.uz/<quruvchi>/<loyiha>. Two bare segments, so
                // it must stay last: declared earlier it would swallow `ads/create` and friends.
                GoRoute(
                  path: ':developerCode/:projectCode',
                  builder: (_, state) => PlaceholderScreen(
                    title: state.pathParameters['projectCode'] ?? 'Loyiha',
                    note: 'Quruvchi: ${state.pathParameters['developerCode']}',
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── 2. Business (ikkilamchi bozor) ─────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/secondary',
              builder: (_, _) => const PlaceholderScreen(title: 'Ikkilamchi bozor'),
            ),
          ],
        ),

        // ── 3. Reels ───────────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reels',
              builder: (_, _) => const PlaceholderScreen(title: 'Reels'),
              routes: [
                // `create` before `:id`, otherwise "create" is read as a reel id.
                GoRoute(
                  path: 'create',
                  builder: (_, _) => const PlaceholderScreen(title: 'Reel yaratish'),
                ),
                GoRoute(path: ':id', builder: (_, _) => const PlaceholderScreen(title: 'Reels')),
              ],
            ),
          ],
        ),

        // ── 4. Mening uyim ─────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/my-home',
              builder: (_, _) => const PlaceholderScreen(title: 'Mening uyim'),
            ),
          ],
        ),

        // ── 5. Kabinet ─────────────────────────────────────────────────────────
        // The branch defaults to its first route, `/cabinet`, which redirects on to the
        // dashboard tab — the same `redirectTo: 'dashboard'` the site's child route does.
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/cabinet', redirect: (_, _) => '/cabinet/dashboard'),
            GoRoute(
              path: '/cabinet/orders/:id',
              builder: (_, _) => const PlaceholderScreen(title: 'Buyurtma'),
            ),
            GoRoute(
              path: '/cabinet/:tab',
              builder: (_, _) => const PlaceholderScreen(title: 'Shaxsiy kabinet'),
            ),
            GoRoute(
              path: '/cabinet-preview',
              builder: (_, _) => const PlaceholderScreen(title: 'Cabinet Preview'),
            ),
            GoRoute(path: '/chat/:id', builder: (_, _) => const PlaceholderScreen(title: 'Suhbat')),
          ],
        ),
      ],
    ),

    // ── Auth — outside the shell: full-screen, no bottom bar ───────────────────
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/auth/oneid/callback',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const PlaceholderScreen(title: 'OneID natija'),
    ),
    GoRoute(
      path: '/auth/:provider/callback',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const PlaceholderScreen(title: 'Social login'),
    ),
  ],
  errorBuilder: (_, state) => PlaceholderScreen(
    title: 'Sahifa topilmadi',
    note: state.uri.toString(),
  ),
);
