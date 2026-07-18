import 'package:flutter/material.dart';
import 'package:client/core/theme/app_theme.dart';

class StatisticCard extends StatelessWidget {
  final int totalMatches;
  final int wins;
  final int losses;
  final int draws;
  final double winRate;

  const StatisticCard({
    super.key,
    required this.totalMatches,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'Tổng trận', totalMatches.toString(), Icons.sports_esports, AppTheme.primaryBlue),
                _buildStatItem(context, 'Thắng', wins.toString(), Icons.emoji_events, AppTheme.successGreen),
                _buildStatItem(context, 'Thua', losses.toString(), Icons.cancel, AppTheme.dangerRed),
                _buildStatItem(context, 'Hòa', draws.toString(), Icons.handshake, AppTheme.textSecondary),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.show_chart, color: AppTheme.primaryBlue, size: 20),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    'Tỷ lệ thắng: ${winRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
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

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
