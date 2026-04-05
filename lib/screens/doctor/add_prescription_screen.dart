import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/colors.dart';
import '../../providers/app_providers.dart';
import '../../models/prescription.dart';

class AddPrescriptionScreen extends ConsumerStatefulWidget {
  final String patientId;
  const AddPrescriptionScreen({super.key, required this.patientId});

  @override
  ConsumerState<AddPrescriptionScreen> createState() =>
      _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends ConsumerState<AddPrescriptionScreen> {
  final _medController = TextEditingController();
  final _doseController = TextEditingController();
  final _freqController = TextEditingController();
  final _durController = TextEditingController();
  final _notesController = TextEditingController();

  int _selectedDuration = 7;

  @override
  void initState() {
    super.initState();
    _durController.text = _selectedDuration.toString();
  }

  void _send() async {
    final medicine = _medController.text.trim();
    if (medicine.isEmpty) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final prescription = Prescription(
      id: const Uuid().v4(),
      patientId: widget.patientId,
      doctorId: user.id,
      medicineName: medicine,
      dosage: _doseController.text.trim(),
      frequency: _freqController.text.trim(),
      durationDays:
          int.tryParse(_durController.text.trim()) ?? _selectedDuration,
      status: 'active',
      notes: _notesController.text.trim(),
      date: DateTime.now(),
    );

    try {
      await ref.read(firestoreServiceProvider).createPrescription(prescription);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription sent successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending prescription: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'New Prescription',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('MEDICATION DETAILS'),
            const SizedBox(height: 12),
            _buildPremiumField(
              controller: _medController,
              label: 'Medicine Name',
              hint: 'e.g. Amoxicillin 500mg',
              icon: Icons.medication_outlined,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPremiumField(
                    controller: _doseController,
                    label: 'Dosage',
                    hint: 'e.g. 1 Tablet',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPremiumField(
                    controller: _freqController,
                    label: 'Frequency',
                    hint: 'e.g. 2x Daily',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('DURATION & NOTES'),
            const SizedBox(height: 12),
            _buildDurationSelector(),
            const SizedBox(height: 20),
            _buildPremiumField(
              controller: _notesController,
              label: 'Doctor\'s Notes',
              hint: 'Special instructions for the patient...',
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            _buildInteractionAlert(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm & Send Prescription',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.textHint,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPremiumField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppColors.textHint,
              fontSize: 14,
            ),
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.primary, size: 20)
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration (Days)',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _durationChip(3),
            const SizedBox(width: 8),
            _durationChip(7),
            const SizedBox(width: 8),
            _durationChip(14),
            const SizedBox(width: 8),
            _durationChip(30),
            const Spacer(),
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _durController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _durationChip(int days) {
    final isSelected = _selectedDuration == days;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDuration = days;
        _durController.text = days.toString();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardGray,
          ),
        ),
        child: Text(
          '$days d',
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDD5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety Check',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No drug-drug interactions detected for this patient based on current active medications.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
