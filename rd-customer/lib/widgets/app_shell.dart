import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notification_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith('/tickets')) currentIndex = 0;
    if (location == '/history') currentIndex = 1;
    if (location == '/profile') currentIndex = 2;
    if (location == '/notifications') currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/tickets');
            case 1: context.go('/history');
            case 2: context.go('/profile');
            case 3: context.go('/notifications');
          }
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.list_alt), label: 'Заявки'),
          const NavigationDestination(icon: Icon(Icons.history), label: 'История'),
          const NavigationDestination(icon: Icon(Icons.person), label: 'Профиль'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Уведомления',
          ),
        ],
      ),
    );
  }
}
