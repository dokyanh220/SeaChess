import 'package:flutter/material.dart';
import 'package:client/core/theme/app_theme.dart';

class PlayerProfileCard extends StatelessWidget {
  final String username;
  final int elo;
  final int level;
  final int exp;
  final int maxExp;
  final String rank;
  final String avatarUrl;

  const PlayerProfileCard({
    super.key,
    required this.username,
    required this.elo,
    required this.level,
    required this.exp,
    required this.maxExp,
    required this.rank,
    this.avatarUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            // Avatar with Rank Border
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentGold, width: 2),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.secondaryBlue.withOpacity(0.3),
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 32, color: AppTheme.primaryBlue)
                    : null,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        username,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/rank/${rank.replaceAll(' ', '')}.png',
                              width: 16,
                              height: 16,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rank,
                              style: const TextStyle(
                                color: AppTheme.accentGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    'Elo: $elo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  
                  // EXP Bar
                  Row(
                    children: [
                      Text(
                        'Lv $level',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: exp / maxExp,
                            minHeight: 6,
                            backgroundColor: AppTheme.secondaryBlue.withOpacity(0.3),
                            color: AppTheme.primaryBlue,
                          ),
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
    );
  }
}
