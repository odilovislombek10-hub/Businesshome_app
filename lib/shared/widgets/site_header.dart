import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/theme_controller.dart';

/// Port of the site's `app-header` at mobile width.
///
/// On the site every page renders this itself (`LayoutComponent` is just a router outlet), so it
/// is a widget screens place in their own `Scaffold` rather than a shell wrapped around them.
///
/// Layout, taken from `header.component.html`:
/// - 56px bar (`h-14`): logo + "Business**HOME**", AI button, hamburger.
/// - A search row underneath that collapses once the page is scrolled (`isScrolled()`).
/// - The hamburger expands a panel from under the bar (`absolute top-full`, `animate-slide-up`)
///   — not a side drawer.
/// - Over the home page's hero the bar is translucent with a blur (`isEffectivelyTransparent()`).
class SiteHeader extends StatefulWidget {
  const SiteHeader({
    super.key,
    this.transparent = false,
    this.showSearch = true,
    this.scrolled = false,
    this.onSearch,
  });

  /// True on the home page, where the bar floats over the hero image.
  final bool transparent;

  /// The site hides the search row on pages that have a search of their own.
  final bool showSearch;

  /// Drives both the translucent-to-solid switch and the collapsing search row.
  final bool scrolled;

  final ValueChanged<String>? onSearch;

  @override
  State<SiteHeader> createState() => _SiteHeaderState();
}

class _SiteHeaderState extends State<SiteHeader> {
  final _search = TextEditingController();
  bool _menuOpen = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// The bar only stays translucent while the page is at the top.
  bool get _isTranslucent => widget.transparent && !widget.scrolled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final onBar = _isTranslucent ? Colors.white : theme.colorScheme.onSurface;

