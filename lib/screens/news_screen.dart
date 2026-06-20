import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/news_card.dart';
import '../providers/matches_provider.dart';
import '../widgets/ad_banner_widget.dart';
import '../models/article.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  String _selectedCategory = 'All';

  static const _gradientStart = Color(0xFF1A0533);
  static const _gradientEnd = Color(0xFF5B21B6);

  static const _categories = ['All', 'Football', 'Cricket', 'Transfer', 'Injury'];

  List<Article> _filterArticles(List<Article> all) {
    if (_selectedCategory == 'All') return all;
    return all
        .where((a) =>
            a.category.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final articlesAsync = ref.watch(articlesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: articlesAsync.when(
        data: (allArticles) {
          final articles = _filterArticles(allArticles);

          return RefreshIndicator(
            color: AppColors.news,
            onRefresh: () async => ref.invalidate(articlesProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Sport identity header ──────────────────────────────
                SliverToBoxAdapter(
                  child: _buildHeader(allArticles.length),
                ),

                // ── Category filter tabs ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildCategoryFilters(allArticles),
                  ),
                ),

                if (allArticles.isEmpty)
                  SliverFillRemaining(
                    child: _emptyState(
                      Icons.newspaper_outlined,
                      'No stories yet',
                      'Check back soon for the latest sports news',
                    ),
                  )
                else if (articles.isEmpty)
                  SliverFillRemaining(
                    child: _emptyState(
                      Icons.filter_list_off_rounded,
                      'No $_selectedCategory articles',
                      'Try a different category',
                    ),
                  )
                else ...[
                  // ── Section label ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: _sectionHeader(articles.length),
                    ),
                  ),

                  // ── Featured article ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: GestureDetector(
                      onTap: () => context.push(
                          '/article-detail', extra: articles.first),
                      child: NewsCard(
                        title: articles.first.title,
                        category: articles.first.category,
                        timestamp: articles.first.relativeTime,
                        logoUrl: articles.first.imageUrl ?? '',
                        featured: true,
                      ),
                    ),
                  ),

                  // ── Compact list (remaining) ─────────────────────────
                  if (articles.length > 1)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          // Ad every 4 compact items
                          if (index > 0 && index % 5 == 4) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: AdBannerWidget(),
                            );
                          }
                          final dataIndex =
                              index - (index ~/ 5);
                          final articleIndex = dataIndex + 1;
                          if (articleIndex >= articles.length) return null;
                          final article = articles[articleIndex];
                          return GestureDetector(
                            onTap: () => context.push(
                                '/article-detail', extra: article),
                            child: NewsCard(
                              title: article.title,
                              category: article.category,
                              timestamp: article.relativeTime,
                              logoUrl: article.imageUrl ?? '',
                            ),
                          );
                        },
                        childCount: (articles.length - 1) +
                            ((articles.length - 1) ~/ 4),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            ),
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.news.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  color: AppColors.news,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading stories...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        error: (_, __) => _errorState(),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.news.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.newspaper_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sports News',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  count > 0
                      ? '$count stories available'
                      : 'Football & Cricket coverage',
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 14),
                SizedBox(width: 5),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Category filter chips ──────────────────────────────────────────────────

  Widget _buildCategoryFilters(List<Article> all) {
    // Only show categories that have articles
    final available = <String>{'All'};
    for (final a in all) {
      final c = a.category;
      if (c.isNotEmpty) {
        final norm = c[0].toUpperCase() + c.substring(1).toLowerCase();
        if (_categories.contains(norm)) available.add(norm);
      }
    }
    final labels = _categories.where(available.contains).toList();

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        itemBuilder: (context, index) {
          final label = labels[index];
          final selected = _selectedCategory == label;
          return GestureDetector(
            onTap: () => setState(
                () => _selectedCategory = selected ? 'All' : label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? AppColors.news : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppColors.news : AppColors.border,
                  width: 1.2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.news.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────

  Widget _sectionHeader(int count) {
    return Row(
      children: [
        const Icon(Icons.local_fire_department_rounded,
            size: 18, color: AppColors.news),
        const SizedBox(width: 7),
        const Text(
          'Latest Stories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.news.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.news,
            ),
          ),
        ),
        const Spacer(),
        if (_selectedCategory != 'All')
          GestureDetector(
            onTap: () => setState(() => _selectedCategory = 'All'),
            child: const Row(
              children: [
                Text(
                  'All stories',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.news,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 10, color: AppColors.news),
              ],
            ),
          ),
      ],
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.news.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 40, color: AppColors.news.withValues(alpha: 0.25)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ─────────────────────────────────────────────────────────────

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.live.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: AppColors.live, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load news',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Check your connection and try again',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(articlesProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.news,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
