import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';

class DoctorShell extends StatelessWidget {
  final Widget child;
  const DoctorShell({super.key, required this.child});

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
              NavigationDestination(icon: Icon(Icons.people), label: 'PATIENTS'),
              NavigationDestination(icon: Icon(Icons.calendar_month), label: 'SCHEDULE'),
              NavigationDestination(icon: Icon(Icons.person), label: 'PROFILE'),
            ],
          ),
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/doctor/home')) return 0;
    if (location.startsWith('/doctor/patients')) return 1;
    if (location.startsWith('/doctor/schedule')) return 2;
    if (location.startsWith('/doctor/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/doctor/home'); break;
      case 1: context.go('/doctor/patients'); break;
      case 2: context.go('/doctor/schedule'); break;
      case 3: context.go('/doctor/profile'); break;
    }
  }
}
