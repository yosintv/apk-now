import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/match.dart';
import '../../providers/matches_provider.dart';
import '../../providers/config_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/match_card.dart';
import '../../widgets/news_card.dart';
import '../../widgets/ad_banner_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;
  bool _messageDismissed = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _leagueLabel(String name, String sport) {
    final n = name.toLowerCase();
    if (n.contains('indian premier league') || n == 'ipl') return 'IPL';
    if (n.contains('world cup') && sport == 'cricket') return 'World Cup';
    if (n.contains('premier league') && sport == 'football') return 'PL';
    if (n.contains('champions league') || n.contains('ucl')) return 'UCL';
    if (n.contains('la liga') || n.contains('laliga')) return 'La Liga';
    return sport == 'cricket' ? 'Cricket' : 'Football';
  }

  List<Match> _applyFilter(List<Match> all) {
    return all.where((m) {
      final q = _searchQuery.toLowerCase();
      if (q.isNotEmpty) {
        if (!m.teamA.toLowerCase().contains(q) &&
            !m.teamB.toLowerCase().contains(q) &&
            !m.leagueName.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Cricket') return m.sport == 'cricket';
      if (_selectedFilter == 'Football') return m.sport == 'football';
      return _leagueLabel(m.leagueName, m.sport) == _selectedFilter;
    }).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final footballAsync = ref.watch(footballMatchesProvider);
    final cricketAsync = ref.watch(cricketMatchesProvider);
    final articlesAsync = ref.watch(articlesProvider);
    final config = ref.watch(configProvider);

    final football = footballAsync.value ?? [];
    final cricket = cricketAsync.value ?? [];
    final allMatches = [...football, ...cricket];

    // Sort: LIVE → UPCOMING (soonest first) → FINISHED
    allMatches.sort((a, b) {
      if (a.status != b.status) {
        return a.status.index.compareTo(b.status.index);
      }
      if (a.status == MatchStatus.upcoming) {
        final ta = a.countdown, tb = b.countdown;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return ta.compareTo(tb);
      }
      return 0;
    });

    final filtered = _applyFilter(allMatches);
    final liveMatches =
        filtered.where((m) => m.status == MatchStatus.live).toList();
    final nonLiveMatches =
        filtered.where((m) => m.status != MatchStatus.live).toList();
    final upcomingCount =
        filtered.where((m) => m.status == MatchStatus.upcoming).length;

    // Build filter label list
    final filters = ['All', 'Cricket', 'Football'];
    final seenLabels = <String>{};
    for (final m in allMatches) {
      final lbl = _leagueLabel(m.leagueName, m.sport);
      if (lbl != 'Cricket' && lbl != 'Football' && seenLabels.add(lbl)) {
        filters.add(lbl);
      }
    }

    final articles = articlesAsync.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(footballMatchesProvider);
            ref.invalidate(cricketMatchesProvider);
            ref.invalidate(articlesProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Stats bar ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildStatsBar(
                      liveMatches.length, upcomingCount, filtered.length),
                ),
              ),

              // ── Search ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildSearch(),
                ),
              ),

              // ── Filter chips ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _buildFilters(filters),
                ),
              ),

              // ── App message banner ─────────────────────────────────────
              if (config.appMessageEnabled &&
                  config.appMessage.isNotEmpty &&
                  !_messageDismissed)
                SliverToBoxAdapter(
                  child: _buildAppMessage(
                      config.appMessage, config.appMessageType),
                ),

              // ── LIVE NOW section ───────────────────────────────────────
              if (liveMatches.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                    child: _sectionHeader(
                      icon: Icons.circle,
                      label: 'Live Now',
                      iconColor: AppColors.live,
                      count: liveMatches.length,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _matchTile(liveMatches[i]),
                    childCount: liveMatches.length,
                  ),
                ),
              ],

              // ── UPCOMING section ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      16, liveMatches.isEmpty ? 18 : 22, 16, 10),
                  child: _sectionHeader(
                    icon: Icons.schedule_rounded,
                    label: liveMatches.isEmpty ? 'Live & Upcoming' : 'Upcoming',
                    iconColor: AppColors.upcoming,
                    count: nonLiveMatches.length,
                  ),
                ),
              ),

              if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: _emptyState(
                    icon: Icons.sports_soccer_outlined,
                    label: 'No matches found',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, index) {
                      if (index > 0 && index % 3 == 0) {
                        return const AdBannerWidget();
                      }
                      final di = index - (index ~/ 3);
                      if (di < 0 || di >= nonLiveMatches.length) return null;
                      return _matchTile(nonLiveMatches[di]);
                    },
                    childCount:
                        nonLiveMatches.length + (nonLiveMatches.length ~/ 3),
                  ),
                ),

              // ── Latest News ────────────────────────────────────────────
              if (articles.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: _sectionHeader(
                      icon: Icons.newspaper_rounded,
                      label: 'Latest News',
                      iconColor: AppColors.news,
                    ),
                  ),
                ),

                // Featured article
                SliverToBoxAdapter(
                  child: InkWell(
                    onTap: () =>
                        context.push('/article-detail', extra: articles.first),
                    child: NewsCard(
                      title: articles.first.title,
                      category: articles.first.category,
                      timestamp: articles.first.relativeTime,
                      logoUrl: articles.first.imageUrl ?? '',
                      featured: true,
                    ),
                  ),
                ),

                // Compact list (next 4)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      if (i >= articles.length - 1) return null;
                      final article = articles[i + 1];
                      return InkWell(
                        onTap: () =>
                            context.push('/article-detail', extra: article),
                        child: NewsCard(
                          title: article.title,
                          category: article.category,
                          timestamp: article.relativeTime,
                          logoUrl: article.imageUrl ?? '',
                        ),
                      );
                    },
                    childCount: (articles.length - 1).clamp(0, 4),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildStatsBar(int liveCount, int upcomingCount, int total) {
    return Row(
      children: [
        _statPill(color: AppColors.live, count: liveCount, label: 'LIVE'),
        const SizedBox(width: 10),
        _statPill(
            color: AppColors.upcoming,
            count: upcomingCount,
            label: 'UPCOMING'),
        const Spacer(),
        Text(
          '$total Matches',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _statPill(
      {required Color color, required int count, required String label}) {
    final active = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              active ? color.withValues(alpha: 0.25) : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: active ? color : AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: active ? color : AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textMuted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          hintText: 'Search teams, leagues...',
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilters(List<String> labels) {
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
                    : [],
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

  Widget _sectionHeader({
    required IconData icon,
    required String label,
    required Color iconColor,
    int? count,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        if (count != null && count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: iconColor,
              ),
            ),
          ),
        ],
      ],
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

    return GestureDetector(
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
    );
  }

  Widget _buildAppMessage(String message, String type) {
    final Color bg, accent;
    final IconData icon;
    switch (type.toLowerCase()) {
      case 'warning':
        bg     = const Color(0xFFFFFBEB);
        accent = const Color(0xFFF59E0B);
        icon   = Icons.warning_amber_rounded;
        break;
      case 'success':
        bg     = const Color(0xFFECFDF5);
        accent = const Color(0xFF10B981);
        icon   = Icons.check_circle_outline_rounded;
        break;
      case 'error':
        bg     = const Color(0xFFFEF2F2);
        accent = const Color(0xFFEF4444);
        icon   = Icons.error_outline_rounded;
        break;
      default: // info
        bg     = const Color(0xFFEFF6FF);
        accent = AppColors.primary;
        icon   = Icons.info_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: accent,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _messageDismissed = true),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: accent.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textMuted.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            label,
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
}
