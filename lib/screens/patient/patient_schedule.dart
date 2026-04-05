import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../core/theme/colors.dart';
import '../../models/appointment.dart';

class PatientScheduleScreen extends ConsumerStatefulWidget {
  const PatientScheduleScreen({super.key});
  @override
  ConsumerState<PatientScheduleScreen> createState() => _PatientScheduleScreenState();
}

class _PatientScheduleScreenState extends ConsumerState<PatientScheduleScreen> {
  String _filter = 'All Visits';

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(patientAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(7)), child: const Icon(Icons.favorite, color: Colors.white, size: 14)),
          const SizedBox(width: 8),
          Text('CareConnect', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary), onPressed: () {})],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Schedule', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Track your healthcare journey. Manage your upcoming consultations and review history.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                // Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: ['All Visits', 'Pending', 'Upcoming', 'Rescheduled', 'Complete'].map((filter) {
                    final sel = _filter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(color: sel ? AppColors.primaryDark : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: sel ? Colors.transparent : AppColors.cardGray)),
                          child: Text(filter, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.textSecondary, fontSize: 13)),
                        ),
                      ),
                    );
                  }).toList()),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: appointmentsAsync.when(
                data: (appointments) {
                  final filtered = appointments.where((a) {
                    if (_filter == 'Pending') return a.status == 'pending';
                    if (_filter == 'Upcoming') return a.status == 'upcoming';
                    if (_filter == 'Rescheduled') return a.status == 'rescheduled';
                    if (_filter == 'Complete') return a.status == 'completed';
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      ...filtered.map((app) => _buildAppointmentCard(context, app)),
                      const SizedBox(height: 100),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/patient/schedule/book'),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Book New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.textHint.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No appointments found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Try changing your filter or book a new one.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/patient/schedule/book'),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment app) {
    Color statusColor;
    String statusLabel;
    
    switch (app.status) {
      case 'pending': 
        statusColor = Colors.orange;
        statusLabel = 'WAITING APPROVAL';
        break;
      case 'rescheduled':
        statusColor = Colors.blue;
        statusLabel = 'RESCHEDULED';
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusLabel = 'CANCELLED';
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusLabel = 'COMPLETED';
        break;
      default:
        statusColor = AppColors.primary;
        statusLabel = 'UPCOMING';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0x0F000000), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            CircleAvatar(radius: 26, backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Text(app.doctorName[0], style: GoogleFonts.inter(color: AppColors.primaryDark, fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(app.doctorName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
              if (app.doctorSpecialization != null)
                Text(
                  '${app.doctorSpecialization}${app.doctorDegree != null ? " (${app.doctorDegree})" : ""}',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(app.type, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
            ]),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
            child: Text(statusLabel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
          ),
        ]),
        const SizedBox(height: 16),
        if (app.status == 'rescheduled') ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withValues(alpha: 0.1))),
            child: Row(children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Doctor has suggested a new time for your appointment.', style: GoogleFonts.inter(fontSize: 11, color: Colors.blue[800], fontWeight: FontWeight.w500))),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        if (app.status == 'cancelled') ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withValues(alpha: 0.1))),
            child: Row(children: [
              const Icon(Icons.warning_amber_outlined, color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Cancelled: ${app.cancellationReason ?? 'Doctor reason'}. Please rebook.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w500))),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        Row(children: [
          Expanded(child: _infoBox(Icons.calendar_today_outlined, DateFormat('MMM dd, yyyy').format(app.date))),
          const SizedBox(width: 8),
          Expanded(child: _infoBox(Icons.access_time_outlined, app.timeSlot)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (app.status == 'cancelled') context.go('/patient/schedule/book');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: app.status == 'pending' ? AppColors.cardGray : AppColors.primaryDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(app.status == 'pending' ? 'Pending Approval' : (app.status == 'cancelled' ? 'Rebook Now' : 'View Details')),
          ),
        ),
      ]),
    );
  }

  Widget _infoBox(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
