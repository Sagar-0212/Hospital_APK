import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../providers/app_providers.dart';
import '../../models/prescription.dart';

class PatientReportsScreen extends ConsumerStatefulWidget {
  const PatientReportsScreen({super.key});

  @override
  ConsumerState<PatientReportsScreen> createState() =>
      _PatientReportsScreenState();
}

class _PatientReportsScreenState extends ConsumerState<PatientReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prescriptionsAsync = ref.watch(patientPrescriptionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Health Portfolio',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPrescriptionsTab(prescriptionsAsync),
                _buildRecordsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        onTap: (index) => setState(() {}),
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(width: 3.0, color: AppColors.primary),
          insets: EdgeInsets.symmetric(
            horizontal: (MediaQuery.of(context).size.width / 4) - 20,
          ),
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Prescriptions'),
          Tab(text: 'Lab Records'),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsTab(
    AsyncValue<List<Prescription>> prescriptionsAsync,
  ) {
    return prescriptionsAsync.when(
      data: (prescriptions) {
        if (prescriptions.isEmpty) {
          return _buildEmptyState(
            'No active prescriptions',
            Icons.medication_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: prescriptions.length,
          itemBuilder: (context, index) {
            final p = prescriptions[index];
            return _buildPrescriptionCard(p);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPrescriptionCard(Prescription p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.medicineName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.dosage,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge('Active'),
              ],
            ),
          ),
          const Divider(height: 1, indent: 24, endIndent: 24),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCol('Frequency', p.frequency, Icons.repeat),
                _buildInfoCol(
                  'Duration',
                  '${p.durationDays} Days',
                  Icons.calendar_today_outlined,
                ),
                _buildInfoCol('Refills', '2 Remaining', Icons.refresh_rounded),
              ],
            ),
          ),
          if (p.notes.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.cardGray,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.notes,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordsTab() {
    // Placeholder for Lab Records
    final fakeRecords = [
      {
        'title': 'Complete Blood Count',
        'date': 'Mar 24, 2024',
        'provider': 'City Health Lab',
        'status': 'Final',
      },
      {
        'title': 'ECG - Cardiology',
        'date': 'Feb 12, 2024',
        'provider': 'General Hospital',
        'status': 'Archived',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: fakeRecords.length,
      itemBuilder: (context, index) {
        final r = fakeRecords[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardGray.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.science_outlined, color: Colors.purple),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['title']!,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${r['date']} • ${r['provider']}',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.file_download_outlined,
                color: AppColors.primary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCol(String label, String val, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textHint),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textHint,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          val,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.success,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textHint.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            msg,
            style: GoogleFonts.inter(
              color: AppColors.textHint,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
