import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NewsCard extends StatelessWidget {
  final String title;
  final String category;
  final String timestamp;
  final String logoUrl;

  const NewsCard({
    super.key,
    required this.title,
    required this.category,
    required this.timestamp,
    this.logoUrl = '',
  });

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'football': return const Color(0xFF003566);
      case 'cricket':  return const Color(0xFF1B5E35);
      case 'transfer':
      case 'transfers': return const Color(0xFF6A0DAD);
      case 'injury':
      case 'injuries': return const Color(0xFFE63946);
      default:         return const Color(0xFF003566);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ────────────────────────────────────────────
            if (logoUrl.isNotEmpty)
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Image.network(
                  logoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(catColor),
                ),
              )
            else
              _buildPlaceholder(catColor),

            // ── Content ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge + timestamp row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: catColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: catColor, letterSpacing: 0.5),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        timestamp,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // Read more row
                  Row(
                    children: [
                      Text(
                        'Read more',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: catColor),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: catColor),
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

  Widget _buildPlaceholder(Color catColor) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [catColor.withOpacity(0.08), catColor.withOpacity(0.03)],
        ),
      ),
      child: Center(
        child: Icon(Icons.article_rounded, size: 44, color: catColor.withOpacity(0.25)),
      ),
    );
  }
}
