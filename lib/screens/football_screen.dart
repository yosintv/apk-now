import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/match_card.dart';
import '../providers/matches_provider.dart';
import '../widgets/ad_banner_widget.dart';
import '../models/match.dart';

class FootballScreen extends ConsumerStatefulWidget {
  const FootballScreen({super.key});

  @override
  ConsumerState<FootballScreen> createState() => _FootballScreenState();
}

class _FootballScreenState extends ConsumerState<FootballScreen> {
  String _selectedFilter = 'All';

  Map<String, dynamic> _getTournamentMetadata(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('premier league') || lowerName == 'pl') {
      return {'label': 'PL', 'icon': Icons.sports_soccer_rounded};
    }
    if (lowerName.contains('serie a') || lowerName == 'sa') {
      return {'label': 'SA', 'icon': Icons.shield_rounded};
    }
    if (lowerName.contains('sudamericana') || lowerName.contains('conmebol')) {
      return {'label': 'Sudamericana', 'icon': Icons.emoji_events_rounded};
    }
    if (lowerName.contains('fifa') || lowerName.contains('world cup')) {
      return {'label': 'FIFA', 'icon': Icons.public_rounded};
    }
    String label = name;
    if (name.contains(',')) label = name.split(',')[0];
    if (label.length > 15) label = '${label.substring(0, 13)}..';
    return {'label': label, 'icon': Icons.sports_soccer_rounded};
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(footballMatchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: matchesAsync.when(
        data: (allMatches) {
          final List<String> filterLabels = ['All'];
          final Set<String> seenLabels = {};
          for (var m in allMatches) {
            final label = _getTournamentMetadata(m.leagueName)['label'] as String;
            if (!seenLabels.contains(label)) {
              filterLabels.add(label);
              seenLabels.add(label);
            }
          }

          final filteredMatches = allMatches.where((m) {
            if (_selectedFilter == 'All') return true;
            return _getTournamentMetadata(m.leagueName)['label'] == _selectedFilter;
          }).toList();

          final liveCount = filteredMatches.where((m) => m.status == MatchStatus.live).length;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(footballMatchesProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Sport header ─────────────────────────────────────
                SliverToBoxAdapter(child: _buildSportHeader(liveCount)),

                // ── Filter chips ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _buildFilterChips(filterLabels),
                  ),
                ),

                // ── Match count label ─────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Matches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('${filteredMatches.length} found', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),

                // ── Match list / empty state ───────────────────────────
                if (allMatches.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState(Icons.sports_soccer_rounded, 'No football matches available'))
                else if (filteredMatches.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState(Icons.filter_list_off_rounded, 'No matches for this filter'))
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index > 0 && (index + 1) % 4 == 0) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: AdBannerWidget(),
                            );
                          }
                          final dataIndex = index - (index ~/ 4);
                          if (dataIndex < 0 || dataIndex >= filteredMatches.length) return null;
                          final match = filteredMatches[dataIndex];
                          return _buildMatchTile(match);
                        },
                        childCount: filteredMatches.length + (filteredMatches.length ~/ 3),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => _buildErrorState(),
      ),
    );
  }

  Widget _buildSportHeader(int liveCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF001233), Color(0xFF003566)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
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
            child: const Icon(Icons.sports_soccer_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Football', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                Text(
                  liveCount > 0 ? '$liveCount matches LIVE now' : 'Live & upcoming matches',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (liveCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, color: Colors.white, size: 7),
                  const SizedBox(width: 5),
                  Text('$liveCount LIVE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<String> labels) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        itemBuilder: (context, index) {
          final label = labels[index];
          final isSelected = _selectedFilter == label;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => setState(() => _selectedFilter = isSelected ? 'All' : label),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                    else
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFF1F3F5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchTile(Match match) {
    final matchStatus = match.status;
    String statusText = 'Starting Soon';
    if (matchStatus == MatchStatus.live) statusText = 'LIVE';
    if (matchStatus == MatchStatus.fullTime) statusText = 'Match Finished';
    String timeText = match.time ?? '';
    if (matchStatus == MatchStatus.upcoming) {
      final cd = match.countdown;
      if (cd != null) timeText = 'Starts in ${cd.inHours}h ${cd.inMinutes % 60}m';
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

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: AppColors.textSecondary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.accent, size: 48),
          const SizedBox(height: 16),
          const Text('Failed to load matches', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.invalidate(footballMatchesProvider),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
