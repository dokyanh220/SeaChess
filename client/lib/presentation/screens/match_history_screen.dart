import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/presentation/providers/match_history_provider.dart';
import 'package:client/presentation/screens/replay_screen.dart';
import 'package:client/core/theme/app_theme.dart';

class MatchHistoryScreen extends ConsumerWidget {
  const MatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(matchHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Lịch Sử Trận Đấu',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryBlue),
      ),
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Lỗi: $err')),
          data: (historyList) {
            if (historyList.isEmpty) {
              return const Center(child: Text('Chưa có lịch sử trận đấu nào.'));
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              itemCount: historyList.length,
              itemBuilder: (context, index) {
                final match = historyList[index];
                
                String resultText;
                Color resultColor;
                if (match.result == 3) {
                  resultText = 'Hòa';
                  resultColor = Theme.of(context).colorScheme.onSurfaceVariant;
                } else if ((match.isWhite && match.result == 1) || (!match.isWhite && match.result == 2)) {
                  resultText = 'Thắng';
                  resultColor = AppTheme.successGreen;
                } else if (match.result == 0) {
                  resultText = 'Đang chờ';
                  resultColor = Theme.of(context).colorScheme.onSurfaceVariant;
                } else {
                  resultText = 'Thua';
                  resultColor = AppTheme.dangerRed;
                }
                
                return Card(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
                    leading: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: resultColor, width: 2),
                      ),
                      child: CircleAvatar(
                        backgroundColor: resultColor.withOpacity(0.1),
                        radius: 20,
                        child: Icon(
                          match.isWhite ? Icons.circle : Icons.circle_outlined,
                          color: match.isWhite ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                    title: Text(
                      'vs ${match.opponentName}', 
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        match.createdAt.toLocal().toString().substring(0, 16),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          resultText,
                          style: TextStyle(color: resultColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (match.pgn != null && match.pgn!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          const Icon(Icons.play_circle_fill, color: AppTheme.primaryBlue, size: 20),
                        ]
                      ],
                    ),
                    onTap: () {
                      if (match.pgn != null && match.pgn!.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ReplayScreen(match: match)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Trận đấu này không có dữ liệu Replay')),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
