import 'package:flutter/material.dart';

import '../data/dtos/anime_item_dto.dart';
import '../utils/proxied_image.dart';


/// Card compacto de anime para listas horizontais.
/// Exibe cover, título e score.
class AnimeCard extends StatelessWidget {
  const AnimeCard({
    super.key,
    required this.anime,
    this.width = 140,
    this.onTap,
  });

  final AnimeItemDto anime;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroTag = 'anime-cover-${anime.source}-${anime.externalId ?? anime.id}';
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image with Hero animation
            Hero(
              tag: heroTag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: anime.coverUrl != null
                      ? ProxiedImage(
                          src: anime.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _PlaceholderCover(theme: theme),
                        )
                      : _PlaceholderCover(theme: theme),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              anime.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            // Score
            if (anime.score != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                  const SizedBox(width: 2),
                  Text(
                    anime.score!.toStringAsFixed(1),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 36,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
