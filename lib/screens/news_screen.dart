import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/news_card.dart';
import '../providers/matches_provider.dart';
import '../widgets/ad_banner_widget.dart';
import '../models/article.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(articlesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Sports News',
          style: TextStyle(
            color: AppColors.primary, 
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
        ),
      ),
      body: articlesAsync.when(
        data: (articles) {
          if (articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.newspaper_rounded, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'No news available right now.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(articlesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: articles.length + (articles.length ~/ 3),
              itemBuilder: (context, index) {
                if (index > 0 && (index + 1) % 4 == 0) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: AdBannerWidget(),
                  );
                }

                final dataIndex = index - (index ~/ 4);
                final Article article = articles[dataIndex];

                return InkWell(
                  onTap: () => context.push('/article-detail', extra: article),
                  child: NewsCard(
                    title: article.title,
                    category: article.category,
                    timestamp: article.relativeTime,
                    logoUrl: article.imageUrl ?? '',
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.accent, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Failed to load news',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(articlesProvider),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
