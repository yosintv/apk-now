// lib/models/article.dart
// Article / news data model with JSON deserialization.

class Article {
  final String id;
  final String title;
  final String excerpt;
  final String? imageUrl;
  final String category;
  final String publishedAt; // ISO8601 string
  final List<String> content; // Full article content paragraphs
  final String? url;        // Full article URL

  const Article({
    required this.id,
    required this.title,
    required this.excerpt,
    this.imageUrl,
    required this.category,
    required this.publishedAt,
    required this.content,
    this.url,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: (json['slug'] ?? json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      excerpt: (json['snippet'] ?? json['excerpt'] ?? json['description'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? json['thumbnail'])?.toString(),
      category: (json['category'] ?? (json['labels'] is List && (json['labels'] as List).isNotEmpty ? (json['labels'] as List).first.toString() : 'Sports')).toString(),
      publishedAt: (json['publishedAt'] ?? json['published_at'] ?? json['date'] ?? '').toString(),
      content: json['content'] is List 
          ? (json['content'] as List).map((e) => e.toString()).toList() 
          : [],
      url: (json['url'] ?? json['link'])?.toString(),
    );
  }

  /// Human-readable relative time label (e.g. "2h ago", "3d ago").
  String get relativeTime {
    final published = DateTime.tryParse(publishedAt);
    if (published == null) return publishedAt;
    final diff = DateTime.now().difference(published);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
