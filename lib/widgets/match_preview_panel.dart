import 'package:flutter/material.dart';

class MatchPreviewPanel extends StatelessWidget {
  final String teamALogo;
  final String teamAName;
  final String teamBLogo;
  final String teamBName;
  final String matchDateTime;
  final String stadiumName;
  final String categoryTag;
  final String previewText;
  final int teamAWins;
  final int draws;
  final int teamBWins;
  final List<String> teamAForm; // e.g. ['W', 'D', 'L', 'W', 'W']
  final List<String> teamBForm; // e.g. ['L', 'L', 'W', 'D', 'L']

  const MatchPreviewPanel({
    super.key,
    required this.teamALogo,
    required this.teamAName,
    required this.teamBLogo,
    required this.teamBName,
    required this.matchDateTime,
    required this.stadiumName,
    required this.categoryTag,
    required this.previewText,
    required this.teamAWins,
    required this.draws,
    required this.teamBWins,
    required this.teamAForm,
    required this.teamBForm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Match Header Block
        _buildHeaderBlock(),
        const SizedBox(height: 16),
        // 2. Match Preview Container (includes Head-to-Head and Recent Form)
        _buildPreviewContainer(),
      ],
    );
  }

  Widget _buildHeaderBlock() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A), // Dark blue canvas
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTeamLogo(teamALogo),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              _buildTeamLogo(teamBLogo),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            matchDateTime,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(
                stadiumName,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String url) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(4),
      child: url.isNotEmpty
          ? ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.sports_soccer, color: Colors.grey, size: 30),
              ),
            )
          : const Icon(Icons.sports_soccer, color: Colors.grey, size: 30),
    );
  }

  Widget _buildPreviewContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Match Preview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  categoryTag.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Descriptive Text
          Text(
            previewText,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C757D),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          
          // Head-to-Head Section
          const Text(
            'Head-to-Head',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 16),
          _buildHeadToHeadBar(),
          
          const SizedBox(height: 24),
          
          // Recent Form Section
          const Text(
            'Recent Form',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentFormRow(teamAName, teamAForm),
          const SizedBox(height: 12),
          _buildRecentFormRow(teamBName, teamBForm),
        ],
      ),
    );
  }

  Widget _buildHeadToHeadBar() {
    final int total = teamAWins + draws + teamBWins;

    return Column(
      children: [
        // Teams and Numbers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                teamAName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$teamAWins - $draws - $teamBWins',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF6C757D),
              ),
            ),
            Expanded(
              child: Text(
                teamBName,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Linear Bar Indicator
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Expanded(
                  flex: teamAWins == 0 ? (total == 0 ? 1 : 0) : teamAWins,
                  child: Container(color: const Color(0xFF0D1B2A)), // Navy
                ),
                Expanded(
                  flex: draws == 0 ? (total == 0 ? 1 : 0) : draws,
                  child: Container(color: const Color(0xFFE9ECEF)), // Light Grey
                ),
                Expanded(
                  flex: teamBWins == 0 ? (total == 0 ? 1 : 0) : teamBWins,
                  child: Container(color: const Color(0xFFE63946)), // Red/Pink
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Bottom Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$teamAWins W',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.bold),
            ),
            Text(
              '$draws D',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.bold),
            ),
            Text(
              '$teamBWins W',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentFormRow(String teamName, List<String> form) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            teamName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0D1B2A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: form.take(5).map((result) {
            Color bgColor;
            if (result.toUpperCase() == 'W') {
              bgColor = const Color(0xFF2E7D32); // Green
            } else if (result.toUpperCase() == 'L') {
              bgColor = const Color(0xFFE63946); // Red
            } else {
              bgColor = const Color(0xFF9E9E9E); // Grey (Draw)
            }

            return Container(
              margin: const EdgeInsets.only(left: 6),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                result.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
