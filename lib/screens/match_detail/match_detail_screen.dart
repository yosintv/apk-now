import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/match.dart';
import '../../theme/app_colors.dart';
import 'lineups_tab.dart';
import '../../services/ad_service.dart';
import '../../providers/streaming_provider.dart';
import '../../providers/config_provider.dart';
import '../../widgets/banner_ad_widget.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final Match match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 1000ms delay before showing rewarded ad
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        ref.read(adServiceProvider).showRewardedAd(
          onUserEarnedReward: (reward) {
            // Reward earned logic if needed
          },
          onAdDismissed: () {
            // Ad dismissed logic
          },
        );
      }
    });
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'TBD';
    try {
      final DateTime dateTime = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configProvider);
    final match = widget.match;
    
    // Helper to safely access Map keys
    Map<String, dynamic> getMap(dynamic data) {
      if (data is Map<String, dynamic>) return data;
      return {};
    }

    final footballData = getMap(match.footballData);
    final event = getMap(footballData['event']);
    final lineups = getMap(footballData['lineups']);
    final pregameForm = getMap(footballData['pregame_form']);
    final matchStatus = match.status;
    
    List<Player> parsePlayers(dynamic rawPlayers) {
      if (rawPlayers is! List) return [];
      return rawPlayers.asMap().entries.map((entry) {
        final index = entry.key;
        final p = entry.value;
        if (p is Map) {
          return Player(
            number: (p['number'] ?? p['jersey_number'] ?? (index + 1)).toString(),
            name: (p['name'] ?? p['player_name'] ?? 'Player').toString(),
          );
        }
        return Player(
          number: (index + 1).toString(),
          name: p.toString(),
        );
      }).toList();
    }

    final teamALineup = parsePlayers(lineups['home_players']);
    final teamBLineup = parsePlayers(lineups['away_players']);
    
    final List<String> teamAUnavailable = List<String>.from(lineups['home_missing_players'] ?? []);
    final List<String> teamBUnavailable = List<String>.from(lineups['away_missing_players'] ?? []);

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
            _buildTeamHeader(match),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreviewCard(match),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader(Icons.info_outline_rounded, 'Match Information'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF1F3F5)),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.emoji_events_outlined, 'League', match.leagueName),
                        if (event['round'] != null)
                          _buildInfoRow(Icons.numbers_rounded, 'Round', 'Round ${event['round']}'),
                        _buildInfoRow(Icons.access_time, 'Kick-off', _formatDateTime(match.time)),
                        if (event['venue'] != null)
                          _buildInfoRow(Icons.location_on_outlined, 'Venue', event['venue'].toString()),
                        if (event['stadium_capacity'] != null)
                          _buildInfoRow(Icons.people_outline_rounded, 'Capacity', '${event['stadium_capacity']} seats'),
                        if (event['referee'] != null)
                          _buildInfoRow(Icons.person_pin_outlined, 'Referee', event['referee'].toString()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (pregameForm.isNotEmpty) ...[
                    _buildSectionHeader(Icons.analytics_outlined, 'Pregame Form'),
                    const SizedBox(height: 12),
                    _buildPregameFormCard(match, pregameForm, getMap),
                    const SizedBox(height: 24),
                  ],
                  
                  // AdMob Approval Logic: Hide streaming notices/links if in review_mode
                  if (!config.reviewMode) ...[
                    if (matchStatus == MatchStatus.live) ...[
                      _buildSectionHeader(Icons.play_circle_outline_rounded, 'Watch Live Stream'),
                      const SizedBox(height: 12),
                      _buildStreamingSection(context, ref, match),
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
                  ],

                  const SizedBox(height: 32),
                  _buildSectionHeader(Icons.groups_outlined, 'Playing XI'),
                  const SizedBox(height: 12),
                  LineupsTab(
                    teamAFormation: (lineups['home_formation'] ?? '').toString(),
                    teamBFormation: (lineups['away_formation'] ?? '').toString(),
                    teamALineup: teamALineup,
                    teamBLineup: teamBLineup,
                    teamAUnavailable: teamAUnavailable,
                    teamBUnavailable: teamBUnavailable,
                    teamAManager: event['home_manager']?.toString(),
                    teamBManager: event['away_manager']?.toString(),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader(Icons.history_rounded, 'Head-to-Head'),
                  const SizedBox(height: 12),
                  _buildH2HCard(match, getMap(footballData['h2h'])),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(
        child: BannerAdWidget(),
      ),
    );
  }

  Widget _buildStreamingSection(BuildContext context, WidgetRef ref, Match match) {
    final streamUrl = match.streamingUrl;
    if (streamUrl != null && streamUrl.isNotEmpty) {
      final streamData = ref.watch(streamingLinksProvider(streamUrl));
      return streamData.when(
        data: (config) {
          if (config == null || config.events.isEmpty) return _buildStaticLinks(context, ref, match);
          
          final List<Widget> linkWidgets = [];
          int serverIndex = 1;
          for (var event in config.events) {
            final eLink = event.link;
            if (eLink != null) {
              linkWidgets.add(_buildLinkTile(
                context: context, 
                ref: ref, 
                title: "Server $serverIndex", 
                subtitle: event.name,
                url: eLink
              ));
              serverIndex++;
            }
            final eLinks = event.links;
            if (eLinks != null) {
              for (var i = 0; i < eLinks.length; i++) {
                final url = eLinks[i];
                if (url.contains('/api/ads')) continue; 
                
                linkWidgets.add(_buildLinkTile(
                  context: context, 
                  ref: ref, 
                  title: "Server $serverIndex", 
                  subtitle: event.name,
                  url: url
                ));
                serverIndex++;
              }
            }
          }

          if (linkWidgets.isEmpty) return _buildStaticLinks(context, ref, match);

          return Column(
            children: linkWidgets.map((w) => Padding(padding: const EdgeInsets.only(top: 12), child: w)).toList(),
          );
        },
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
        error: (e, st) => _buildStaticLinks(context, ref, match),
      );
    }
    return _buildStaticLinks(context, ref, match);
  }

  Widget _buildStaticLinks(BuildContext context, WidgetRef ref, Match match) {
    final List<String> links = [...match.streamUrls];
    if (match.detailsUrl.isNotEmpty) links.insert(0, match.detailsUrl);
    if (links.isEmpty) return const SizedBox.shrink();

    return Column(
      children: links.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildLinkTile(
            context: context, 
            ref: ref, 
            title: 'Server ${entry.key + 1}', 
            subtitle: 'High Quality Stream',
            url: entry.value
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLinkTile({
    required BuildContext context, 
    required WidgetRef ref, 
    required String title, 
    required String subtitle,
    required String url
  }) {
    return InkWell(
      onTap: () {
        _launchURL(url);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F3F5)),
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 18, backgroundColor: AppColors.accent, child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.open_in_browser_rounded, size: 18, color: Color(0xFFCED4DA)),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary.withOpacity(0.6)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          Flexible(
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPregameFormCard(Match match, Map<String, dynamic> form, Map<String, dynamic> Function(dynamic) getMap) {
    final home = getMap(form['homeTeam']);
    final away = getMap(form['awayTeam']);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F3F5)),
      ),
      child: Column(
        children: [
          _buildFormRow(match.teamA, home),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF1F3F5)),
          ),
          _buildFormRow(match.teamB, away),
        ],
      ),
    );
  }

  Widget _buildFormRow(String teamName, Map<String, dynamic> data) {
    final List<dynamic> formList = data['form'] ?? [];
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(teamName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('Rank: ${data['position'] ?? '-'} • Rating: ${data['avgRating'] ?? '-'}', 
                   style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: formList.map((f) => _buildFormBadge(f.toString())).toList(),
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
      margin: const EdgeInsets.only(left: 5),
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      alignment: Alignment.center,
      child: Text(result, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildStatusNotice(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F3F5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildTeamHeader(Match match) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTeamCol(match.teamA, match.teamALogo),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: const Text('VS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
          _buildTeamCol(match.teamB, match.teamBLogo),
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
          child: Text(name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(Match match) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: const Color(0xFFF1F3F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(color: Color(0xFFF8F9FA), borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text('MATCH PREVIEW', style: TextStyle(color: AppColors.primary.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${match.teamA} vs ${match.teamB}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('${match.teamA} and ${match.teamB} are scheduled to face each other in the ${match.leagueName}.', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildH2HCard(Match match, Map<String, dynamic> h2h) {
    if (h2h.isEmpty) return const SizedBox.shrink();
    final homeWins = h2h['homeWins'] ?? 0;
    final awayWins = h2h['awayWins'] ?? 0;
    final draws = h2h['draws'] ?? 0;
    final total = homeWins + awayWins + draws;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F3F5))),
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
                  Expanded(flex: homeWins == 0 && total == 0 ? 1 : (homeWins as int), child: Container(color: AppColors.primary)),
                  Expanded(flex: draws == 0 && total == 0 ? 1 : (draws as int), child: Container(color: const Color(0xFFE9ECEF))),
                  Expanded(flex: awayWins == 0 && total == 0 ? 1 : (awayWins as int), child: Container(color: AppColors.accent)),
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
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        SizedBox(width: 80, child: Text(team, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
