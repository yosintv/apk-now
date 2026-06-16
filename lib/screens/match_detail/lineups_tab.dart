import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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
  final String? teamAManager;
  final String? teamBManager;

  const LineupsTab({
    super.key,
    required this.teamAFormation,
    required this.teamBFormation,
    required this.teamALineup,
    required this.teamBLineup,
    required this.teamAUnavailable,
    required this.teamBUnavailable,
    this.teamAManager,
    this.teamBManager,
  });

  @override
  Widget build(BuildContext context) {
    final tAManager = teamAManager;
    final tBManager = teamBManager;

    final bool hasNoData = teamALineup.isEmpty && 
                           teamBLineup.isEmpty && 
                           teamAUnavailable.isEmpty && 
                           teamBUnavailable.isEmpty &&
                           (tAManager == null || tAManager.isEmpty) &&
                           (tBManager == null || tBManager.isEmpty);

    if (hasNoData) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (teamALineup.isNotEmpty || teamBLineup.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F3F5)),
            ),
            child: Column(
              children: [
                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (teamAFormation.isNotEmpty)
                        _buildFormationPill(teamAFormation)
                      else
                        const SizedBox(),
                      const Text(
                        'Line-ups',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                      if (teamBFormation.isNotEmpty)
                        _buildFormationPill(teamBFormation)
                      else
                        const SizedBox(),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F3F5)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildParallelColumns(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if ((tAManager != null && tAManager.isNotEmpty) ||
            (tBManager != null && tBManager.isNotEmpty)) ...[
          _buildManagersRow(tAManager, tBManager),
          const SizedBox(height: 16),
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
        border: Border.all(color: const Color(0xFFF1F3F5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lineup data not available for this match',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormationPill(String formation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
      child: Text(formation, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildParallelColumns() {
    final int maxRows = teamALineup.length > teamBLineup.length ? teamALineup.length : teamBLineup.length;
    return Column(
      children: List.generate(maxRows, (index) {
        final Player? playerA = index < teamALineup.length ? teamALineup[index] : null;
        final Player? playerB = index < teamBLineup.length ? teamBLineup[index] : null;
        final bool isLast = index == maxRows - 1;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: playerA != null
                        ? Row(children: [
                            _buildSquadNumber(playerA.number),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                playerA.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ])
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 18, color: const Color(0xFFE9ECEF)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: playerB != null
                        ? Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Expanded(
                              child: Text(
                                playerB.name,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildSquadNumber(playerB.number),
                          ])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            if (!isLast) const Divider(height: 1, color: Color(0xFFF8F9FA)),
          ],
        );
      }),
    );
  }

  Widget _buildManagersRow(String? managerA, String? managerB) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F3F5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MANAGER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(managerA ?? 'TBD', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 30, color: const Color(0xFFE9ECEF)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('MANAGER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(managerB ?? 'TBD', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadNumber(String number) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withOpacity(0.18), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(number, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary)),
    );
  }

  Widget _buildUnavailableSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F3F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('UNAVAILABLE / MISSING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildMissingList(teamAUnavailable, alignment: CrossAxisAlignment.start)),
              const SizedBox(width: 16),
              Expanded(child: _buildMissingList(teamBUnavailable, alignment: CrossAxisAlignment.end)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissingList(List<String> players, {required CrossAxisAlignment alignment}) {
    if (players.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: alignment,
      children: players.map((name) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          name, 
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600), 
          textAlign: alignment == CrossAxisAlignment.start ? TextAlign.left : TextAlign.right
        ),
      )).toList(),
    );
  }
}
