import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/match_card.dart';
import '../widgets/news_card.dart';
import '../providers/matches_provider.dart';
import '../widgets/ad_banner_widget.dart';
import '../models/match.dart';
import '../models/article.dart';

class FootballScreen extends ConsumerStatefulWidget {
  const FootballScreen({super.key});

  @override
  ConsumerState<FootballScreen> createState() => _FootballScreenState();
}

class _FootballScreenState extends ConsumerState<FootballScreen>
    with AutomaticKeepAliveClientMixin {
  String _selectedFilter = 'All';

  @override
  bool get wantKeepAlive => true;

  String _leagueLabel(String name) {
    final n = name.toLowerCase();
    if (n.contains('premier league')) return 'PL';
    if (n.contains('serie a')) return 'Serie A';
    if (n.contains('la liga') || n.contains('laliga')) return 'La Liga';
    if (n.contains('champions league') || n.contains('ucl')) return 'UCL';
    if (n.contains('europa league') || n.contains('uel')) return 'UEL';
    if (n.contains('sudamericana') || n.contains('conmebol')) return 'Sudamericana';
    if (n.contains('fifa') || n.contains('world cup')) return 'FIFA WC';
    String label = name;
    if (name.contains(',')) label = name.split(',')[0];
    return label.length > 16 ? '${label.substring(0, 14)}..' : label;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final matchesAsync = ref.watch(footballMatchesProvider);
    final articlesAsync = ref.watch(articlesProvider);
    final articles = articlesAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: matchesAsync.when(
        data: (allMatches) {
          final filterLabels = ['All'];
          final seen = <String>{};
          for (final m in allMatches) {
            final lbl = _leagueLabel(m.leagueName);
            if (seen.add(lbl)) filterLabels.add(lbl);
          }

          final filtered = _selectedFilter == 'All'
              ? allMatches
              : allMatches
                  .where((m) => _leagueLabel(m.leagueName) == _selectedFilter)
                  .toList();

          final liveCount =
              filtered.where((m) => m.status == MatchStatus.live).length;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(footballMatchesProvider);
              ref.invalidate(articlesProvider);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildTopBar(liveCount, filtered.length, filterLabels),
                ),

                if (allMatches.isEmpty) ...[
                  // No matches — show news instead of blank screen
                  ..._buildNewsSlivers(articles, emptyMode: true),
                ] else if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: _emptyState(Icons.filter_list_off_rounded,
                        'No matches for this filter'),
                  )
                else if (_selectedFilter == 'All')
                  ..._buildGroupedSlivers(filtered, articles)
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8),
                    sliver: _buildFlatList(filtered),
                  ),
                  ..._buildNewsSlivers(articles),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2.5),
        ),
        error: (_, __) => _errorState(),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(int liveCount, int total, List<String> filterLabels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF001A40), Color(0xFF003566)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                child: const Icon(Icons.sports_soccer_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Football',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      liveCount > 0
                          ? '$liveCount LIVE · $total matches'
                          : '$total matches available',
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (liveCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.live,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.live.withValues(alpha: 0.40),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, color: Colors.white, size: 6),
                      const SizedBox(width: 5),
                      Text(
                        '$liveCount LIVE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildFilterChips(filterLabels),
        ),
      ],
    );
  }

  Widget _buildFilterChips(List<String> labels) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        itemBuilder: (context, index) {
          final label = labels[index];
          final selected = _selectedFilter == label;
          return GestureDetector(
            onTap: () =>
                setState(() => _selectedFilter = selected ? 'All' : label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 1.2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : const [],
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color:
                        selected ? Colors.white : AppColors.textSecondary,
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

  // ── Match list builders ────────────────────────────────────────────────────

  List<Widget> _buildGroupedSlivers(
      List<Match> matches, List<Article> articles) {
    final Map<String, List<Match>> groups = {};
    for (final m in matches) {
      groups.putIfAbsent(m.leagueName, () => []).add(m);
    }

    final slivers = <Widget>[];
    int adCounter = 0;

    for (final entry in groups.entries) {
      for (final match in entry.value) {
        slivers.add(SliverToBoxAdapter(child: _matchTile(match)));
        adCounter++;
        if (adCounter % 3 == 0) {
          slivers.add(const SliverToBoxAdapter(child: AdBannerWidget()));
        }
      }
    }

    slivers.addAll(_buildNewsSlivers(articles));
    return slivers;
  }

  SliverList _buildFlatList(List<Match> matches) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index > 0 && index % 3 == 0) {
            return const AdBannerWidget();
          }
          final di = index - (index ~/ 3);
          if (di < 0 || di >= matches.length) return null;
          return _matchTile(matches[di]);
        },
        childCount: matches.length + (matches.length ~/ 3),
      ),
    );
  }

  Widget _matchTile(Match match) {
    final isLive = match.status == MatchStatus.live;
    final isFinished = match.status == MatchStatus.fullTime;

    String statusText = 'UPCOMING';
    if (isLive) statusText = 'LIVE';
    if (isFinished) statusText = 'Match Finished';

    String timeText = match.time ?? '';
    if (match.status == MatchStatus.upcoming) {
      final cd = match.countdown;
      if (cd != null) {
        timeText = cd.inHours > 0
            ? '${cd.inHours}h ${cd.inMinutes % 60}m'
            : '${cd.inMinutes}m';
      }
    }

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => context.push('/match-detail', extra: match),
        child: MatchCard(
          leagueName: match.leagueName,
          leagueLogo: match.leagueLogo,
          teamALogo: match.teamALogo,
          teamAName: match.teamA,
          teamBLogo: match.teamBLogo,
          teamBName: match.teamB,
          matchDateTime: timeText,
          stadiumName: match.stadium ?? 'TBD',
          matchStatus: statusText,
          scoreA: match.scoreA,
          scoreB: match.scoreB,
          minute: match.minute,
          sport: match.sport,
        ),
      ),
    );
  }

  // ── News section ───────────────────────────────────────────────────────────

  List<Widget> _buildNewsSlivers(List<Article> articles,
      {bool emptyMode = false}) {
    if (articles.isEmpty) {
      if (emptyMode) {
        return [
          SliverFillRemaining(
            child: _emptyState(
                Icons.sports_soccer_rounded, 'No football matches today'),
          )
        ];
      }
      return [const SliverToBoxAdapter(child: SizedBox(height: 24))];
    }

    final limited = articles.take(6).toList();
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Latest News',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => RepaintBoundary(
            child: GestureDetector(
              onTap: () => ctx.push('/article-detail', extra: limited[i]),
              child: NewsCard(
                title: limited[i].title,
                category: limited[i].category,
                timestamp: limited[i].relativeTime,
                logoUrl: limited[i].imageUrl ?? '',
              ),
            ),
          ),
          childCount: limited.length,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }

  // ── Empty / error states ───────────────────────────────────────────────────

  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 64, color: AppColors.textMuted.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

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
              'Failed to load matches',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Check your connection and try again',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(footballMatchesProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
