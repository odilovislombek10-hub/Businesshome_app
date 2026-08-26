import '../../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/models/region.dart';

/// The site's `footer`.
///
/// Two parts: a bordered top row with the three call-to-action blocks (new projects, phone,
/// complaints), then the link columns — regions split across two lists, services, company, social
/// and support — and the copyright line.
///
/// The site lays the columns out `grid-cols-2` on a phone; the regions are the live list from
/// `/market/regions`, linking into `/secondary?city=`.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key, required this.regions, this.contactPhone});

  final List<Region> regions;
  final String? contactPhone;

  static List<(String, String)> get _services => [
    (t('footer.mortgage'), '/mortgage'),
    ('BusinessHome-Ijara', '/rent'),
    ('BusinessHome-Sport', '/sport'),
    ('BusinessHome-Servis', '/service'),
  ];

  static List<(String, String)> get _company => [
    (t('footer.aboutCompany'), '/about'),
    (t('footer.investors'), '/investors'),
    ('For Investors', '/for-investors'),
    (t('footer.community'), '/community'),
    (t('footer.press'), '/press'),
    (t('footer.career'), '/career'),
    (t('footer.tenders'), '/tenders'),
  ];

  static List<(String, String)> get _support => [
    (t('footer.faq'), '/faq'),
    (t('footer.onlinePurchase'), '/online-purchase'),
    (t('footer.tours'), '/tours'),
    (t('footer.contacts'), '/contacts'),
    (t('footer.antiFraud'), '/anti-fraud'),
    (t('footer.privacy'), '/privacy'),
  ];

  static const _social = [
    ('Telegram', 'https://t.me/businesshome'),
    ('Instagram', 'https://instagram.com/businesshome'),
  ];

  static const _defaultPhone = '+998 71 200 00 00';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = contactPhone ?? _defaultPhone;

    // The site splits the single region list into two columns.
    final half = (regions.length / 2).ceil();
    final regionsLeft = regions.take(half).toList();
    final regionsRight = regions.skip(half).toList();

    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40), // py-10
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.dark.withValues(alpha: 0.1))),
            ),
            child: Column(
              children: [
                _CtaBlock(
                  title: t('footer.newProjects'),
                  button: t('footer.details'),
                  onPressed: () => context.go('/new-projects'),
                ),
                const SizedBox(height: 32), // gap-8
                Column(
                  children: [
                    Text(
                      phone,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PillButton(
                      label: t('footer.call'),
                      onPressed: () => _open('tel:${phone.replaceAll(' ', '')}'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _CtaBlock(
                  title: t('footer.complaint'),
                  button: t('footer.contact'),
                  onPressed: () => _open('https://t.me/businesshome'),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48), // py-12
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LinkColumn(
                        title: t('footer.regions'),
                        links: [
                          for (final region in regionsLeft)
                            (region.label, '/secondary?city=${region.value}'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32), // gap-8
                    Expanded(
                      child: _LinkColumn(
                        // The second regions column has no heading on the site either.
                        title: '',
                        links: [
                          for (final region in regionsRight)
                            (region.label, '/secondary?city=${region.value}'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LinkColumn(title: t('footer.services'), links: _services),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: _LinkColumn(title: t('footer.company'), links: _company),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LinkColumn(title: t('footer.social'), links: _social),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: _LinkColumn(title: t('footer.support'), links: _support),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.dark.withValues(alpha: 0.1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '© ${DateTime.now().year} BusinessHome. ${t('footer.rights')}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 20,
                  children: [
                    _FooterLink(label: t('footer.privacy'), path: '/privacy'),
                    _FooterLink(label: t('footer.terms'), path: '/terms'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _CtaBlock extends StatelessWidget {
  const _CtaBlock({required this.title, required this.button, required this.onPressed});

  final String title;
  final String button;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 16),
        _PillButton(label: button, onPressed: onPressed),
      ],
    );
  }
}

/// `px-8 py-3 rounded-full border border-dark/20` on white — the footer's only button style.
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.dark.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.dark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _LinkColumn extends StatelessWidget {
  const _LinkColumn({required this.title, required this.links});

  final String title;
  final List<(String, String)> links;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16), // mb-4
        ] else
          // Keeps the unlabelled second regions column aligned with the first.
          const SizedBox(height: 36),
        for (final (label, path) in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 8), // space-y-2
            child: _FooterLink(label: label, path: path),
          ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        if (path.startsWith('http')) {
          launchUrl(Uri.parse(path), mode: LaunchMode.externalApplication);
        } else {
          context.go(path);
        }
      },
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.6)),
      ),
    );
  }
}
