import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MatchCard extends StatefulWidget {
  final String leagueName;
  final String leagueLogo;
  final String teamALogo;
  final String teamAName;
  final String teamBLogo;
  final String teamBName;
  final String matchDateTime;
  final String stadiumName;
  final String matchStatus;
  final String? scoreA;
  final String? scoreB;
  final String? minute;
  final String sport;

  const MatchCard({
    super.key,
    required this.leagueName,
    this.leagueLogo = '',
    required this.teamALogo,
    required this.teamAName,
    required this.teamBLogo,
    required this.teamBName,
    required this.matchDateTime,
    this.stadiumName = 'TBD',
    required this.matchStatus,
    this.scoreA,
    this.scoreB,
    this.minute,
    this.sport = 'football',
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (_isLive) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  bool get _isLive => widget.matchStatus.toUpperCase() == 'LIVE';
  bool get _isFinished =>
      widget.matchStatus == 'Match Finished' ||
      widget.matchStatus.toUpperCase() == 'FT';
  bool get _hasScore =>
      widget.scoreA != null &&
      widget.scoreB != null &&
      widget.scoreA!.isNotEmpty &&
      widget.scoreB!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isLive
              ? [const Color(0xFF0E1F40), const Color(0xFF162747)]
              : _isFinished
                  ? [const Color(0xFF0A1328), const Color(0xFF101C38)]
                  : [const Color(0xFF06113D), const Color(0xFF0C1E52)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isLive
              ? AppColors.live.withValues(alpha: 0.35)
              : const Color(0x10FFFFFF),
          width: _isLive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isLive
                ? AppColors.live.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.28),
            blurRadius: _isLive ? 20 : 12,
            offset: const Offset(0, 6),
            spreadRadius: _isLive ? 2 : -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Ambient live glow blob
            if (_isLive)
              Positioned(
                top: -50,
                right: -25,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.live.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeagueRow(),
                  const SizedBox(height: 14),
                  _buildTeamsRow(),
                  if (widget.stadiumName.isNotEmpty &&
                      widget.stadiumName != 'TBD') ...[
                    const SizedBox(height: 10),
                    _buildVenueRow(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── League / status row ────────────────────────────────────────────────────

  Widget _buildLeagueRow() {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Color(0x14FFFFFF),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          child: Icon(
            widget.sport == 'cricket'
                ? Icons.sports_cricket_rounded
                : Icons.sports_soccer_rounded,
            color: const Color(0x61FFFFFF),
            size: 10,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            widget.leagueName,
            style: const TextStyle(
              color: Color(0x8AFFFFFF),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    if (_isLive) {
      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.live.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.live.withValues(alpha: 0.32),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.live.withValues(alpha: _pulseAnim.value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.live.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.minute != null && widget.minute!.isNotEmpty
                    ? "LIVE · ${widget.minute}'"
                    : 'LIVE',
                style: const TextStyle(
                  color: AppColors.live,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isFinished) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: const BoxDecoration(
          color: Color(0x0DFFFFFF),
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        child: const Text(
          'FT',
          style: TextStyle(
            color: Color(0x4DFFFFFF),
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    // Upcoming
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.upcoming.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.upcoming.withValues(alpha: 0.20),
          width: 0.8,
        ),
      ),
      child: Text(
        widget.matchDateTime,
        style: const TextStyle(
          color: Color(0xFF60A5FA),
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Teams + score/VS row ───────────────────────────────────────────────────

  Widget _buildTeamsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              _buildLogo(widget.teamALogo),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.teamAName,
                  style: TextStyle(
                    color: _isFinished
                        ? const Color(0x80FFFFFF)
                        : const Color(0xF2FFFFFF),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _hasScore ? _buildScore() : _buildVs(),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  widget.teamBName,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: _isFinished
                        ? const Color(0x80FFFFFF)
                        : const Color(0xF2FFFFFF),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              _buildLogo(widget.teamBLogo),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScore() {
    return Text(
      '${widget.scoreA}  –  ${widget.scoreB}',
      style: TextStyle(
        color: _isLive ? Colors.white : const Color(0x99FFFFFF),
        fontWeight: FontWeight.w900,
        fontSize: _isLive ? 20 : 18,
        letterSpacing: 2,
        height: 1,
      ),
    );
  }

  Widget _buildVs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0x12FFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0x17FFFFFF)),
        ),
      ),
      child: const Text(
        'VS',
        style: TextStyle(
          color: Color(0x61FFFFFF),
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildVenueRow() {
    return Row(
      children: [
        const Icon(Icons.stadium_outlined, size: 9, color: Color(0x33FFFFFF)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.stadiumName,
            style: const TextStyle(
              color: Color(0x3DFFFFFF),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(String url, {double size = 38}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: url.isNotEmpty
          ? ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.sports,
                  color: AppColors.textMuted,
                  size: size * 0.45,
                ),
              ),
            )
          : Icon(Icons.sports, color: AppColors.textMuted, size: size * 0.45),
    );
  }
}
