import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/match.dart';
import '../../theme/app_colors.dart';
import 'lineups_tab.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../services/ad_service.dart';

class MatchDetailScreen extends ConsumerWidget {
  final Match match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final footballData = match.footballData;
    final event = footballData?['event'];
    final lineups = footballData?['lineups'];
    final pregameForm = footballData?['pregame_form'];
    final matchStatus = match.status;
    
    // Parse players from JSON into Player model
    List<Player> parsePlayers(dynamic rawPlayers) {
      if (rawPlayers is! List) return [];
      return rawPlayers.map((p) {
        return Player(
          number: (p['number'] ?? p['jersey_number'] ?? '0').toString(),
          name: (p['name'] ?? p['player_name'] ?? 'Player').toString(),
        );
      }).toList();
    }

    final teamALineup = parsePlayers(lineups?['home_players']);
    final teamBLineup = parsePlayers(lineups?['away_players']);
    
    final List<String> teamAUnavailable = List<String>.from(lineups?['home_missing_players'] ?? []);
    final List<String> teamBUnavailable = List<String>.from(lineups?['away_missing_players'] ?? []);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          match.leagueName,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Team Header
            _buildTeamHeader(),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Match Preview Card
                  _buildPreviewCard(),
                  const SizedBox(height: 16),
                  
