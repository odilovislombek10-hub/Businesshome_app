import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/api/media_url.dart';
import '../../core/models/project.dart';

/// The site's `property-card` for a new-build project — used both in the `/new-projects` list and
/// in the home page's "featured buildings" strip, which is why it lives in `shared/`.
class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, this.onTap, this.width});

  final Project project;
  final VoidCallback? onTap;

  /// Set when the card sits in a horizontal strip; null lets it fill the column.
  final double? width;

  static final _money = NumberFormat.decimalPattern('uz');

  /// The API stores status as a slug; these are the labels the website prints.
  static String statusLabel(String status) => switch (status) {
        'rejada' => 'Rejada',
        'qurilmoqda' => 'Qurilmoqda',
        'tugallangan' => 'Tugallangan',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = absoluteMediaUrl(project.thumbnail);

    final card = Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: image == null
                  ? Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.apartment,
                          size: 48, color: theme.colorScheme.onSurfaceVariant),
                    )
                  : CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: theme.colorScheme.surfaceContainerHighest),
                      errorWidget: (_, _, _) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (project.isTop)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'TOP',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (project.developer?.name != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      project.developer!.name!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (project.locationLabel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.place_outlined,
                            size: 15, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project.locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (project.status != null) _Chip(text: statusLabel(project.status!)),
                      if (project.totalApartments != null)
                        _Chip(text: '${project.totalApartments} xonadon'),
                      if (project.totalBlocks != null) _Chip(text: '${project.totalBlocks} blok'),
                      if (project.minPrice != null)
                        _Chip(text: '${_money.format(project.minPrice)} so\'m dan'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return width == null ? card : SizedBox(width: width, child: card);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.chipTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(text, style: theme.textTheme.labelSmall),
    );
  }
}
