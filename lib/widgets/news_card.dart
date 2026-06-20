import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NewsCard extends StatelessWidget {
  final String title;
  final String category;
  final String timestamp;
  final String logoUrl;
  final bool featured;

  const NewsCard({
    super.key,
    required this.title,
    required this.category,
    required this.timestamp,
    this.logoUrl = '',
    this.featured = false,
  });

  Color _catColor() {
    switch (category.toLowerCase()) {
      case 'football':
        return AppColors.football;
      case 'cricket':
        return AppColors.cricket;
      case 'transfer':
      case 'transfers':
        return const Color(0xFF6D28D9);
      case 'injury':
      case 'injuries':
        return AppColors.live;
      default:
        return AppColors.football;
    }
  }

  @override
  Widget build(BuildContext context) {
    return featured ? _buildFeatured() : _buildCompact();
  }

  // ── Featured: large card with full-width top image ─────────────────────────

  Widget _buildFeatured() {
    final color = _catColor();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with category badge overlay
            Stack(
              children: [
                SizedBox(
                  height: 182,
                  width: double.infinity,
                  child: logoUrl.isNotEmpty
                      ? Image.network(
                          logoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(color, 182),
                        )
                      : _imagePlaceholder(color, 182),
                ),
                // Gradient scrim at bottom of image
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Category badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Text content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        timestamp,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Read more',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded,
                          size: 13, color: color),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Compact: horizontal card, thumbnail right, left accent bar ─────────────

  Widget _buildCompact() {
    final color = _catColor();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent line
              Container(width: 3, color: color),

              // Text content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 10, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            timestamp,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Right thumbnail
              SizedBox(
                width: 92,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(14)),
                  child: logoUrl.isNotEmpty
                      ? Image.network(
                          logoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(color, double.infinity),
                        )
                      : _imagePlaceholder(color, double.infinity),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(Color color, double height) {
    return Container(
      height: height == double.infinity ? null : height,
      color: const Color(0xFF06113D),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.live_tv_rounded,
              color: Colors.white.withValues(alpha: 0.25),
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}
