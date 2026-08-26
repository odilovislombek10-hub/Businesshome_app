import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import 'entrance.dart';
import 'site_icon.dart';
import '../../core/models/market_user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/language_service.dart';
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
                if (GoRouterState.of(context).matchedLocation == '/')
                  _Logo(onBar: onBar, onTap: () => context.go('/'))
                else
                  HeaderBackButton(onBar: onBar),
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
                  child: SiteIcon(
                    _menuOpen ? SiteIcons.close : SiteIcons.menu,
                    size: 24,
                    color: onBar,
                  ),
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
                      onFilters: () => context.go('/secondary?filters=open'),
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
                    color: _isTranslucent ? Colors.white24 : theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: SafeArea(bottom: false, child: bar),
            ),
          ),
        ),
        if (_menuOpen) MobileMenuPanel(onClose: () => setState(() => _menuOpen = false)),
      ],
    );
  }

  void _showAiSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const SafeArea(
        child: Padding(padding: EdgeInsets.all(24), child: Text('AI yordamchi tayyorlanmoqda')),
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
                TextSpan(
                  text: 'HOME',
                  style: TextStyle(color: onBar),
                ),
              ],
            ),
            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

/// Ilovada har bir sahifada logotip o'rniga orqaga qaytish turadi — saytda bunday tugma yo'q,
/// chunki u brauzerning o'z tugmasiga tayanadi. Matn tanlangan tilga qarab
/// (`header.back`: Orqaga / Назад / Артка).
class HeaderBackButton extends StatelessWidget {
  const HeaderBackButton({super.key, required this.onBar});

  final Color onBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      child: ListenableBuilder(
        listenable: LanguageService.instance,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SiteIcon(SiteIcons.arrowLeft, size: 22, color: onBar),
            const SizedBox(width: 8),
            Text(
              LanguageService.instance.back,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: onBar,
              ),
            ),
          ],
        ),
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
  const _SearchBar({
    required this.controller,
    required this.translucent,
    this.onSubmit,
    this.onFilters,
  });

  final TextEditingController controller;
  final bool translucent;
  final ValueChanged<String>? onSubmit;

  /// The filter button sitting inside the field's right edge, `/secondary?filters=open`.
  final VoidCallback? onFilters;

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
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: SiteIcon(
            SiteIcons.search,
            size: 18,
            color: translucent ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        // `w-11 h-10` with a divider on its left, exactly as the site places it.
        suffixIcon: onFilters == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 1,
                    height: 24,
                    color: translucent ? Colors.white24 : theme.colorScheme.outlineVariant,
                  ),
                  Pressable(
                    onTap: onFilters,
                    child: SizedBox(
                      width: 44,
                      height: 40,
                      child: Center(
                        child: SiteIcon(
                          SiteIcons.filters,
                          size: 18,
                          color: translucent ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        suffixIconConstraints: const BoxConstraints(minWidth: 45, minHeight: 40),
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

  String get _lang => LanguageService.instance.code;

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
                      onTap: () {
                        LanguageService.instance.set(code);
                        setState(() => _view = _MenuView.main);
                      },
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
                                Text(
                                  auth.user!.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium,
                                ),
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
                    icon: SiteIcons.globe,
                    label: 'Til',
                    trailing: Text(_lang.toUpperCase(), style: theme.textTheme.labelSmall),
                    onTap: () => setState(() => _view = _MenuView.language),
                  ),
                  if (auth.isLoggedIn) ...[
                    _MenuItem(
                      icon: SiteIcons.dashboard,
                      label: 'Mening kabinetim',
                      tint: AppColors.olive,
                      onTap: () => _go(context, '/cabinet'),
                    ),
                    _MenuItem(
                      icon: SiteIcons.heart,
                      label: 'Sevimlilar',
                      tint: AppColors.danger,
                      onTap: () => _go(context, '/cabinet/favorites'),
                    ),
                  ],
                  _MenuItem(
                    icon: SiteIcons.reel,
                    label: 'Reels',
                    tint: const Color(0xFFF43F5E), // rose-500
                    onTap: () => _go(context, '/reels'),
                  ),
                  // Saytda rejim qatori ikki marta chizilgan: biri "Mening uyim" dan
                  // oldin (qaysi rejimga o'tishini yozadi), ikkinchisi undan keyin
                  // ("Rejim" + hozirgi holat + kalit). Ikkalasi ham shu yerda.
                  _MenuItem(
                    icon: themeController.isDark ? SiteIcons.sun : SiteIcons.moon,
                    label: themeController.isDark ? 'Kunduzgi' : 'Tungi',
                    tint: const Color(0xFFF59E0B), // amber-500
                    onTap: themeController.toggle,
                  ),
                  _MenuItem(
                    icon: SiteIcons.house,
                    label: 'Mening uyim',
                    tint: AppColors.bronze,
                    onTap: () => _go(context, '/my-home'),
                  ),
                  _MenuItem(
                    icon: themeController.isDark ? SiteIcons.sun : SiteIcons.moon,
                    label: 'Rejim',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          themeController.isDark ? 'Tungi' : 'Kunduzgi',
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(width: 8),
                        // `w-10 h-6 rounded-full` kalit.
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 24,
                          padding: const EdgeInsets.all(2),
                          alignment: themeController.isDark
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: themeController.isDark
                                ? AppColors.olive
                                : const Color(0xFFE2E8F0), // slate-200
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: themeController.toggle,
                  ),

                  const Divider(height: 20),
                  if (auth.isLoggedIn) ...[
                    // `canCreateListing()` — saytda tugma faqat shu ikki rol uchun.
                    if (auth.user?.role == MarketRole.user || auth.user?.role == MarketRole.agent)
                      FilledButton.icon(
                        onPressed: () => _go(context, '/ads/create'),
                        icon: const Icon(Icons.add),
                        label: const Text("E'lon berish"),
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

  final SiteIconData icon;
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
              child: Center(child: SiteIcon(icon, size: 18, color: color)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
            if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
            SiteIcon(SiteIcons.chevronRight, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
