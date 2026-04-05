import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../providers/app_providers.dart';
import '../../models/clinical_note.dart';
import '../../models/medical_record.dart';

class ClinicalNotesScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;
  const ClinicalNotesScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<ClinicalNotesScreen> createState() =>
      _ClinicalNotesScreenState();
}

class _ClinicalNotesScreenState extends ConsumerState<ClinicalNotesScreen> {
  final _noteController = TextEditingController();
  final _diagnosisController = TextEditingController();

  void _saveNote() async {
    final observation = _noteController.text.trim();
    if (observation.isEmpty) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final note = ClinicalNote(
      id: const Uuid().v4(),
      patientId: widget.patientId,
      doctorId: user.id,
      date: DateTime.now(),
      observation: observation,
      diagnosis: _diagnosisController.text.trim(),
    );

    try {
      await ref.read(firestoreServiceProvider).createClinicalNote(note);
      _noteController.clear();
      _diagnosisController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation note saved!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(patientNotesProvider(widget.patientId));
    final recordsAsync = ref.watch(patientRecordsProvider(widget.patientId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Clinical Records',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 0.5,
            height: 1.3,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildPatientHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('NEW CONSULTATION'),
                  const SizedBox(height: 12),
                  _buildNoteEntryCard(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('PATIENT UPLOADED RECORDS'),
                  const SizedBox(height: 16),
                  _buildMedicalRecordsGallery(recordsAsync),
                  const SizedBox(height: 32),
                  _buildSectionTitle('PREVIOUS RECORDS'),
                  const SizedBox(height: 16),
                  notesAsync.when(
                    data: (notes) {
                      if (notes.isEmpty) return _buildEmptyPreviousState();
                      final sortedNotes = List<ClinicalNote>.from(notes)
                        ..sort((a, b) => b.date.compareTo(a.date));
                      return Column(
                        children: sortedNotes
                            .map((n) => _buildPreviousNoteCard(n))
                            .toList(),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: AppColors.textHint,
        letterSpacing: 1.5,
        height: 1.4,
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  widget.patientName[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patientName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'Patient ID: #${widget.patientId.substring(0, 8)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Stable',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVitalItem(
                'Heart Rate',
                '72',
                'bpm',
                Icons.favorite,
                Colors.red,
              ),
              _buildVitalItem(
                'Blood Pressure',
                '120/80',
                'mmHg',
                Icons.speed,
                Colors.blue,
              ),
              _buildVitalItem(
                'Weight',
                '68',
                'kg',
                Icons.monitor_weight,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalItem(
    String label,
    String val,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.5), size: 22),
        const SizedBox(height: 6),
        Text(
          val,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            height: 1.2,
          ),
        ),
        Text(
          unit,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textHint,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteEntryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _diagnosisController,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Primary Diagnosis',
              hintStyle: GoogleFonts.inter(
                color: AppColors.textHint,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 5,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: 'Observations, symptoms, and clinical findings...',
              hintStyle: GoogleFonts.inter(
                color: AppColors.textHint,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Add consultation Record',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousNoteCard(ClinicalNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(note.date),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHint,
                  letterSpacing: 0.3,
                  height: 1.3,
                ),
              ),
              const Icon(Icons.more_horiz, color: AppColors.textHint, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          if (note.diagnosis.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Diagnosis: ${note.diagnosis}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                  letterSpacing: 0.2,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            note.observation,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.7,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPreviousState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.history_edu,
              size: 48,
              color: AppColors.textHint.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No previous clinical records',
              style: GoogleFonts.inter(
                color: AppColors.textHint,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalRecordsGallery(
    AsyncValue<List<MedicalRecord>> recordsAsync,
  ) {
    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                'No patient records uploaded.',
                style: GoogleFonts.inter(
                  color: AppColors.textHint,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          );
        }
        return SizedBox(
          height: 160,
          child: ListView.builder(
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
                          InteractiveViewer(child: Image.network(r.imageUrl)),
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
    );
  }
}
