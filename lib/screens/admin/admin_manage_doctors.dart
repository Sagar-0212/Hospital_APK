import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../models/app_user.dart';
import '../../providers/app_providers.dart';
import '../../services/firestore_service.dart';

class AdminManageDoctors extends ConsumerStatefulWidget {
  const AdminManageDoctors({super.key});

  @override
  ConsumerState<AdminManageDoctors> createState() => _AdminManageDoctorsState();
}

class _AdminManageDoctorsState extends ConsumerState<AdminManageDoctors> {
  String _filterStatus = 'all'; // 'all', 'pending', 'approved'

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    // Security check
    if (currentUser?.role != 'admin') {
      return Scaffold(
        body: Center(
          child: Text(
            'Access Denied',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Doctor Management',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: FirestoreService().getAllDoctors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading doctors',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            );
          }

          final doctors = snapshot.data ?? [];
          if (doctors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No doctors registered yet',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // Filter doctors based on status
          final filteredDoctors = doctors.where((doc) {
            if (_filterStatus == 'pending') return !doc.isApproved;
            if (_filterStatus == 'approved') return doc.isApproved;
            return true;
          }).toList();

          return Column(
            children: [
              // Filter Tabs
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildFilterTab('All', 'all'),
                    const SizedBox(width: 12),
                    _buildFilterTab('Pending', 'pending'),
                    const SizedBox(width: 12),
                    _buildFilterTab('Approved', 'approved'),
                  ],
                ),
              ),

              // Doctor List
              Expanded(
                child: filteredDoctors.isEmpty
                    ? Center(
                        child: Text(
                          'No ${_filterStatus != 'all' ? _filterStatus : 'doctors'} found',
                          style: GoogleFonts.inter(
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filteredDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = filteredDoctors[index];
                          return _buildDoctorCard(doctor, context, ref);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardGray,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(AppUser doctor, BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: doctor.isApproved
              ? AppColors.warning.withValues(alpha: 0.1)
              : AppColors.success.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  doctor.name[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      doctor.email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: doctor.isApproved
                      ? AppColors.warning.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  doctor.isApproved ? 'Approved' : 'Pending',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: doctor.isApproved
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (doctor.approvedAt != null)
            Text(
              'Approved on ${DateFormat('MMM dd, yyyy').format(doctor.approvedAt!)}',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint),
            ),
          const SizedBox(height: 12),
          if (!doctor.isApproved)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveDoctor(doctor, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Approve',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showRejectDialog(doctor, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showBlockDialog(doctor, ref),
                    icon: const Icon(Icons.block),
                    label: Text(
                      'Block',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                      foregroundColor: AppColors.warning,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppColors.warning),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _approveDoctor(AppUser doctor, WidgetRef ref) async {
    try {
      await FirestoreService().approveDoctor(doctor.id);

      // Log the action
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        await ref
            .read(adminActionsServiceProvider)
            .logAdminAction(
              adminId: currentUser.id,
              adminName: currentUser.name,
              action: 'approved',
              targetType: 'doctor',
              targetId: doctor.id,
              targetName: doctor.name,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ ${doctor.name} approved successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error approving doctor: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showRejectDialog(AppUser doctor, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reject Doctor Registration?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to reject the registration of:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.email,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Note: This action will permanently delete their registration. This cannot be undone.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.warning,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _rejectDoctor(doctor, ref),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Reject',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _rejectDoctor(AppUser doctor, WidgetRef ref) async {
    try {
      Navigator.pop(context);

      await FirestoreService().rejectDoctor(doctor.id);

      // Log the action
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        await ref
            .read(adminActionsServiceProvider)
            .logAdminAction(
              adminId: currentUser.id,
              adminName: currentUser.name,
              action: 'rejected',
              targetType: 'doctor',
              targetId: doctor.id,
              targetName: doctor.name,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✗ ${doctor.name} registration rejected',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error rejecting doctor: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showBlockDialog(AppUser doctor, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Block Doctor?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to block:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.email,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Blocked doctors cannot access the system. You can unblock them later.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.warning,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _blockDoctor(doctor, ref),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text(
              'Block',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _blockDoctor(AppUser doctor, WidgetRef ref) async {
    try {
      Navigator.pop(context);

      await FirestoreService().blockDoctor(doctor.id);

      // Log the action
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        await ref
            .read(adminActionsServiceProvider)
            .logAdminAction(
              adminId: currentUser.id,
              adminName: currentUser.name,
              action: 'blocked',
              targetType: 'doctor',
              targetId: doctor.id,
              targetName: doctor.name,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⊘ ${doctor.name} has been blocked',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error blocking doctor: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
