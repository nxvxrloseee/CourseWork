import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/guest_screen.dart';
import 'screens/tickets_screen.dart';
import 'screens/create_ticket_screen.dart';
import 'screens/ticket_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';
import 'screens/notifications_screen.dart';
import 'widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/tickets',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final loc = state.matchedLocation;
      final publicRoute = loc == '/login' || loc == '/register' || loc == '/guest';

      if (!loggedIn && !publicRoute) return '/login';
      if (loggedIn && (loc == '/login' || loc == '/register' || loc == '/guest')) return '/tickets';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/guest', builder: (_, _) => const GuestScreen()),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/tickets', builder: (_, _) => const TicketsScreen()),
          GoRoute(path: '/tickets/create', builder: (_, _) => const CreateTicketScreen()),
          GoRoute(
            path: '/tickets/:id',
            builder: (_, state) => TicketDetailScreen(
              ticketId: int.parse(state.pathParameters['id']!),
              initialTab: state.uri.queryParameters['tab'],
              targetMessageId: int.tryParse(state.uri.queryParameters['msg'] ?? ''),
            ),
          ),
          GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
        ],
      ),
    ],
  );
});
