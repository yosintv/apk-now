import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/match.dart';
import '../../providers/matches_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/match_card.dart';
import '../../widgets/news_card.dart';
import '../../widgets/ad_banner_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getTournamentMetadata(String? leagueName, String sport) {
    if (leagueName == null) {
      return {'label': sport == 'cricket' ? 'Cricket' : 'Football', 'icon': sport == 'cricket' ? Icons.sports_cricket : Icons.sports_soccer};
    }
    final name = leagueName.toLowerCase();
    if (name.contains('ipl') || name.contains('premier league')) {
      return {'label': 'IPL', 'icon': Icons.sports_cricket};
    } else if (name.contains('t20') || name.contains('world cup')) {
      return {'label': 'World Cup', 'icon': Icons.sports_cricket};
    } else if (name.contains('la liga') || name.contains('laliga')) {
      return {'label': 'La Liga', 'icon': Icons.sports_soccer};
    } else if (name.contains('champions league') || name.contains('ucl')) {
      return {'label': 'UCL', 'icon': Icons.sports_soccer};
    }
    return {
      'label': sport == 'cricket' ? 'Cricket' : 'Football',
      'icon': sport == 'cricket' ? Icons.sports_cricket : Icons.sports_soccer
    };
  }

  List<Match> _getFilteredMatches(List<Match> matches) {
    return matches.where((m) {
      final matchesSearch = m.teamA.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.teamB.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (m.leagueName.toLowerCase().contains(_searchQuery.toLowerCase()));
      if (!matchesSearch) return false;
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Cricket') return m.sport == 'cricket';
      if (_selectedFilter == 'Football') return m.sport == 'football';
      final meta = _getTournamentMetadata(m.leagueName, m.sport);
      return meta['label'] == _selectedFilter;
    }).toList();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_soccer_outlined, size: 80, color: AppColors.textSecondary.withOpacity(0.2)),
              const SizedBox(height: 16),
              const Text(
                'No matches found',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final footballAsync = ref.watch(footballMatchesProvider);
    final cricketAsync = ref.watch(cricketMatchesProvider);
    final articlesAsync = ref.watch(articlesProvider);

    final football = footballAsync.value ?? [];
    final cricket = cricketAsync.value ?? [];
    final List<Match> allMatches = [...football, ...cricket];

    allMatches.sort((a, b) {
      final aStatus = a.status;
      final bStatus = b.status;
      if (aStatus == bStatus) {
        if (aStatus == MatchStatus.upcoming) {
          final ta = a.countdown;
          final tb = b.countdown;
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return ta.compareTo(tb);
        }
        return 0;
      }
      return aStatus.index.compareTo(bStatus.index);
    });

    final filteredMatches = _getFilteredMatches(allMatches);
    final liveCount = filteredMatches.where((m) => m.status == MatchStatus.live).length;

    final List<String> filterLabels = ['All', 'Cricket', 'Football'];
    final Set<String> seenLeagues = {};
    for (var m in allMatches) {
      final meta = _getTournamentMetadata(m.leagueName, m.sport);
      final label = meta['label'] as String?;
      if (label != null && !seenLeagues.contains(label) && label != 'Cricket' && label != 'Football') {
        filterLabels.add(label);
        seenLeagues.add(label);
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
              // ── Greeting + Search ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Text(
                                'Explore Matches',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                              ],
                            ),
                            child: Image.asset('assets/logo.png', height: 40),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSearchField(),
                    ],
                  ),
                ),
              ),

              // ── Filter chips ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _buildFilterChips(filterLabels, allMatches),
                ),
              ),

              // ── "Live & Upcoming" section header ───────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Text(
                        'Live & Upcoming',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      if (liveCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.circle, color: Colors.white, size: 6),
                              const SizedBox(width: 4),
                              Text(
                                '$liveCount LIVE',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      if (filteredMatches.isNotEmpty)
                        Text(
                          '${filteredMatches.length} Matches',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Match list ─────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                sliver: filteredMatches.isEmpty
                    ? _buildEmptyState()
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index > 0 && (index + 1) % 4 == 0) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: AdBannerWidget(),
                              );
                            }
                            final dataIndex = index - (index ~/ 4);
                            if (dataIndex < 0 || dataIndex >= filteredMatches.length) return null;
                            return _buildMatchCard(filteredMatches[dataIndex]);
                          },
                          childCount: filteredMatches.length + (filteredMatches.length ~/ 3),
                        ),
                      ),
              ),

              // ── Latest News header ─────────────────────────────────────
              if (articles.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                    child: const Text(
                      'Latest News',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                ),

                // ── News vertical list ─────────────────────────────────
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= articles.take(5).length) return null;
                      final article = articles[index];
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
                    childCount: articles.take(5).length,
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

  Widget _buildFilterChips(List<String> labels, List<Match> allMatches) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        itemBuilder: (context, index) {
          final label = labels[index];
          final isSelected = _selectedFilter == label;

          Match? sampleMatch;
          try {
            sampleMatch = allMatches.firstWhere(
              (m) => _getTournamentMetadata(m.leagueName, m.sport)['label'] == label,
            );
          } catch (_) {}

          final sport = sampleMatch?.sport ?? (label == 'Cricket' ? 'cricket' : 'football');
          final icon = _getTournamentMetadata(label, sport)['icon'];

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedFilter = isSelected ? 'All' : label),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                    else
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFF1F3F5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: const Color(0xFFF1F3F5), width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          hintText: 'Search teams or tournaments...',
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    final matchStatus = match.status;
    String statusText = 'Starting Soon';
    if (matchStatus == MatchStatus.live) statusText = 'LIVE';
    if (matchStatus == MatchStatus.fullTime) statusText = 'Match Finished';

    String timeText = match.time ?? '';
    if (matchStatus == MatchStatus.upcoming) {
      final cd = match.countdown;
      if (cd != null) {
        timeText = 'Starts in ${cd.inHours}h ${cd.inMinutes % 60}m';
      }
    }

    return GestureDetector(
      onTap: () => context.push('/match-detail', extra: match),
      child: MatchCard(
        leagueName: match.leagueName,
        teamALogo: match.teamALogo,
        teamAName: match.teamA,
        teamBLogo: match.teamBLogo,
        teamBName: match.teamB,
        matchDateTime: timeText,
        stadiumName: match.stadium ?? 'TBD',
        matchStatus: statusText,
      ),
    );
  }
}
