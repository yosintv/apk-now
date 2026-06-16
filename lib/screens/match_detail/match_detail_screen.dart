import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/match.dart';
import 'lineups_tab.dart';
import '../../services/ad_service.dart';
import '../../providers/streaming_provider.dart';
import '../../providers/config_provider.dart';
import '../../widgets/banner_ad_widget.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _bgPage       = Color(0xFFF4F6F9);
const _cardBg       = Colors.white;
const _textPrimary  = Color(0xFF0F1B2D);
const _textSecondary= Color(0xFF64748B);
const _textMuted    = Color(0xFF94A3B8);
const _divColor     = Color(0xFFF0F3F7);
const _accent       = Color(0xFF1652A8);
const _accentSoft   = Color(0x1A1652A8); // ~10% alpha
const _homeColor    = Color(0xFF0B2E5E);
const _awayColor    = Color(0xFF16834A);
const _statusAmber  = Color(0xFFFACC15);
const _statusLive   = Color(0xFFF43F5E);

BoxDecoration _cardDecor() => const BoxDecoration(
  color: _cardBg,
  borderRadius: BorderRadius.all(Radius.circular(20)),
  boxShadow: [
    BoxShadow(
      color: Color(0x150F1B2D),
      blurRadius: 18,
      offset: Offset(0, 4),
      spreadRadius: -8,
    ),
  ],
);

// ── Screen ────────────────────────────────────────────────────────────────────

class MatchDetailScreen extends ConsumerStatefulWidget {
  final Match match;
  const MatchDetailScreen({super.key, required this.match});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        ref.read(adServiceProvider).showRewardedAd(
          onUserEarnedReward: (reward) {},
          onAdDismissed: () {},
        );
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _m(dynamic d) =>
      d is Map<String, dynamic> ? d : {};

  List<Player> _parsePlayers(dynamic raw) {
    if (raw is! List) return [];
    return raw.asMap().entries.map((e) {
      final p = e.value;
      if (p is Map) {
        return Player(
          number: (p['number'] ?? p['jersey_number'] ?? e.key + 1).toString(),
          name:   (p['name']   ?? p['player_name']   ?? 'Player').toString(),
        );
      }
      return Player(number: (e.key + 1).toString(), name: p.toString());
    }).toList();
  }

  String _fmt(String? raw) {
    if (raw == null || raw.isEmpty) return 'TBD';
    try {
      return DateFormat('d MMM yyyy · HH:mm').format(DateTime.parse(raw).toLocal());
    } catch (_) { return raw; }
  }

  String _code(String name) {
    final w = name.trim().split(RegExp(r'\s+'));
    if (w.length >= 3) return w.take(3).map((x) => x[0].toUpperCase()).join();
    if (w.length == 2) {
      return (w[0].substring(0, min(2, w[0].length)) +
              w[1].substring(0, 1))
          .toUpperCase();
    }
    return name.substring(0, min(3, name.length)).toUpperCase();
  }

