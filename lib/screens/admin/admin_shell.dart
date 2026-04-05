import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';

class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({required this.child, super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late String _selectedRoute;

  @override
  void initState() {
    super.initState();
    _selectedRoute = _getCurrentRoute();
  }

  String _getCurrentRoute() {
    final location = GoRouterState.of(context).uri.toString();
    if (location.contains('/admin/doctors')) {
      return '/admin/doctors';
    } else if (location.contains('/admin/users')) {
      return '/admin/users';
    } else if (location.contains('/admin/logs')) {
      return '/admin/logs';
    }
    return '/admin/dashboard';
  }

  void _navigateTo(String route) {
    setState(() => _selectedRoute = route);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                // Logo Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'CareConnect',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Admin Panel',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _buildNavItem(
                        icon: Icons.dashboard,
                        label: 'Dashboard',
                        route: '/admin/dashboard',
                        isSelected: _selectedRoute == '/admin/dashboard',
                        onTap: () => _navigateTo('/admin/dashboard'),
                      ),
                      _buildNavItem(
                        icon: Icons.people,
                        label: 'Manage Doctors',
                        route: '/admin/doctors',
                        isSelected: _selectedRoute.contains('/admin/doctors'),
                        onTap: () => _navigateTo('/admin/doctors'),
                      ),
                      _buildNavItem(
                        icon: Icons.group,
                        label: 'All Users',
                        route: '/admin/users',
                        isSelected: _selectedRoute.contains('/admin/users'),
                        onTap: () => _navigateTo('/admin/users'),
                      ),
                      _buildNavItem(
                        icon: Icons.history,
                        label: 'Activity Logs',
                        route: '/admin/logs',
                        isSelected: _selectedRoute.contains('/admin/logs'),
                        onTap: () => _navigateTo('/admin/logs'),
                      ),
                      _buildNavItem(
                        icon: Icons.settings,
                        label: 'Settings',
                        route: '/admin/settings',
                        isSelected: _selectedRoute.contains('/admin/settings'),
                        onTap: () => _navigateTo('/admin/settings'),
                      ),
                    ],
                  ),
                ),

                // Bottom Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Icon(Icons.info, color: AppColors.textHint, size: 20),
                        const SizedBox(height: 8),
                        Text(
                          'Need help?',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Contact support',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String route,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textHint,
          size: 20,
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
