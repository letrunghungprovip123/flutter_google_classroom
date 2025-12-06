import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentShellPage extends StatelessWidget {
  const StudentShellPage({super.key, required this.child});

  final Widget child;

  static const List<String> tabs = [
    '/student/home',
    '/student/dashboard',
    '/student/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    /// 🔥 Determine selectedIndex từ URL
    int index = tabs.indexWhere((t) => location.startsWith(t));
    if (index == -1) index = 0;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      body: child,

      bottomNavigationBar: NavigationBar(
        height: 65,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedIndex: index,
        indicatorColor: Colors.blueAccent.withOpacity(0.25),
        animationDuration: const Duration(milliseconds: 250),

        onDestinationSelected: (i) {
          context.go(tabs[i]); // 🔥 Không dùng setState!
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.class_rounded, color: Colors.white70),
            selectedIcon: Icon(Icons.class_rounded, color: Colors.blueAccent),
            label: "Classes",
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard, color: Colors.white70),
            selectedIcon: Icon(Icons.dashboard, color: Colors.blueAccent),
            label: "Dashboard",
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user, color: Colors.white70),
            selectedIcon: Icon(Icons.verified_user, color: Colors.blueAccent),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
