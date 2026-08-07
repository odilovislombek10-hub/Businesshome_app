import 'package:flutter/material.dart';

import '../../../shared/widgets/app_image.dart';
import '../../../app/theme.dart';
import '../../../core/api/media_url.dart';
import '../../../core/models/developer_summary.dart';

/// The site's `developers-slider`.
///
/// A heading with two circular arrow buttons on the right, then a horizontally scrolling row of
/// 200px-wide company cards (`flex gap-4 overflow-x-auto`): a white 4:3 logo panel with the name
/// under it, then the company name and its project count below the panel.
class DevelopersSlider extends StatefulWidget {
  const DevelopersSlider({super.key, required this.developers});

  final List<DeveloperSummary> developers;

  @override
  State<DevelopersSlider> createState() => _DevelopersSliderState();
}

class _DevelopersSliderState extends State<DevelopersSlider> {
  final _scroll = ScrollController();

  static const _cardWidth = 200.0;
  static const _gap = 16.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool get _canLeft => _scroll.hasClients && _scroll.offset > 0;
  bool get _canRight => _scroll.hasClients && _scroll.offset < _scroll.position.maxScrollExtent - 1;

  void _scrollBy(double delta) => _scroll.animateTo(
    (_scroll.offset + delta).clamp(0.0, _scroll.position.maxScrollExtent),
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: AppColors.cream,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40), // py-10
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "O'zbekistondagi qurilish kompaniyalar bo'yicha loyihalar",
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 24,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ArrowButton(
                    icon: Icons.chevron_left,
                    enabled: _canLeft,
                    onPressed: () => _scrollBy(-(_cardWidth + _gap)),
                  ),
                  const SizedBox(width: 8),
                  _ArrowButton(
                    icon: Icons.chevron_right,
                    enabled: _canRight,
                    onPressed: () => _scrollBy(_cardWidth + _gap),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40), // mb-10
            if (widget.developers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Loyihachilar topilmadi',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                // 4:3 logo panel (150) + 16 gap + two lines of text.
                height: 150 + 16 + 48,
                child: ListView.separated(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.developers.length,
                  separatorBuilder: (_, _) => const SizedBox(width: _gap),
                  itemBuilder: (context, i) =>
                      _DeveloperCard(developer: widget.developers[i], width: _cardWidth),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.enabled, required this.onPressed});

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.olive : AppColors.dark.withValues(alpha: 0.2);
    return InkWell(
      onTap: enabled ? onPressed : null,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard({required this.developer, required this.width});

  final DeveloperSummary developer;
  final double width;

  /// A stable colour per company, so the placeholder does not change between builds.
  (Color, Color) get _avatarColors {
    final hue = (developer.name.hashCode.abs() % 360).toDouble();
    return (
      HSLColor.fromAHSL(1, hue, 0.35, 0.88).toColor(),
      HSLColor.fromAHSL(1, hue, 0.45, 0.32).toColor(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logo = absoluteMediaUrl(developer.logo);
    final (background, foreground) = _avatarColors;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150, // aspect-[4/3] at 200px wide
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.dark.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: logo == null
                      ? Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              developer.initial,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      : AppImage(
                          imageUrl: logo,
                          fit: BoxFit.contain,
                          errorWidget: (_, _, _) =>
                              Icon(Icons.business, color: AppColors.dark.withValues(alpha: 0.3)),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  developer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            developer.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(color: AppColors.dark),
          ),
          Text(
            '${developer.projectsCount} ta loyiha',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
