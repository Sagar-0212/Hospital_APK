import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../core/theme/colors.dart';
import '../../models/appointment.dart';
import '../../models/app_user.dart';

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider);

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning,'
        : hour < 17
        ? 'Good afternoon,'
        : 'Good evening,';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) return const SizedBox();

            final allApps = appointmentsAsync.value ?? [];
            final pendingApps = allApps
                .where((a) => a.status == 'pending')
                .toList();
            final upcomingApps = allApps
                .where(
                  (a) => a.status == 'upcoming' || a.status == 'rescheduled',
                )
                .toList();
            final todayApps = upcomingApps
                .where(
                  (a) =>
                      DateFormat('yyyy-MM-dd').format(a.date) ==
                      DateFormat('yyyy-MM-dd').format(DateTime.now()),
                )
                .toList();

            final nextApp = upcomingApps.isNotEmpty ? upcomingApps.first : null;

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(doctorAppointmentsProvider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    _buildHero(greeting, user, upcomingApps.length),

                    if (pendingApps.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildPendingRequests(context, ref, pendingApps, user),
                    ],



                    const SizedBox(height: 24),
                    _buildUpcomingSection(context, appointmentsAsync),

                    const SizedBox(height: 24),
                    _buildPatientSummaries(context, appointmentsAsync),

                    const SizedBox(height: 24),
                    _buildActions(context),

                    const SizedBox(height: 20),
                    _buildDailySummary(todayApps, upcomingApps.length),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'CareConnect',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHero(String greeting, AppUser user, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting Dr.',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            user.name + (user.degree != null ? ' (${user.degree})' : ''),
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          if (user.specialization != null)
            Text(
              user.specialization!.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 1,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'You have $count upcoming appointments. Stay on top of your schedule.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequests(
    BuildContext context,
    WidgetRef ref,
    List<Appointment> pending,
    AppUser doctor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Requests',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${pending.length} NEW',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: pending.length,
            itemBuilder: (context, i) {
              final a = pending[i];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text(a.patientName[0]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.patientName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${DateFormat('MMM d').format(a.date)} • ${a.timeSlot}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Requested a ${a.type} for clinical review.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _showRescheduleDialog(context, ref, a, doctor),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: const BorderSide(color: AppColors.cardGray),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Reschedule',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => ref
                                .read(firestoreServiceProvider)
                                .updateAppointmentStatus(a.id, 'upcoming'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Approve',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRescheduleDialog(
    BuildContext context,
    WidgetRef ref,
    Appointment appt,
    AppUser doctor,
  ) {
    showDialog(
      context: context,
      builder: (context) => RescheduleDialog(appointment: appt, doctor: doctor),
    );
  }


  Widget _buildUpcomingSection(
    BuildContext context,
    AsyncValue<List<Appointment>> async,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Appointments',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/doctor/schedule'),
                child: Text(
                  'View Schedule',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          async.when(
            data: (appointments) {
              final list = appointments
                  .where(
                    (a) => a.status == 'upcoming' || a.status == 'rescheduled',
                  )
                  .toList();
              if (list.isEmpty) return _emptyApptCard();
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x0F000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.take(4).length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 70),
                  itemBuilder: (context, i) {
                    final a = list[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          a.patientName[0],
                          style: GoogleFonts.inter(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        a.patientName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        a.status == 'rescheduled' ? 'Rescheduled' : a.type,
                        style: GoogleFonts.inter(
                          color: a.status == 'rescheduled'
                              ? Colors.orange
                              : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            a.timeSlot,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              a.type,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSummaries(
    BuildContext context,
    AsyncValue<List<Appointment>> async,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Patient Summaries',
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        async.when(
          data: (appointments) {
            final seen = <String>{};
            final patients = appointments
                .where((a) => seen.add(a.patientId))
                .toList();
            if (patients.isEmpty) return const SizedBox();
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: patients.take(2).length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, i) => _patientSummaryCard(
                context,
                patients[i].patientId,
                patients[i].patientName,
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => context.go('/doctor/patients'),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add Prescription'),
        ),
      ),
    );
  }

  Widget _buildDailySummary(List<Appointment> today, int totalCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Summary',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          'Total Active',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white60,
                          ),
                        ),
                        Text(
                          '$totalCount',
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(width: 1, height: 60, color: Colors.white30),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                            'Today',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            '${today.length}',
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyApptCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          'No upcoming patients',
          style: TextStyle(color: AppColors.textHint),
        ),
      ),
    );
  }


  Widget _patientSummaryCard(
    BuildContext context,
    String patientId,
    String patientName,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(patientName[0]),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'PATIENT ID: #${patientId.substring(0, 6).toUpperCase()}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.success,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go(
                    '/doctor/patients/notes/$patientId/${Uri.encodeComponent(patientName)}',
                  ),
                  child: Text(
                    'View Records',
                    style: TextStyle(color: AppColors.primaryDark),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RescheduleDialog extends StatefulWidget {
  final Appointment appointment;
  final AppUser doctor;

  const RescheduleDialog({
    super.key,
    required this.appointment,
    required this.doctor,
  });

  @override
  State<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<RescheduleDialog> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;

  final List<String> _defaultHours = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEEE').format(_selectedDate);
    final hours = widget.doctor.clinicalHours?[dayName] ?? _defaultHours;

    return AlertDialog(
      title: Text(
        'Reschedule Appointment',
        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select New Date',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (d != null) setState(() => _selectedDate = d);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardGray),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Available Slot',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: hours.map((h) {
                final isSelected = _selectedTime == h;
                return ChoiceChip(
                  label: Text(
                    h,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (s) => setState(() => _selectedTime = h),
                  selectedColor: AppColors.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        Consumer(
          builder: (context, ref, _) => ElevatedButton(
            onPressed: _selectedTime == null
                ? null
                : () async {
                    await ref
                        .read(firestoreServiceProvider)
                        .rescheduleAppointment(
                          widget.appointment.id,
                          _selectedDate,
                          _selectedTime!,
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
            child: const Text('Confirm'),
          ),
        ),
      ],
    );
  }
}
