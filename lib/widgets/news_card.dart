import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Dark blue square with white YoSinTV logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A), // Dark blue container
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                // Placeholder for YoSinTV Logo
                child: logoUrl.isNotEmpty
                    ? Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.tv, color: Color(0xFF0D1B2A)),
                      )
                    : const Icon(
                        Icons.live_tv,
                        color: Color(0xFF0D1B2A),
                        size: 32,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Right side: Flexible vertical text column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Metadata row
                Row(
                  children: [
                    // Category
                    const Icon(Icons.article_outlined, size: 14, color: Color(0xFF6C757D)),
                    const SizedBox(width: 4),
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C757D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Timestamp
                    const Icon(Icons.access_time, size: 14, color: Color(0xFF6C757D)),
                    const SizedBox(width: 4),
                    Text(
                      timestamp,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
