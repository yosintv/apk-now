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
      body: articlesAsync.when(
        data: (articles) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(articlesProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── News header ──────────────────────────────────────
                SliverToBoxAdapter(child: _buildNewsHeader(articles.length)),

                if (articles.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.newspaper_rounded, size: 72,
                              color: AppColors.textSecondary.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          const Text(
                            'No news available right now.',
                            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // ── Section label ──────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          const Text('Latest Stories',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          const Spacer(),
                          Text('${articles.length} articles',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),

                  // ── Article list ───────────────────────────────────
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index > 0 && (index + 1) % 4 == 0) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: AdBannerWidget(),
                          );
                        }
                        final dataIndex = index - (index ~/ 4);
                        if (dataIndex < 0 || dataIndex >= articles.length) return null;
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
                      childCount: articles.length + (articles.length ~/ 3),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
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
              const Text('Failed to load news',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(articlesProvider),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsHeader(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0533), Color(0xFF3D0F6B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF3D0F6B).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.newspaper_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sports News',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                Text(
                  count > 0 ? '$count stories available' : 'Latest football & cricket news',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
