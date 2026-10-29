import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/widgets/floating_nav_bar.dart';
import '../features/visitors/screens/dashboard_screen.dart';
import '../features/visitors/screens/qr_scanner_screen.dart';
import '../features/visitors/screens/visitor_details_screen.dart';
import '../features/visitors/screens/visitor_form_screen.dart';
import '../features/visitors/screens/visitor_list_screen.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/visitors',
                builder: (context, state) => const VisitorListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scan',
                builder: (context, state) => const QrScannerScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const VisitorFormScreen(),
      ),
      GoRoute(
        path: '/visitors/:id',
        builder: (context, state) => VisitorDetailsScreen(
          visitorId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/visitors/:id/edit',
        builder: (context, state) => VisitorFormScreen(
          visitorId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          FloatingNavItem(
            icon: Icons.space_dashboard_outlined,
            selectedIcon: Icons.space_dashboard_rounded,
            label: 'Dashboard',
          ),
          FloatingNavItem(
            icon: Icons.groups_outlined,
            selectedIcon: Icons.groups_rounded,
            label: 'Visitors',
          ),
          FloatingNavItem(
            icon: Icons.qr_code_scanner_rounded,
            selectedIcon: Icons.qr_code_scanner_rounded,
            label: 'Scan',
          ),
        ],
      ),
    );
  }
}
