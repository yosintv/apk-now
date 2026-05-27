import 'package:flutter/material.dart';

class Player {
  final String number;
  final String name;

  const Player({required this.number, required this.name});
}

class LineupsTab extends StatelessWidget {
  final String teamAFormation;
  final String teamBFormation;
  final List<Player> teamALineup;
  final List<Player> teamBLineup;
  final List<String> teamAUnavailable;
  final List<String> teamBUnavailable;

  const LineupsTab({
    super.key,
    required this.teamAFormation,
    required this.teamBFormation,
    required this.teamALineup,
    required this.teamBLineup,
    required this.teamAUnavailable,
    required this.teamBUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasNoData = teamALineup.isEmpty && 
                           teamBLineup.isEmpty && 
                           teamAUnavailable.isEmpty && 
                           teamBUnavailable.isEmpty;

    if (hasNoData) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (teamALineup.isNotEmpty || teamBLineup.isNotEmpty) ...[
          _buildHeaderBar(),
          const SizedBox(height: 24),
          _buildParallelColumns(),
          const SizedBox(height: 32),
        ] else if (teamAUnavailable.isNotEmpty || teamBUnavailable.isNotEmpty) ...[
           // If only missing players are available
           _buildHeaderBar(title: 'Team News'),
           const SizedBox(height: 12),
        ] else ...[
          _buildEmptyState(),
        ],
        
        if (teamAUnavailable.isNotEmpty || teamBUnavailable.isNotEmpty)
          _buildUnavailableSection(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.withOpacity(0.5), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Lineup data not available for this match',
              style: TextStyle(fontSize: 14, color: Color(0xFF6C757D), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar({String title = 'Line-ups'}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (teamAFormation.isNotEmpty) _buildFormationPill(teamAFormation),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A)),
        ),
        if (teamBFormation.isNotEmpty) _buildFormationPill(teamBFormation),
      ],
    );
  }

  Widget _buildFormationPill(String formation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF0D1B2A), borderRadius: BorderRadius.circular(20)),
      child: Text(formation, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildParallelColumns() {
    final int maxRows = teamALineup.length > teamBLineup.length ? teamALineup.length : teamBLineup.length;
    return Column(
      children: List.generate(maxRows, (index) {
        final Player? playerA = index < teamALineup.length ? teamALineup[index] : null;
        final Player? playerB = index < teamBLineup.length ? teamBLineup[index] : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: playerA != null
                    ? Row(children: [_buildSquadNumber(playerA.number), const SizedBox(width: 10), Expanded(child: Text(playerA.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis))])
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: playerB != null
                    ? Row(mainAxisAlignment: MainAxisAlignment.end, children: [Expanded(child: Text(playerB.name, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)), const SizedBox(width: 10), _buildSquadNumber(playerB.number)])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSquadNumber(String number) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(color: Color(0xFFE9ECEF), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(number, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildUnavailableSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        children: [
          const Text('UNAVAILABLE / MISSING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildMissingList(teamAUnavailable, crossAxisAlignment: CrossAxisAlignment.start)),
              const SizedBox(width: 16),
              Expanded(child: _buildMissingList(teamBUnavailable, crossAxisAlignment: CrossAxisAlignment.end)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissingList(List<String> players, {required CrossAxisAlignment crossAxisAlignment}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: players.map((name) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFF495057), fontWeight: FontWeight.w500), textAlign: crossAxisAlignment == CrossAxisAlignment.start ? TextAlign.left : TextAlign.right),
      )).toList(),
    );
  }
}
