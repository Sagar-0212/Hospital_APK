import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../core/theme/colors.dart';
import '../../models/appointment.dart';

class DoctorScheduleScreen extends ConsumerStatefulWidget {
  const DoctorScheduleScreen({super.key});
  @override
  ConsumerState<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends ConsumerState<DoctorScheduleScreen> {
  String _filter = 'Upcoming';
  final List<String> _filters = ['All', 'Pending', 'Upcoming', 'Rescheduled', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Clinical Schedule', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Manage your daily consultations and review pending patient requests.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                // Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _filters.map((filter) {
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
                    if (_filter == 'Upcoming') return a.status == 'upcoming' || a.status == 'rescheduled';
                    if (_filter == 'Rescheduled') return a.status == 'rescheduled';
                    if (_filter == 'Completed') return a.status == 'completed';
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _buildAppointmentCard(filtered[i]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      // DOCTOR SECTION: NO FLOATING ACTION BUTTON FOR BOOKING
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 64, color: AppColors.textHint.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No appointments scheduled', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('New requests will appear in the "Pending" section.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment app) {
    Color statusColor;
    String statusLabel;
    
    switch (app.status) {
      case 'pending': 
        statusColor = Colors.orange;
        statusLabel = 'PENDING REQUEST';
        break;
      case 'rescheduled':
        statusColor = Colors.blue;
        statusLabel = 'RESCHEDULED';
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
            CircleAvatar(radius: 26, backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Text(app.patientName[0], style: GoogleFonts.inter(color: AppColors.primaryDark, fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(app.patientName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
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
        Row(children: [
          Expanded(child: _infoBox(Icons.calendar_today_outlined, DateFormat('MMM dd, yyyy').format(app.date))),
          const SizedBox(width: 8),
          Expanded(child: _infoBox(Icons.access_time_outlined, app.timeSlot)),
        ]),
        const SizedBox(height: 16),
        Row(
          children: [
            if (app.status == 'pending') ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {}, // Reschedule logic handled in Dashboard or detailed view
                  child: const Text('Reschedule'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ref.read(firestoreServiceProvider).updateAppointmentStatus(app.id, 'upcoming'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Approve'),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {}, 
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white),
                  child: const Text('View Patient File'),
                ),
              ),
            ]
          ],
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
