import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MatchCard extends StatelessWidget {
  final String leagueName;
  final String teamALogo;
  final String teamAName;
  final String teamBLogo;
  final String teamBName;
  final String matchDateTime;
  final String stadiumName;
  final String matchStatus;

  const MatchCard({
    super.key,
    required this.leagueName,
    required this.teamALogo,
    required this.teamAName,
    required this.teamBLogo,
    required this.teamBName,
    required this.matchDateTime,
    required this.stadiumName,
    required this.matchStatus,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLive = matchStatus.toUpperCase() == 'LIVE';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F3F5), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Accent Bar for LIVE status
            if (isLive)
              Container(
                height: 3,
                width: double.infinity,
                color: AppColors.accent,
              ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // League Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.emoji_events_outlined, color: AppColors.primary, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          leagueName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          matchStatus,
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.8),
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Teams Row
                  Row(
                    children: [
                      // Team A
                      Expanded(
                        child: Column(
                          children: [
                            _buildTeamLogo(teamALogo),
                            const SizedBox(height: 8),
                            Text(
                              teamAName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // VS Central Badge
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE9ECEF)),
                              ),
                              child: const Text(
                                "VS",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Team B
                      Expanded(
                        child: Column(
                          children: [
                            _buildTeamLogo(teamBLogo),
                            const SizedBox(height: 8),
                            Text(
                              teamBName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bottom Info
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF1F3F5), width: 1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 12),
                            const SizedBox(width: 6),
                            Text(
                              matchDateTime,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (stadiumName.isNotEmpty && stadiumName != 'TBD')
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                stadiumName,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLogo(String url, {double size = 44}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F3F5), width: 1),
      ),
      padding: const EdgeInsets.all(6),
      child: url.isNotEmpty
          ? ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.sports, color: AppColors.textSecondary.withOpacity(0.4), size: size * 0.5),
              ),
            )
          : Icon(Icons.sports, color: AppColors.textSecondary.withOpacity(0.4), size: size * 0.5),
    );
  }
}
