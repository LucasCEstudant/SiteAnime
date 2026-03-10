import 'package:flutter/material.dart';

import 'shimmer_box.dart';

/// Skeleton shimmer para cards de anime em lista horizontal.
/// Simula o layout do [AnimeCard] enquanto os dados carregam.
class AnimeCardSkeleton extends StatelessWidget {
  const AnimeCardSkeleton({super.key, this.width = 140});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: ShimmerBox(borderRadius: 0),
            ),
          ),
          const SizedBox(height: 6),
          // Title line 1
          ShimmerBox(height: 12, width: width * 0.85, borderRadius: 4),
          const SizedBox(height: 4),
          // Title line 2
          ShimmerBox(height: 12, width: width * 0.55, borderRadius: 4),
          const SizedBox(height: 4),
          // Score
          ShimmerBox(height: 10, width: 40, borderRadius: 4),
        ],
      ),
    );
  }
}
