import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../models/app_user.dart';
import '../../providers/app_providers.dart';
import '../../services/firestore_service.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pendingDoctors = ref.watch(pendingDoctorsProvider);
    final approvedDoctors = ref.watch(approvedDoctorsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab Navigation
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      label: '📋 Pending',
                      isActive: _selectedTabIndex == 0,
                      onTap: () => setState(() => _selectedTabIndex = 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTabButton(
                      label: '✅ Approved',
                      isActive: _selectedTabIndex == 1,
                      onTap: () => setState(() => _selectedTabIndex = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildPendingDoctorsView(pendingDoctors)
                : _buildApprovedDoctorsView(approvedDoctors),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive ? Colors.white : AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingDoctorsView(AsyncValue<List<AppUser>> doctorsAsync) {
    return doctorsAsync.when(
      data: (doctors) {
        if (doctors.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'All Caught Up!',
            message: 'No pending doctor approvals',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            return _buildDoctorCard(doctors[index], isPending: true);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Text(
          'Error: $error',
          style: GoogleFonts.inter(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildApprovedDoctorsView(AsyncValue<List<AppUser>> doctorsAsync) {
    return doctorsAsync.when(
      data: (doctors) {
        if (doctors.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_outline,
            title: 'No Approved Doctors',
            message: 'Approve doctors to see them here',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            return _buildDoctorCard(doctors[index], isPending: false);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Text(
          'Error: $error',
          style: GoogleFonts.inter(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(AppUser doctor, {required bool isPending}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.success.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Info
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isPending
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
                child: Text(
                  doctor.name[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: isPending ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.email,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joined ${DateFormat('MMM dd, yyyy').format(doctor.createdAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textHint,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPending
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isPending ? '⏳ Pending Approval' : '✅ Approved',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isPending ? AppColors.warning : AppColors.success,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Approve',
                    backgroundColor: AppColors.success,
                    textColor: Colors.white,
                    onTap: () => _approveDoctor(doctor.id),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: 'Reject',
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    textColor: AppColors.error,
                    onTap: () => _rejectDoctor(doctor.id, doctor.name),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            _buildActionButton(
              label: 'Block Doctor',
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              textColor: AppColors.error,
              onTap: () => _blockDoctor(doctor.id, doctor.name),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textHint.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _approveDoctor(String doctorId) {
    _showConfirmationDialog(
      title: 'Approve Doctor?',
      message: 'This doctor will be able to access all features.',
      confirmLabel: 'Approve',
      confirmColor: AppColors.success,
      onConfirm: () async {
        try {
          await FirestoreService().approveDoctor(doctorId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Doctor approved successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
    );
  }

  void _rejectDoctor(String doctorId, String doctorName) {
    _showConfirmationDialog(
      title: 'Reject Doctor?',
      message: '$doctorName will be removed from the system.',
      confirmLabel: 'Reject',
      confirmColor: AppColors.error,
      onConfirm: () async {
        try {
          await FirestoreService().rejectDoctor(doctorId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Doctor rejected!'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
    );
  }

  void _blockDoctor(String doctorId, String doctorName) {
    _showConfirmationDialog(
      title: 'Block Doctor?',
      message: '$doctorName will lose access to the system.',
      confirmLabel: 'Block',
      confirmColor: AppColors.error,
      onConfirm: () async {
        try {
          await FirestoreService().blockDoctor(doctorId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Doctor blocked!'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              confirmLabel,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: confirmColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
