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
    if (name.contains(',')) {
      label = name.split(',')[0]; 
    }
    if (label.length > 15) {
      label = label.substring(0, 13) + '..';
    }
    return {'label': label, 'icon': Icons.sports_soccer_rounded};
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(footballMatchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Football Matches', 
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 22)
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
        ),
      ),
      body: matchesAsync.when(
        data: (allMatches) {
          if (allMatches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_soccer_rounded, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'No football matches available.', 
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)
                  ),
                ],
              ),
            );
          }

          final List<String> filterLabels = ['All'];
          final Set<String> seenLabels = {};
          for (var m in allMatches) {
            final label = _getTournamentMetadata(m.leagueName)['label'];
            if (!seenLabels.contains(label)) {
              filterLabels.add(label);
              seenLabels.add(label);
            }
          }

          final filteredMatches = allMatches.where((m) {
            if (_selectedFilter == 'All') return true;
            return _getTournamentMetadata(m.leagueName)['label'] == _selectedFilter;
          }).toList();

          return Column(
            children: [
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F3F5))),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filterLabels.length,
                  itemBuilder: (context, index) {
                    final label = filterLabels[index];
                    final isSelected = _selectedFilter == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(label),
                        onSelected: (selected) => setState(() => _selectedFilter = selected ? label : 'All'),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary, 
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        checkmarkColor: Colors.white,
                        backgroundColor: const Color(0xFFF8F9FA),
                        shape: StadiumBorder(side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE9ECEF))),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(footballMatchesProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: filteredMatches.length + (filteredMatches.length ~/ 3),
                    itemBuilder: (context, index) {
                      if (index > 0 && (index + 1) % 4 == 0) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: AdBannerWidget(),
                        );
                      }

                      final dataIndex = index - (index ~/ 4);
                      if (dataIndex >= filteredMatches.length) return null;
                      final Match match = filteredMatches[dataIndex];
                      
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
                        onTap: () {
                          context.push('/match-detail', extra: match);
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
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.accent, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load matches', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(footballMatchesProvider),
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
