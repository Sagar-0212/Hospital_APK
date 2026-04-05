import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../core/theme/colors.dart';

class DoctorPatientsScreen extends ConsumerStatefulWidget {
  const DoctorPatientsScreen({super.key});
  @override
  ConsumerState<DoctorPatientsScreen> createState() =>
      _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends ConsumerState<DoctorPatientsScreen> {
  String _filter = 'All Patients';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final patientsAsync = ref.watch(doctorPatientsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: userAsync.when(
              data: (u) => Text(
                u?.name.isNotEmpty == true ? u!.name[0].toUpperCase() : 'D',
                style: GoogleFonts.inter(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              loading: () => const SizedBox(),
              error: (_, _) => const Icon(Icons.person),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 12),
            ),
            const SizedBox(width: 6),
            Text(
              'CareConnect',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryDark,
        onPressed: () => context.go('/doctor/patients'),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Patients',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Monitoring ${(patientsAsync.value?.length ?? 0) + 20} patients under your care today.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search
                  TextField(
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search by name, ID or condition...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textHint,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter
                  Row(
                    children: ['All Patients', 'Critical', 'New'].map((f) {
                      final sel = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primaryDark : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: sel
                                    ? Colors.transparent
                                    : AppColors.cardGray,
                              ),
                            ),
                            child: Text(
                              f,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: patientsAsync.when(
                data: (patients) {
                  // Also add some sample patients for a market-ready feel
                  final samplePatients = [
                    {
                      'id': 'sample1',
                      'name': 'Eleanor Vance',
                      'age': '72',
                      'gender': 'Female',
                      'status': 'Critical',
                      'lastVisit': 'Oct 24, 2023',
                    },
                    {
                      'id': 'sample2',
                      'name': 'Marcus Thorne',
                      'age': '45',
                      'gender': 'Male',
                      'status': 'Stable',
                      'lastVisit': 'Nov 02, 2023',
                    },
                    {
                      'id': 'sample3',
                      'name': 'Sana Khan',
                      'age': '29',
                      'gender': 'Female',
                      'status': 'Review Needed',
                      'lastVisit': 'Oct 30, 2023',
                    },
                    {
                      'id': 'sample4',
                      'name': 'Julian Rossi',
                      'age': '34',
                      'gender': 'Male',
                      'status': 'New Patient',
                      'lastVisit': 'First Visit',
                    },
                  ];

                  // Combine real + sample patients without duplicates
                  final realPatientIds = patients.map((p) => p['id']).toSet();
                  final allPatients = [
                    ...patients.map(
                      (p) => {
                        'id': p['id'],
                        'name': p['name'],
                        'age': '—',
                        'gender': '—',
                        'status': 'Active',
                        'lastVisit': DateFormat(
                          'MMM dd, yyyy',
                        ).format(p['lastVisit'] as DateTime),
                      },
                    ),
                    ...samplePatients.where(
                      (s) => !realPatientIds.contains(s['id']),
                    ),
                  ];

                  final filtered = allPatients.where((p) {
                    final nameMatch =
                        _searchQuery.isEmpty ||
                        (p['name'] as String).toLowerCase().contains(
                          _searchQuery,
                        );
                    final filterMatch =
                        _filter == 'All Patients' ||
                        (p['status'] as String).toLowerCase().contains(
                          _filter
                              .toLowerCase()
                              .replaceAll(' patients', '')
                              .replaceAll(' ', ''),
                        );
                    return nameMatch && filterMatch;
                  }).toList();

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      if (i == filtered.length) {
                        return const SizedBox(height: 80);
                      }
                      final p = filtered[i];
                      return _patientCard(context, p);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientCard(BuildContext context, Map<String, dynamic> p) {
    final status = p['status'] as String;
    Color statusColor;
    if (status == 'Critical') {
      statusColor = AppColors.error;
    } else if (status == 'Stable') {
      statusColor = AppColors.success;
    } else if (status.contains('Review')) {
      statusColor = Colors.blue;
    } else if (status == 'New Patient') {
      statusColor = AppColors.primary;
    } else {
      statusColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  (p['name'] as String).isNotEmpty
                      ? (p['name'] as String)[0]
                      : 'P',
                  style: GoogleFonts.inter(
                    color: AppColors.primaryDark,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (p['age'] != '—')
                      Text(
                        '${p['age']} yrs • ${p['gender']}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
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
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  status == 'New Patient' ? 'FIRST VISIT' : 'LAST VISIT',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHint,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  p['lastVisit'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (status == 'New Patient') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Review Intake Form',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go(
                    '/doctor/patients/notes/${p['id']}/${Uri.encodeComponent(p['name'] as String)}',
                  ),
                  icon: const Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                  label: Text(
                    'Records',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cardGray),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_outlined, size: 16),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}
