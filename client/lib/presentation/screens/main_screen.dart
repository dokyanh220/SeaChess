import 'package:flutter/material.dart';
import 'package:client/presentation/screens/lobby_screen.dart';
import 'package:client/presentation/screens/friends_screen.dart';
import 'package:client/presentation/screens/settings_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/presentation/providers/notification_providers.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notificationState = ref.watch(notificationStateProvider);
    final pendingCount = notificationState.pendingRequestsCount;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          LobbyScreen(),
          FriendsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        selectedItemColor: colorScheme.tertiary,
        unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.4),
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onTabTapped,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text(pendingCount.toString()),
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.people_alt_rounded),
            ),
            label: 'Friends',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