                  // Detailed Info Section
                  _buildSectionHeader(Icons.info_outline_rounded, 'Match Information'),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.emoji_events_outlined,
                    label: 'League',
                    value: match.leagueName,
                  ),
                  const SizedBox(height: 12),
                  if (event?['round'] != null) ...[
                    _buildInfoCard(
                      icon: Icons.numbers_rounded,
                      label: 'Round',
                      value: 'Round ${event!['round']}',
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildInfoCard(
                    icon: Icons.access_time,
                    label: 'Kick-off',
                    value: match.time ?? 'TBD',
                  ),
                  const SizedBox(height: 12),
                  if (event?['venue'] != null) ...[
                    _buildInfoCard(
                      icon: Icons.location_on_outlined,
                      label: 'Venue',
                      value: event!['venue'].toString(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (event?['stadium_capacity'] != null) ...[
                    _buildInfoCard(
                      icon: Icons.people_outline_rounded,
                      label: 'Capacity',
                      value: event!['stadium_capacity'].toString(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (event?['home_manager'] != null) ...[
                    _buildInfoCard(
                      icon: Icons.person_outline,
                      label: 'Managers',
                      value: '${event!['home_manager']} vs ${event['away_manager']}',
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 12),

                  // Pregame Form Section
                  if (pregameForm != null) ...[
                    _buildSectionHeader(Icons.analytics_outlined, 'Pregame Form'),
                    const SizedBox(height: 12),
                    _buildPregameFormCard(pregameForm),
                    const SizedBox(height: 24),
                  ],
                  
                  // Streaming Links Section
                  if (matchStatus == MatchStatus.live) ...[
                    _buildSectionHeader(Icons.play_circle_outline_rounded, 'Watch Live Stream'),
                    const SizedBox(height: 12),
                    _buildStreamingLinks(context, ref),
                  ] else if (matchStatus == MatchStatus.upcoming) ...[
                    _buildStatusNotice(
                      Icons.timer_outlined, 
                      'Match Starting Soon', 
                      'Streaming links will appear here once the match starts.'
                    ),
                  ] else ...[
                    _buildStatusNotice(
                      Icons.check_circle_outline_rounded, 
                      'Match Finished', 
                      'This match has concluded. Check back later for highlights.'
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Playing XI Section
                  _buildSectionHeader(Icons.groups_outlined, 'Playing XI'),
                  const SizedBox(height: 12),
                  LineupsTab(
                    teamAFormation: (lineups?['home_formation'] ?? '').toString(),
                    teamBFormation: (lineups?['away_formation'] ?? '').toString(),
                    teamALineup: teamALineup,
                    teamBLineup: teamBLineup,
                    teamAUnavailable: teamAUnavailable,
                    teamBUnavailable: teamBUnavailable,
                  ),
                  const SizedBox(height: 24),

                  // Head-to-Head Section
                  _buildSectionHeader(Icons.history_rounded, 'Head-to-Head'),
                  const SizedBox(height: 12),
                  _buildH2HCard(footballData?['h2h']),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusNotice(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F3F5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTeamCol(match.teamA, match.teamALogo),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _buildTeamCol(match.teamB, match.teamBLogo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCol(String name, String logo) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            backgroundImage: logo.isNotEmpty ? NetworkImage(logo) : null,
            child: logo.isEmpty ? const Icon(Icons.sports, color: AppColors.primary) : null,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 120,
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F3F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'MATCH PREVIEW',
                  style: TextStyle(color: AppColors.primary.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match.teamA} vs ${match.teamB}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  '${match.teamA} and ${match.teamB} are scheduled to face each other in the ${match.leagueName}.',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F3F5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPregameFormCard(Map<String, dynamic> form) {
    final home = form['homeTeam'];
    final away = form['awayTeam'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F3F5)),
      ),
      child: Column(
        children: [
          _buildFormRow(match.teamA, home),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F3F5)),
          ),
          _buildFormRow(match.teamB, away),
        ],
      ),
    );
  }

  Widget _buildFormRow(String teamName, dynamic teamData) {
    final List<dynamic> formList = teamData?['form'] ?? [];
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(teamName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('Pos: ${teamData?['position'] ?? '-'} • Rating: ${teamData?['avgRating'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: formList.map((f) => _buildFormBadge(f.toString())).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFormBadge(String result) {
    Color color;
    switch (result.toUpperCase()) {
      case 'W': color = const Color(0xFF2DC653); break;
      case 'D': color = const Color(0xFFFFB703); break;
      case 'L': color = const Color(0xFFE63946); break;
      default: color = Colors.grey;
    }
    return Container(
      margin: const EdgeInsets.only(left: 4),
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      alignment: Alignment.center,
      child: Text(result, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingLinks(BuildContext context, WidgetRef ref) {
    final List<String> links = [...match.streamUrls];
    if (match.detailsUrl.isNotEmpty) links.insert(0, match.detailsUrl);

    if (links.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No streaming links available for this match.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      );
    }

    return Column(
      children: links.asMap().entries.map((entry) {
        int idx = entry.key;
        String url = entry.value;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildLinkTile(
            context: context,
            ref: ref,
            title: 'Stream Server ${idx + 1}',
            url: url,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLinkTile({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String url,
  }) {
    return InkWell(
      onTap: () {
        ref.read(adServiceProvider).showRewardedAd(
          onUserEarnedReward: (reward) {
            _launchURL(url);
          },
          onAdDismissed: () {
            _launchURL(url);
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F3F5)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accent,
              child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 14),
                  ),
                  const Text(
                    'High Quality Native Player',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCED4DA)),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url, 
        mode: LaunchMode.inAppWebView,
      );
    }
  }

  Widget _buildH2HCard(Map<String, dynamic>? h2h) {
    if (h2h == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F3F5)),
        ),
        child: const Column(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFCED4DA), size: 32),
            SizedBox(height: 12),
            Text(
              'Head-to-head data not available',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final homeWins = h2h['homeWins'] ?? 0;
    final awayWins = h2h['awayWins'] ?? 0;
    final draws = h2h['draws'] ?? 0;
    final total = homeWins + awayWins + draws;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F3F5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildH2HStatCol('Wins', homeWins.toString(), match.teamA),
              _buildH2HStatCol('Draws', draws.toString(), 'Total'),
              _buildH2HStatCol('Wins', awayWins.toString(), match.teamB),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: homeWins == 0 && total == 0 ? 1 : (homeWins as int),
                    child: Container(color: AppColors.primary),
                  ),
                  Expanded(
                    flex: draws == 0 && total == 0 ? 1 : (draws as int),
                    child: Container(color: const Color(0xFFE9ECEF)),
                  ),
                  Expanded(
                    flex: awayWins == 0 && total == 0 ? 1 : (awayWins as int),
                    child: Container(color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildH2HStatCol(String label, String value, String team) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(
            team,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
