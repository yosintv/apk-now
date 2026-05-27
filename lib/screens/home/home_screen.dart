import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/match_card.dart';
import '../../providers/matches_provider.dart';
import '../../models/match.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../services/ad_service.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';

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

  Map<String, dynamic> _getTournamentMetadata(String name, String sport) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('indian premier league') || lowerName == 'ipl') {
      return {'label': 'IPL', 'icon': Icons.sports_cricket_rounded};
    }
    if (lowerName.contains('premier league') || lowerName == 'pl') {
      return {'label': 'PL', 'icon': Icons.sports_soccer_rounded};
    }
    if (lowerName.contains('serie a') || lowerName == 'sa') {
      return {'label': 'SA', 'icon': Icons.shield_rounded};
    }
    if (lowerName.contains('fifa') || lowerName.contains('world cup')) {
      return {'label': 'FIFA', 'icon': Icons.public_rounded};
    }
    if (name == 'Football') {
      return {'label': 'Football', 'icon': Icons.sports_soccer_rounded};
    }
    if (name == 'Cricket') {
      return {'label': 'Cricket', 'icon': Icons.sports_cricket_rounded};
    }

    String label = name;
    if (name.contains(',')) {
      label = name.split(',')[0];
    }
    if (label.length > 12) {
      label = label.substring(0, 10) + '..';
    }

    return {
      'label': label, 
      'icon': sport.toLowerCase() == 'cricket' ? Icons.sports_cricket_rounded : Icons.sports_soccer_rounded
    };
  }

  List<Match> _getFilteredMatches(List<Match> allMatches) {
    return allMatches.where((match) {
      bool matchesFilter = _selectedFilter == 'All';
      if (!matchesFilter) {
        final meta = _getTournamentMetadata(match.leagueName, match.sport);
        matchesFilter = _selectedFilter == meta['label'] || 
                        _selectedFilter == match.leagueName ||
                        _selectedFilter == (match.sport[0].toUpperCase() + match.sport.substring(1));
      }
      final matchesSearch = _searchQuery.isEmpty ||
          match.teamA.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          match.teamB.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          match.leagueName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final footballAsync = ref.watch(footballMatchesProvider);
    final cricketAsync = ref.watch(cricketMatchesProvider);

    final football = footballAsync.value ?? [];
    final cricket = cricketAsync.value ?? [];
    final allMatches = [...football, ...cricket];
    
    allMatches.sort((a, b) {
      if (a.status == b.status) {
        if (a.status == MatchStatus.upcoming) {
          final ta = a.countdown;
          final tb = b.countdown;
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return ta.compareTo(tb);
        }
        return 0;
      }
      return a.status.index.compareTo(b.status.index);
    });

    final filteredMatches = _getFilteredMatches(allMatches);

    final List<String> filterLabels = ['All', 'Cricket', 'Football'];
    final Set<String> seenLeagues = {};
    for (var m in allMatches) {
      final label = _getTournamentMetadata(m.leagueName, m.sport)['label'];
      if (!seenLeagues.contains(label) && label != 'Cricket' && label != 'Football') {
        filterLabels.add(label);
        seenLeagues.add(label);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(footballMatchesProvider);
            ref.invalidate(cricketMatchesProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
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
                                'Good ${DateTime.now().hour < 12 ? 'Morning' : 'Evening'}',
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
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _buildFilterChips(filterLabels, allMatches),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Live & Upcoming',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (filteredMatches.isNotEmpty)
                        Text(
                          '${filteredMatches.length} Matches',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
                sliver: filteredMatches.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyState())
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
                            return _buildMatchCard(filteredMatches[dataIndex]);
                          },
                          childCount: filteredMatches.length + (filteredMatches.length ~/ 3),
                        ),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
          final sampleMatch = allMatches.firstWhere(
            (m) => _getTournamentMetadata(m.leagueName, m.sport)['label'] == label,
            orElse: () => Match(id: '', league: '', leagueName: '', teamA: '', teamALogo: '', teamB: '', teamBLogo: '', channel: '', quality: '', sport: label == 'Cricket' ? 'cricket' : 'football'),
          );
          final icon = _getTournamentMetadata(label, sampleMatch.sport)['icon'];

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
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFF1F3F5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
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
    String statusText = 'Starting Soon';
    if (match.status == MatchStatus.live) statusText = 'LIVE';
    if (match.status == MatchStatus.fullTime) statusText = 'Match Finished';
                
    String timeText = match.time ?? '';
    if (match.status == MatchStatus.upcoming && match.countdown != null) {
      final cd = match.countdown!;
      timeText = 'Starts in ${cd.inHours}h ${cd.inMinutes % 60}m';
    }

    return GestureDetector(
      onTap: () {
        ref.read(adServiceProvider).showInterstitialAd(onAdDismissed: () {
          context.push('/match-detail', extra: match);
        });
      },
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF1F3F5)),
              ),
              child: Icon(Icons.search_off_rounded, size: 40, color: AppColors.textSecondary.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No matches found',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try adjusting your filters or search',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
