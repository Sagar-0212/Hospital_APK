import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../providers/app_providers.dart';
import '../../models/appointment.dart';
import '../../models/app_user.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  AppUser? _selectedDoctor;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  String _searchQuery = '';
  String _selectedSpecialty = 'All';

  final List<String> _specialties = [
    'All',
    'General',
    'Cardiology',
    'Neurology',
    'Pediatrics',
    'Dentistry',
  ];

  void _book() async {
    if (_selectedDoctor == null || _selectedTimeSlot == null) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final appointment = Appointment(
      id: const Uuid().v4(),
      patientId: user.id,
      patientName: user.name,
      doctorId: _selectedDoctor!.id,
      doctorName: _selectedDoctor!.name,
      date: _selectedDate,
      timeSlot: _selectedTimeSlot!,
      status: 'pending',
      type: 'Consultation',
    );

    try {
      await ref.read(firestoreServiceProvider).createAppointment(appointment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent to ${_selectedDoctor!.name}!'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
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
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(availableDoctorsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'New Booking',
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
          if (_selectedDoctor == null) _buildSearchAndFilters(),
          if (_selectedDoctor != null) _buildSelectedDoctorHeader(),
          Expanded(
            child: _selectedDoctor == null
                ? _buildDoctorList(doctorsAsync)
                : _buildDateTimeSelection(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildSelectedDoctorHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(
              _selectedDoctor!.name[0],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
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
                  _selectedDoctor!.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Available for consultation',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _selectedDoctor = null;
              _selectedTimeSlot = null;
            }),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorList(AsyncValue<List<AppUser>> doctorsAsync) {
    return doctorsAsync.when(
      data: (doctors) {
        final filtered = doctors.where((doc) {
          final mS = doc.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
          final mSpec =
              _selectedSpecialty == 'All' || doc.role == _selectedSpecialty;
          return mS && mSpec;
        }).toList();
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'No matching doctors found',
              style: GoogleFonts.inter(color: AppColors.textHint),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: filtered.length,
          itemBuilder: (context, i) => _buildDoctorCard(filtered[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildDateTimeSelection() {
    // UPDATED: Dynamically fetch slots based on the day of the week
    final selectedDayName = DateFormat('EEEE').format(_selectedDate);
    final hours = _selectedDoctor?.clinicalHours?[selectedDayName] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Appointment Date',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildHorizontalDatePicker(),
          const SizedBox(height: 32),
          Text(
            'Available Slots on $selectedDayName',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Tailored to doctor\'s daily clinical hours',
            style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (hours.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_busy,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This doctor is not available on $selectedDayName. Please choose another date.',
                      style: GoogleFonts.inter(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            _buildTimeSlotGrid(hours),
        ],
      ),
    );
  }

  Widget _buildHorizontalDatePicker() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, i) {
          final date = DateTime.now().add(Duration(days: i + 1));
          final isSelected =
              DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(_selectedDate);
          return GestureDetector(
            onTap: () => setState(() {
              _selectedDate = date;
              _selectedTimeSlot = null;
            }),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardGray,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white70 : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotGrid(List<String> hours) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: hours.length,
      itemBuilder: (context, i) {
        final time = hours[i];
        final isSelected = _selectedTimeSlot == time;
        return GestureDetector(
          onTap: () => setState(() => _selectedTimeSlot = time),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.cardGray,
              ),
            ),
            child: Center(
              child: Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: AppColors.background,
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search specialists...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _specialties.map((spec) {
                final isS = _selectedSpecialty == spec;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(spec),
                    selected: isS,
                    onSelected: (s) =>
                        setState(() => _selectedSpecialty = spec),
                    selectedColor: AppColors.primary,
                    labelStyle: GoogleFonts.inter(
                      color: isS ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isS ? Colors.transparent : AppColors.cardGray,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(AppUser doc) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDoctor = doc;
        _selectedTimeSlot = null;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  doc.name[0],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    doc.role.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '4.9',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    final canBook = _selectedDoctor != null && _selectedTimeSlot != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: canBook ? _book : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              disabledBackgroundColor: AppColors.cardGray,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              _selectedDoctor == null
                  ? 'Select Specialist'
                  : (_selectedTimeSlot == null
                        ? 'Choose a Time'
                        : 'Confirm Request'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
