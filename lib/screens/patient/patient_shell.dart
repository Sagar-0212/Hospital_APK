import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';

class PatientShell extends StatelessWidget {
  final Widget child;
  const PatientShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: NavigationBar(
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: AppColors.primaryLight,
            selectedIndex: _calculateSelectedIndex(context),
            onDestinationSelected: (int idx) => _onItemTapped(idx, context),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_filled), label: 'HOME'),
              NavigationDestination(icon: Icon(Icons.calendar_month), label: 'SCHEDULE'),
              NavigationDestination(icon: Icon(Icons.receipt_long), label: 'REPORTS'),
              NavigationDestination(icon: Icon(Icons.person), label: 'PROFILE'),
            ],
          ),
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/patient/home')) return 0;
    if (location.startsWith('/patient/schedule')) return 1;
    if (location.startsWith('/patient/reports')) return 2;
    if (location.startsWith('/patient/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/patient/home'); break;
      case 1: context.go('/patient/schedule'); break;
      case 2: context.go('/patient/reports'); break;
      case 3: context.go('/patient/profile'); break;
    }
  }
}
