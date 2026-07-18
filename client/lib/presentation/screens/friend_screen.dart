import 'package:flutter/material.dart';
import 'package:client/core/theme/app_theme.dart';

class FriendScreen extends StatelessWidget {
  const FriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Bạn bè',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: AppTheme.primaryBlue.withOpacity(0.5)),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Tính năng đang phát triển',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