    final bar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 56, // h-14
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _Logo(onBar: onBar, onTap: () => context.go('/')),
                const Spacer(),
                // AI assistant — `sm:hidden`, so mobile-only on the site too.
                _IconButton(
                  onBar: onBar,
                  onPressed: () => _showAiSheet(context),
                  child: Text(
                    'AI',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: onBar,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _IconButton(
                  onBar: onBar,
                  onPressed: () => setState(() => _menuOpen = !_menuOpen),
                  child: Icon(_menuOpen ? Icons.close : Icons.menu, size: 24, color: onBar),
                ),
              ],
            ),
          ),
        ),
        // The search row collapses away once the page scrolls.
        if (widget.showSearch)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: widget.scrolled
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _SearchBar(
                      controller: _search,
                      translucent: _isTranslucent,
                      onSubmit: widget.onSearch,
                    ),
                  ),
          ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRect(
          child: BackdropFilter(
            // `backdrop-blur-xl` on the site; harmless when the bar is opaque.
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: _isTranslucent
                    ? (dark ? AppColors.scaffoldDark.withValues(alpha: 0.4) : Colors.white10)
                    : theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: _isTranslucent
                        ? Colors.white24
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: SafeArea(bottom: false, child: bar),
            ),
          ),
        ),
        if (_menuOpen)
          MobileMenuPanel(onClose: () => setState(() => _menuOpen = false)),
      ],
    );
  }

  void _showAiSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('AI yordamchi tayyorlanmoqda'),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.onBar, required this.onTap});

  final Color onBar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.asset('assets/images/logo.jpg', width: 36, height: 36, fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
          // `font-display` with "Business" in the brand colour and "HOME" in the bar's colour.
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Business',
                  style: TextStyle(color: AppColors.olive),
                ),
                TextSpan(text: 'HOME', style: TextStyle(color: onBar)),
              ],
            ),
            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.child, required this.onPressed, required this.onBar});

  final Widget child;
  final VoidCallback onPressed;
  final Color onBar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      // 44x44 minimum — the site sets `min-w-[44px] min-h-[44px]` for the same reason.
      child: SizedBox(width: 44, height: 44, child: Center(child: child)),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.translucent, this.onSubmit});

  final TextEditingController controller;
  final bool translucent;
  final ValueChanged<String>? onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmit,
      style: TextStyle(color: translucent ? Colors.white : theme.colorScheme.onSurface),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Qidiruv: kvartira, loyiha, tuman…',
        hintStyle: TextStyle(
          color: translucent ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Icons.search,
          size: 18,
          color: translucent ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: translucent ? Colors.white10 : theme.inputDecorationTheme.fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: translucent ? Colors.white24 : theme.colorScheme.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: translucent ? Colors.white24 : theme.colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

/// The panel the hamburger opens, item for item as `header.component.html` renders it.
///
/// Note what is *not* here: the six catalogue links (`/secondary`, `/new-projects`, `/rent`,
/// `/designers`, `/masters`, `/birja`) live in the desktop nav bar only. On a phone the site
/// reaches those through the home page's category and service cards, and through search.
class MobileMenuPanel extends StatefulWidget {
  const MobileMenuPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<MobileMenuPanel> createState() => _MobileMenuPanelState();
}

enum _MenuView { main, language }

class _MobileMenuPanelState extends State<MobileMenuPanel> {
  _MenuView _view = _MenuView.main;

  /// `uz` / `ru` / `ky`, the three the site offers.
  static const _languages = [
    ('uz', "O'zbekcha", '🇺🇿'),
    ('ru', 'Русский', '🇷🇺'),
    ('ky', 'Кыргызча', '🇰🇬'),
  ];

  String _lang = 'uz';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();
    final themeController = context.watch<ThemeController>();

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: _view == _MenuView.language
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => setState(() => _view = _MenuView.main),
                      ),
                      Text('Tilni tanlang', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  for (final (code, label, flag) in _languages)
                    ListTile(
                      leading: Text(flag, style: const TextStyle(fontSize: 22)),
                      title: Text(label),
                      trailing: _lang == code
                          ? const Icon(Icons.check, color: AppColors.olive)
                          : null,
                      onTap: () => setState(() {
                        _lang = code;
                        _view = _MenuView.main;
                      }),
                    ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (auth.isLoggedIn) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.olive.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.olive.withValues(alpha: 0.2),
                            child: Text(
                              auth.user!.fullName.isEmpty
                                  ? 'U'
                                  : auth.user!.fullName.characters.first.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.olive,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(auth.user!.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium),
                                Text(auth.user!.phone, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  _MenuItem(
                    icon: Icons.language,
                    label: 'Til',
                    trailing: Text(
                      _lang.toUpperCase(),
                      style: theme.textTheme.labelSmall,
                    ),
                    onTap: () => setState(() => _view = _MenuView.language),
                  ),
                  if (auth.isLoggedIn) ...[
                    _MenuItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Mening kabinetim',
                      tint: AppColors.olive,
                      onTap: () => _go(context, '/cabinet'),
                    ),
                    _MenuItem(
                      icon: Icons.favorite_outline,
                      label: 'Sevimlilar',
                      tint: AppColors.danger,
                      onTap: () => _go(context, '/cabinet/favorites'),
                    ),
                  ],
                  _MenuItem(
                    icon: Icons.play_circle_outline,
                    label: 'Reels',
                    tint: const Color(0xFFF43F5E), // rose-500
                    onTap: () => _go(context, '/reels'),
                  ),
                  _MenuItem(
                    icon: Icons.home_outlined,
                    label: 'Mening uyim',
                    onTap: () => _go(context, '/my-home'),
                  ),
                  _MenuItem(
                    icon: themeController.isDark ? Icons.light_mode : Icons.dark_mode,
                    label: 'Tema',
                    trailing: Text(
                      themeController.isDark ? 'Tungi' : 'Yorug‘',
                      style: theme.textTheme.labelSmall,
                    ),
                    onTap: themeController.toggle,
                  ),

                  const Divider(height: 20),
                  if (auth.isLoggedIn) ...[
                    FilledButton.icon(
                      onPressed: () => _go(context, '/ads/create'),
                      icon: const Icon(Icons.add),
                      label: const Text("E'lon yaratish"),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        auth.logout();
                        widget.onClose();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Chiqish'),
                    ),
                  ] else
                    FilledButton.icon(
                      onPressed: () => _go(context, '/login'),
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Kirish'),
                    ),
                ],
              ),
      ),
    );
  }

  void _go(BuildContext context, String path) {
    widget.onClose();
    context.go(path);
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tint ?? theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
            if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
            Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
