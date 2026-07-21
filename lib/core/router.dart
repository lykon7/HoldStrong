import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/models/celebration_data.dart';
import '../domain/providers/goal_providers.dart';
import '../ui/home/home_screen.dart';
import '../ui/log/log_screen.dart';
import '../ui/celebration/celebration_screen.dart';
import '../ui/resists/resists_screen.dart';
import '../ui/goals/goal_form_screen.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/transactions/transactions_screen.dart';
import '../ui/transactions/recurring_screen.dart';
import '../ui/funds/funds_screen.dart';
import '../ui/journal/journal_screen.dart';
import '../ui/journal/journal_entry_screen.dart';
import '../ui/hub/hub_screen.dart';
import '../ui/wishlist/wishlist_screen.dart';
import '../ui/workout/workout_screen.dart';
import '../ui/todo/todo_screen.dart';
import '../ui/liabilities/liabilities_screen.dart';
import '../ui/analysis/analysis_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final activeGoalNotifier = ref.watch(activeGoalProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAtGoalNew = state.matchedLocation == '/goals/new';
      return activeGoalNotifier.when(
        data: (goal) {
          if (goal == null && !isAtGoalNew) return '/goals/new';
          return null;
        },
        loading: () => null,
        error: (_, __) => null,
      );
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/workout',
            builder: (context, state) => const WorkoutScreen(),
          ),
          GoRoute(
            path: '/history',
            redirect: (context, state) => '/hub/resists',
          ),
          GoRoute(
            path: '/goals',
            redirect: (context, state) => '/hub/resists',
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/recurring',
            builder: (context, state) => const RecurringScreen(),
          ),
          GoRoute(
            path: '/expenses',
            redirect: (context, state) => '/transactions',
          ),
          GoRoute(
            path: '/income',
            redirect: (context, state) => '/transactions',
          ),
          GoRoute(
            path: '/funds',
            builder: (context, state) => const FundsScreen(),
          ),
          GoRoute(
            path: '/hub',
            builder: (context, state) => const HubScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/hub/journal',
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: '/hub/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/hub/resists',
        builder: (context, state) => const ResistsScreen(),
      ),
      GoRoute(
        path: '/hub/todo',
        builder: (context, state) => const TodoScreen(),
      ),
      GoRoute(
        path: '/hub/liabilities',
        builder: (context, state) => const LiabilitiesScreen(),
      ),
      GoRoute(
        path: '/hub/analysis',
        builder: (context, state) => const AnalysisScreen(),
      ),
      GoRoute(
        path: '/log',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const LogScreen(),
          transitionsBuilder: (context, animation, secondary, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/celebration',
        pageBuilder: (context, state) {
          final data = state.extra as CelebrationData?;
          return CustomTransitionPage(
            child: data != null
                ? CelebrationScreen(data: data)
                : const HomeScreen(),
            transitionsBuilder: (context, animation, secondary, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/goals/new',
        builder: (context, state) => const GoalFormScreen(),
      ),
      GoRoute(
        path: '/goals/:uuid/edit',
        builder: (context, state) {
          final uuid = state.pathParameters['uuid']!;
          return GoalFormScreen(goalUuid: uuid);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/journal/:date',
        builder: (context, state) {
          final dateStr = state.pathParameters['date']!;
          return JournalEntryScreen(dateString: dateStr);
        },
      ),
    ],
  );
});

class _MainShell extends ConsumerWidget {
  const _MainShell({required this.child});
  final Widget child;

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/workout')) {
      return 1;
    }
    if (location.startsWith('/transactions') ||
        location.startsWith('/recurring') ||
        location.startsWith('/expenses') ||
        location.startsWith('/income')) {
      return 2;
    }
    if (location.startsWith('/funds')) {
      return 3;
    }
    if (location.startsWith('/hub')) {
      return 4;
    }
    return 0;
  }

  static const _tabs = ['/', '/workout', '/transactions', '/funds', '/hub'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          context.go(_tabs[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'HOME'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'WORKOUT'),
          NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'TRANSACTIONS'),
          NavigationDestination(icon: Icon(Icons.savings_outlined), label: 'FUNDS'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'HUB'),
        ],
      ),
    );
  }
}