  String _short(String full) {
    final parts = full.trim().split(RegExp(r'\s+'));
    final last  = parts.length > 1 ? parts.last : full;
    return last.length > 8 ? '${last.substring(0, 8)}.' : last;
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final config      = ref.watch(configProvider);
    final match       = widget.match;
    final status      = match.status;
    final countdown   = match.countdown;
    final isPreMatch  = status == MatchStatus.upcoming &&
                        countdown != null &&
                        countdown.inMinutes <= 15;

    final fd      = _m(match.footballData);
    final event   = _m(fd['event']);
    final lineups = _m(fd['lineups']);
    final h2h     = _m(fd['h2h']);

    final homeLineup   = _parsePlayers(lineups['home_players']);
    final awayLineup   = _parsePlayers(lineups['away_players']);
    final homeOut      = List<String>.from(lineups['home_missing_players'] ?? []);
    final awayOut      = List<String>.from(lineups['away_missing_players'] ?? []);
    final homeFmt      = (lineups['home_formation'] ?? '').toString();
    final awayFmt      = (lineups['away_formation'] ?? '').toString();
    final homeManager  = event['home_manager']?.toString();
    final awayManager  = event['away_manager']?.toString();

    final hasLineupData = homeLineup.isNotEmpty || awayLineup.isNotEmpty ||
                          homeOut.isNotEmpty    || awayOut.isNotEmpty    ||
                          homeManager != null   || awayManager != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _bgPage,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // 1 · Hero header
              SliverToBoxAdapter(
                child: _buildHero(match, status),
              ),

              // 2 · Match Preview
              _pad(_buildPreviewCard(match)),

              // 3 · Match Information
              _pad(_buildInfoCard(match, event)),

              // 4 · Match Links (hidden in review mode)
              if (!config.reviewMode)
                _pad(_buildLinksSection(match, status, isPreMatch, countdown)),

              // 5 · Playing XI
              if (hasLineupData)
                _pad(_buildPlayingXI(
                  match, homeLineup, awayLineup,
                  homeFmt, awayFmt, homeOut, awayOut,
                  homeManager, awayManager,
                )),

              // 6 · Head-to-Head
              if (h2h.isNotEmpty) _pad(_buildH2H(match, h2h)),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
        bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
      ),
    );
  }

  SliverToBoxAdapter _pad(Widget child) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: child,
    ),
  );

  // ── 1 · Hero ───────────────────────────────────────────────────────────────

  Widget _buildHero(Match match, MatchStatus status) {
    final isLive     = status == MatchStatus.live;
    final isFinished = status == MatchStatus.fullTime;
    final hasScore   = match.scoreA != null && match.scoreB != null;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.6),
          radius: 1.5,
          colors: [
            Color(0xFF1763C9),
            Color(0xFF0D4288),
            Color(0xFF0A2C5E),
            Color(0xFF06183A),
          ],
          stops: [0.0, 0.3, 0.65, 1.0],
        ),
      ),
      child: Column(
          children: [
            // Back button row
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLive) ...[
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: _statusLive.withOpacity(_pulseAnim.value),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _statusLive.withOpacity(0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE',
                      style: GoogleFonts.plusJakartaSans(
                        color: _statusLive,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: isFinished ? _textMuted : _statusAmber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFinished ? 'FULL TIME' : 'UPCOMING',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Teams row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildTeamBlock(
                      match.teamA, match.teamALogo, _code(match.teamA),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: hasScore
                        ? _buildScoreBlock(
                            match.scoreA!, match.scoreB!, match.minute, isLive)
                        : _buildVsBlock(),
                  ),
                  Expanded(
                    child: _buildTeamBlock(
                      match.teamB, match.teamBLogo, _code(match.teamB),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bottom info strip
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 18),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: Colors.white54,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _fmt(match.time),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (match.stadium != null &&
                      match.stadium!.isNotEmpty &&
                      match.stadium != 'TBD') ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 1,
                      height: 14,
                      color: Colors.white24,
                    ),
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        match.stadium!,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildTeamBlock(String name, String logo, String code) {
    return Column(
      children: [
        Container(
          width: 78, height: 78,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.22),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: logo.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    logo,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.sports, color: _accent, size: 30),
                  ),
                )
              : const Icon(Icons.sports, color: _accent, size: 30),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            height: 1.25,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          code,
          style: GoogleFonts.archivo(
            color: Colors.white38,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVsBlock() {
    return Text(
      'VS',
      style: GoogleFonts.archivo(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 30,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildScoreBlock(
      String a, String b, String? minute, bool isLive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLive && minute != null && minute.isNotEmpty)
          Text(
            "$minute'",
            style: GoogleFonts.plusJakartaSans(
              color: _statusLive,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              a,
              style: GoogleFonts.archivo(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 44,
                height: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                ':',
                style: GoogleFonts.archivo(
                  color: Colors.white30,
                  fontWeight: FontWeight.w900,
                  fontSize: 38,
                  height: 1,
                ),
              ),
            ),
            Text(
              b,
              style: GoogleFonts.archivo(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 44,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'HT',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ── 2 · Match Preview ──────────────────────────────────────────────────────

  Widget _buildPreviewCard(Match match) {
    return Container(
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent chip header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_outlined, size: 14, color: _accent),
                ),
                const SizedBox(width: 10),
                Text(
                  'MATCH PREVIEW',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _accent,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match.teamA} vs ${match.teamB}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${match.teamA} and ${match.teamB} face off in the '
                  '${match.leagueName}. Both sides will be looking to '
                  'secure a positive result in this fixture.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: _textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3 · Match Information ──────────────────────────────────────────────────

  Widget _buildInfoCard(Match match, Map<String, dynamic> event) {
    final rows = <_InfoRow>[
      _InfoRow(Icons.emoji_events_outlined,  'League',   match.leagueName),
      if (event['round'] != null)
        _InfoRow(Icons.numbers_rounded, 'Round', 'Round ${event['round']}'),
      _InfoRow(Icons.access_time_rounded, 'Kick-off', _fmt(match.time)),
      if (event['venue'] != null)
        _InfoRow(Icons.stadium_outlined, 'Venue', event['venue'].toString()),
      if (event['stadium_capacity'] != null)
        _InfoRow(Icons.people_outline_rounded, 'Capacity',
            '${event['stadium_capacity']} seats'),
      if (event['referee'] != null)
        _InfoRow(Icons.person_pin_outlined, 'Referee',
            event['referee'].toString()),
    ];

    return Container(
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chipHeader(Icons.info_outline_rounded, 'MATCH INFORMATION'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: rows.asMap().entries.map((e) {
                return _buildInfoRow(e.value, isLast: e.key == rows.length - 1);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(_InfoRow row, {required bool isLast}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(row.icon, size: 17, color: _accent),
              ),
              const SizedBox(width: 14),
              Text(
                row.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: _textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Text(
                  row.value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1, color: _divColor),
      ],
    );
  }

  // ── 4 · Match Links ───────────────────────────────────────────────────────

  Widget _buildLinksSection(
    Match match,
    MatchStatus status,
    bool isPreMatch,
    Duration? countdown,
  ) {
    final showLinks = status == MatchStatus.live || isPreMatch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(Icons.play_circle_outline_rounded, 'Match Links'),
        const SizedBox(height: 14),
        if (!showLinks)
          _buildLinkPlaceholder(status)
        else
          _buildLinksList(match, countdown),
      ],
    );
  }

  Widget _buildLinkPlaceholder(MatchStatus status) {
    final finished = status == MatchStatus.fullTime;
    return Container(
      decoration: _cardDecor(),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 70, height: 70,
            decoration: const BoxDecoration(color: _accentSoft, shape: BoxShape.circle),
            child: const Icon(Icons.timer_outlined, color: _accent, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            finished ? 'Match Finished' : 'Match Starting Soon',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            finished
                ? 'This match has concluded.'
                : 'Streaming links appear 15 minutes before kick-off.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksList(Match match, Duration? countdown) {
    // Inner helper to render list of link entries
    Widget renderLinks(List<_LinkEntry> links) {
      if (links.isEmpty) {
        return _buildLinkPlaceholder(MatchStatus.upcoming);
      }
      return Container(
        decoration: _cardDecor(),
        child: Column(
          children: [
            if (countdown != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9EE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _statusAmber.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 15, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      Text(
                        'Kick-off in ${countdown.inMinutes}m — links ready',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFFF59E0B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: links.asMap().entries.map((e) => Column(
                  children: [
                    _buildLinkRow(e.value),
                    if (e.key < links.length - 1)
                      Divider(height: 1, thickness: 1, color: _divColor),
                  ],
                )).toList(),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      );
    }

    final streamUrl = match.streamingUrl;
    if (streamUrl != null && streamUrl.isNotEmpty) {
      final streamData = ref.watch(streamingLinksProvider(streamUrl));
      return streamData.when(
        data: (cfg) {
          if (cfg == null || cfg.events.isEmpty) {
            return renderLinks(_staticLinks(match));
          }
          final links = <_LinkEntry>[];
          int idx = 1;
          for (final ev in cfg.events) {
            final single = ev.link;
            if (single != null) {
              links.add(_LinkEntry('Server $idx', ev.name, single, 'HD'));
              idx++;
            }
            final multi = ev.links;
            if (multi != null) {
              for (final url in multi) {
                if (url.contains('/api/ads')) continue;
                links.add(_LinkEntry('Server $idx', ev.name, url, 'HD'));
                idx++;
              }
            }
          }
          return renderLinks(links.isEmpty ? _staticLinks(match) : links);
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
          ),
        ),
        error: (_, __) => renderLinks(_staticLinks(match)),
      );
    }
    return renderLinks(_staticLinks(match));
  }

  List<_LinkEntry> _staticLinks(Match match) {
    final out = <_LinkEntry>[];
    if (match.detailsUrl.isNotEmpty) {
      out.add(_LinkEntry('Server 1', 'High Quality Stream', match.detailsUrl, 'FHD'));
    }
    for (int i = 0; i < match.streamUrls.length; i++) {
      out.add(_LinkEntry('Server ${i + 2}', 'High Quality Stream', match.streamUrls[i], 'HD'));
    }
    return out;
  }

  Widget _buildLinkRow(_LinkEntry link) {
    final qualityColor = link.quality == 'FHD'
        ? const Color(0xFF7C3AED)
        : link.quality == 'HD'
            ? _accent
            : _textMuted;

    return InkWell(
      onTap: () => _launch(link.url),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    link.sub,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: qualityColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                link.quality,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: qualityColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: _textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // ── 5 · Playing XI ────────────────────────────────────────────────────────

  Widget _buildPlayingXI(
    Match match,
    List<Player> homeLineup,
    List<Player> awayLineup,
    String homeFmt,
    String awayFmt,
    List<String> homeOut,
    List<String> awayOut,
    String? homeManager,
    String? awayManager,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(Icons.groups_outlined, 'Playing XI'),
        const SizedBox(height: 14),

        if (homeLineup.isNotEmpty || awayLineup.isNotEmpty) ...[
          _buildPitch(homeLineup, awayLineup, homeFmt, awayFmt),
          const SizedBox(height: 14),

          // Formation legend
          Container(
            decoration: _cardDecor(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _legendDot(_homeColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        match.teamA,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (homeFmt.isNotEmpty) _fmtPill(homeFmt, _homeColor),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _legendDot(_awayColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        match.teamB,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (awayFmt.isNotEmpty) _fmtPill(awayFmt, _awayColor),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          // No lineup data
          Container(
            decoration: _cardDecor(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: _textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lineup data not yet available for this match.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: _textSecondary, fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Managers
        if (homeManager != null || awayManager != null) ...[
          const SizedBox(height: 12),
          _buildManagersCard(homeManager, awayManager),
        ],

        // Missing / unavailable
        if (homeOut.isNotEmpty || awayOut.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildMissingCard(homeOut, awayOut),
        ],
      ],
    );
  }

  // Pitch with CustomPainter + player Stack
  Widget _buildPitch(
    List<Player> homeLineup,
    List<Player> awayLineup,
    String homeFmt,
    String awayFmt,
  ) {
    final homeRows = _parseFmt(homeFmt);
    final awayRows = _parseFmt(awayFmt);

    return LayoutBuilder(
      builder: (_, c) {
        final W = c.maxWidth;
        final H = W * 1.38;
        final size = Size(W, H);
        final homePos = _fmtPositions(homeRows, size, true);
        final awayPos = _fmtPositions(awayRows, size, false);

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: W, height: H,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                CustomPaint(size: size, painter: _PitchPainter()),
                // Away (top half)
                ...awayPos.asMap().entries.map((e) => _playerNode(
                  e.key < awayLineup.length ? awayLineup[e.key] : null,
                  e.value,
                  _awayColor,
                )),
                // Home (bottom half)
                ...homePos.asMap().entries.map((e) => _playerNode(
                  e.key < homeLineup.length ? homeLineup[e.key] : null,
                  e.value,
                  _homeColor,
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  List<int> _parseFmt(String fmt) {
    if (fmt.isEmpty) return [4, 3, 3];
    try {
      final rows = fmt.split('-')
          .map((s) => int.tryParse(s.trim()) ?? 0)
          .where((n) => n > 0)
          .toList();
      return rows.isEmpty ? [4, 3, 3] : rows;
    } catch (_) {
      return [4, 3, 3];
    }
  }

  List<Offset> _fmtPositions(List<int> rows, Size size, bool isHome) {
    final W  = size.width;
    final H  = size.height;
    final positions = <Offset>[];

    const hPad   = 0.04;
    const vMar   = 0.06;
    final teamBot = isHome ? H * (1 - vMar) : H * (0.5 - 0.02);
    final teamTop = isHome ? H * (0.5 + 0.02) : H * vMar;

    final totalRows = rows.length + 1;
    final rowSpacing = totalRows > 1
        ? (teamBot - teamTop) / (totalRows - 1)
        : 0.0;

    // GK
    positions.add(Offset(W / 2, isHome ? teamBot : teamTop));

    // Formation rows
    for (int ri = 0; ri < rows.length; ri++) {
      final n = rows[ri];
      final y = isHome
          ? teamBot - (ri + 1) * rowSpacing
          : teamTop + (ri + 1) * rowSpacing;
      for (int ci = 0; ci < n; ci++) {
        final xFrac = (hPad + (1 - 2 * hPad) * (ci + 1) / (n + 1));
        positions.add(Offset(W * xFrac, y));
      }
    }

    return positions;
  }

  Widget _playerNode(Player? player, Offset pos, Color teamColor) {
    const r = 14.0;
    return Positioned(
      left: pos.dx - r,
      top:  pos.dy - r,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: r * 2, height: r * 2,
            decoration: BoxDecoration(
              color: teamColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                player?.number ?? '',
                style: GoogleFonts.archivo(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (player != null)
            SizedBox(
              width: 44,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _short(player.name),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
    width: 14, height: 14,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 1.5),
    ),
  );

  Widget _fmtPill(String fmt, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      fmt,
      style: GoogleFonts.archivo(
        fontSize: 11, fontWeight: FontWeight.w800, color: color,
      ),
    ),
  );

  Widget _buildManagersCard(String? mA, String? mB) {
    return Container(
      decoration: _cardDecor(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MANAGER',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9, fontWeight: FontWeight.w800,
                    color: _textMuted, letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mA ?? 'TBD',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w800, color: _homeColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1, height: 32,
            color: _divColor,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'MANAGER',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9, fontWeight: FontWeight.w800,
                    color: _textMuted, letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mB ?? 'TBD',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w800, color: _awayColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingCard(List<String> homeOut, List<String> awayOut) {
    return Container(
      decoration: _cardDecor(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UNAVAILABLE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9, fontWeight: FontWeight.w800,
              color: _textMuted, letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: homeOut.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(children: [
                      const Icon(Icons.close_rounded, size: 11, color: _statusLive),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          n,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ]),
                  )).toList(),
                ),
              ),
              Container(width: 1, color: _divColor, margin: const EdgeInsets.symmetric(horizontal: 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: awayOut.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Flexible(
                        child: Text(
                          n,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.close_rounded, size: 11, color: _statusLive),
                    ]),
                  )).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 6 · Head-to-Head ──────────────────────────────────────────────────────

  Widget _buildH2H(Match match, Map<String, dynamic> h2h) {
    final raw = (v) => h2h[v];
    final hw = raw('homeWins') is num ? (raw('homeWins') as num).toInt() : 0;
    final aw = raw('awayWins') is num ? (raw('awayWins') as num).toInt() : 0;
    final dr = raw('draws')    is num ? (raw('draws')    as num).toInt() : 0;
    final total = hw + aw + dr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(Icons.history_rounded, 'Head-to-Head'),
        const SizedBox(height: 14),
        Container(
          decoration: _cardDecor(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Big numbers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _h2hStat(hw.toString(), 'Wins', _homeColor),
                  _h2hStat(dr.toString(), 'Draws', _textMuted),
                  _h2hStat(aw.toString(), 'Wins', _awayColor),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.teamA,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$total played',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _textMuted),
                  ),
                  Expanded(
                    child: Text(
                      match.teamB,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Win-share bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      Expanded(
                        flex: total == 0 ? 33 : max(1, hw),
                        child: Container(color: _homeColor),
                      ),
                      Expanded(
                        flex: total == 0 ? 34 : max(1, dr),
                        child: Container(color: _divColor),
                      ),
                      Expanded(
                        flex: total == 0 ? 33 : max(1, aw),
                        child: Container(color: _awayColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _h2hStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.archivo(
            fontSize: 34, fontWeight: FontWeight.w900, color: color, height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: _textMuted, fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Shared widget helpers ─────────────────────────────────────────────────

  Widget _chipHeader(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: _accentSoft,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: _accent),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w800,
              color: _accent, letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _textPrimary),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w900, color: _textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
}

class _LinkEntry {
  final String title;
  final String sub;
  final String url;
  final String quality;
  const _LinkEntry(this.title, this.sub, this.url, this.quality);
}

// ── Football Pitch Painter ────────────────────────────────────────────────────

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    // Green gradient background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F7A3D), Color(0xFF0C8A43), Color(0xFF0F7A3D)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, W, H));
    canvas.drawRect(Rect.fromLTWH(0, 0, W, H), bgPaint);

    // Mowing stripes
    final stripePaint = Paint()..color = Colors.white.withOpacity(0.03);
    final stripeH = H / 14;
    for (int i = 0; i < 14; i += 2) {
      canvas.drawRect(Rect.fromLTWH(0, i * stripeH, W, stripeH), stripePaint);
    }

    // Line paint
    final lp = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const m = 10.0;

    // Outer border
    canvas.drawRect(Rect.fromLTWH(m, m, W - 2 * m, H - 2 * m), lp);

    // Halfway line
    canvas.drawLine(Offset(m, H / 2), Offset(W - m, H / 2), lp);

    // Center circle
    canvas.drawCircle(Offset(W / 2, H / 2), W * 0.13, lp);
    canvas.drawCircle(
      Offset(W / 2, H / 2),
      3,
      Paint()..color = Colors.white.withOpacity(0.55),
    );

    // Penalty areas
    final boxW = W * 0.58;
    final boxH = H * 0.155;
    final boxX = (W - boxW) / 2;
    canvas.drawRect(Rect.fromLTWH(boxX, m, boxW, boxH), lp);          // top
    canvas.drawRect(Rect.fromLTWH(boxX, H - m - boxH, boxW, boxH), lp); // bottom

    // Goal boxes
    final gbW = W * 0.3;
    final gbH = H * 0.075;
    final gbX = (W - gbW) / 2;
    canvas.drawRect(Rect.fromLTWH(gbX, m, gbW, gbH), lp);             // top
    canvas.drawRect(Rect.fromLTWH(gbX, H - m - gbH, gbW, gbH), lp);  // bottom

    // Penalty spots
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.55);
    canvas.drawCircle(Offset(W / 2, m + boxH * 0.62), 2.5, dotPaint);
    canvas.drawCircle(Offset(W / 2, H - m - boxH * 0.62), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
