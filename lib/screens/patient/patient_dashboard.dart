import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/app_providers.dart';
import '../../services/record_service.dart';
import '../../models/medical_record.dart';
import '../../models/app_user.dart';
import '../../core/theme/colors.dart';

class PatientDashboardScreen extends ConsumerStatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  ConsumerState<PatientDashboardScreen> createState() =>
      _PatientDashboardScreenState();
}

class _PatientDashboardScreenState
    extends ConsumerState<PatientDashboardScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadRecord() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // Required for web support
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() => _isUploading = true);
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;

      final fileBytes = result.files.single.bytes!;
      final fileName = result.files.single.name;
      final imageUrl = await ref
          .read(recordServiceProvider)
          .uploadRecordBytes(user.id, fileBytes, fileName);

      final record = MedicalRecord(
        id: const Uuid().v4(),
        patientId: user.id,
        title: fileName,
        imageUrl: imageUrl,
        uploaderRole: 'patient',
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).createMedicalRecord(record);
      ref.invalidate(patientRecordsProvider(user.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record uploaded successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final appointmentsAsync = ref.watch(patientAppointmentsProvider);

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
            final recordsAsync = ref.watch(patientRecordsProvider(user.id));
            final upcomingApps =
                appointmentsAsync.value
                    ?.where(
                      (a) =>
                          a.status == 'upcoming' || a.status == 'rescheduled',
                    )
                    .toList() ??
                [];

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(patientAppointmentsProvider);
                ref.invalidate(patientRecordsProvider(user.id));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(user),
                    _buildHero(greeting, user.name, upcomingApps.length),
                    const SizedBox(height: 24),
                    _buildVitalsCard(),
                    const SizedBox(height: 24),
                    _buildUploadSection(),
                    const SizedBox(height: 24),
                    _buildUpcomingSection(
                      upcomingApps,
                      appointmentsAsync.isLoading,
                    ),
                    const SizedBox(height: 24),
                    _buildMedicalRecordsGallery(recordsAsync),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
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

  Widget _buildTopBar(AppUser user) {
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
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {},
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: GoogleFonts.inter(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHero(String greeting, String name, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You have $count upcoming appointments this week. Stay healthy!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/patient/schedule/book'),
              icon: const Icon(Icons.calendar_month, size: 18),
              label: const Text('Book Appointment'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0F000000),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vital Statistics',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _vitalRow(
              Icons.favorite,
              Colors.red,
              'HEART RATE',
              '72 bpm',
              'Normal',
            ),
            const Divider(height: 24),
            _vitalRow(Icons.air, Colors.teal, 'OXYGEN', '98 %', 'Optimal'),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
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
                const Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Medical Records',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your lab reports, prescriptions, or X-rays for your doctor to review.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _pickAndUploadRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                  elevation: 0,
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Upload New Image'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(List<dynamic> upcoming, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Upcoming Visits',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (upcoming.isEmpty)
          _emptyState('No appointments.')
        else
          ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: upcoming.length,
            itemBuilder: (context, i) {
              final app = upcoming[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(app.doctorName[0]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.doctorName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${DateFormat('MMM d').format(app.date)} · ${app.timeSlot}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        app.status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMedicalRecordsGallery(
    AsyncValue<List<MedicalRecord>> recordsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Your Records',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        recordsAsync.when(
          data: (records) {
            if (records.isEmpty) return _emptyState('No records uploaded yet.');
            return SizedBox(
              height: 160,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: records.length,
                itemBuilder: (context, i) {
                  final r = records[i];
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(16),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              InteractiveViewer(
                                child: Image.network(r.imageUrl),
                              ),
                              Positioned(
                                top: -10,
                                right: -10,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: NetworkImage(r.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          r.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _quickAction('Request Refill', Icons.medication_outlined),
          _quickAction('Message Doctor', Icons.chat_outlined),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(msg, style: TextStyle(color: AppColors.textHint)),
        ),
      ),
    );
  }

  Widget _vitalRow(
    IconData icon,
    Color iconColor,
    String label,
    String value,
    String status,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickAction(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
