import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/colors.dart';
import '../../providers/app_providers.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    // Security check: Only admins can access
    if (currentUser?.role != 'admin') {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Only admins can access this panel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final adminService = ref.watch(adminActionsServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${currentUser?.name}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _showLogoutConfirmation(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${currentUser?.name}!',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have full administrative access to the CareConnect system',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Statistics Section
            Text(
              'System Overview',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),

            // Stats Cards
            FutureBuilder<Map<String, dynamic>>(
              future: adminService.getAdminStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return Text(
                    'Unable to load statistics',
                    style: GoogleFonts.inter(color: AppColors.error),
                  );
                }

                final stats = snapshot.data!;
                return GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      title: 'Total Doctors',
                      value: stats['totalDoctors'].toString(),
                      icon: Icons.people,
                      color: AppColors.primary,
                    ),
                    _buildStatCard(
                      title: 'Approved',
                      value: stats['approvedDoctors'].toString(),
                      subtitle: 'doctors',
                      icon: Icons.verified,
                      color: AppColors.success,
                    ),
                    _buildStatCard(
                      title: 'Pending',
                      value: stats['pendingDoctors'].toString(),
                      subtitle: 'approvals',
                      icon: Icons.schedule,
                      color: AppColors.warning,
                    ),
                    _buildStatCard(
                      title: 'Total Users',
                      value: stats['totalUsers'].toString(),
                      icon: Icons.group,
                      color: Colors.blue,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Management Tools',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),

            // Action Cards
            _buildActionCard(
              context,
              icon: Icons.person_add,
              title: 'Manage Doctors',
              subtitle: 'Review and approve doctor registrations',
              color: AppColors.primary,
              onTap: () => context.go('/admin/doctors'),
            ),
            const SizedBox(height: 12),

            _buildActionCard(
              context,
              icon: Icons.group,
              title: 'All Users',
              subtitle: 'View and manage system users',
              color: Colors.blue,
              onTap: () => context.go('/admin/users'),
            ),
            const SizedBox(height: 12),

            _buildActionCard(
              context,
              icon: Icons.history,
              title: 'Activity Logs',
              subtitle: 'Track admin and system activities',
              color: Colors.purple,
              onTap: () => context.go('/admin/logs'),
            ),
            const SizedBox(height: 12),

            _buildActionCard(
              context,
              icon: Icons.settings,
              title: 'System Settings',
              subtitle: 'Configure system parameters',
              color: Colors.orange,
              onTap: () => context.go('/admin/settings'),
            ),
            const SizedBox(height: 32),

            // Recent Activity
            Text(
              'Recent Activity',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: adminService.getAdminLogs(limit: 5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardGray),
                    ),
                    child: Center(
                      child: Text(
                        'No recent activity',
                        style: GoogleFonts.inter(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                final logs = snapshot.data!;
                return Column(
                  children: [...logs.map((log) => _buildActivityItem(log))],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardGray),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> log) {
    final action = log['action'] as String? ?? 'Unknown';
    final targetName = log['targetName'] as String? ?? 'Unknown';
    final adminName = log['adminName'] as String? ?? 'System';
    final timestamp =
        (log['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardGray),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getActionColor(action).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getActionIcon(action),
              color: _getActionColor(action),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$adminName ${action.toLowerCase()} $targetName',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'blocked':
        return Icons.block;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'blocked':
        return AppColors.warning;
      case 'login':
        return AppColors.primary;
      case 'logout':
        return AppColors.textHint;
      default:
        return AppColors.textHint;
    }
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authServiceProvider).signOut();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
