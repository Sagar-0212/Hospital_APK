import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_providers.dart';
import '../../core/theme/colors.dart';
import '../../models/app_user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _selectedDay = 'Monday';
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) return const SizedBox();
            final isDoctor = user.role == 'doctor';

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildAvatar(user),
                  const SizedBox(height: 14),
                  _buildNameSection(user, isDoctor),
                  const SizedBox(height: 20),
                  _buildInfoPills(user, isDoctor),
                  const SizedBox(height: 24),

                  if (isDoctor) ...[
                    _buildDoctorProfessionalDetails(context, ref, user),
                    const SizedBox(height: 24),
                    _buildDailyClinicalHoursSection(context, ref, user),
                    const SizedBox(height: 24),
                  ],

                  _buildStatsCard(isDoctor),
                  const SizedBox(height: 24),
                  _buildAccountSettings(context, ref),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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

  Widget _buildAvatar(AppUser user) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 54,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: GoogleFonts.inter(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified, color: Colors.white, size: 16),
        ),
      ],
    );
  }

  Widget _buildNameSection(AppUser user, bool isDoctor) {
    return Column(
      children: [
        Text(
          isDoctor ? 'Dr. ${user.name}' : user.name,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          isDoctor
              ? (user.specialization ?? 'Senior Specialist')
              : 'Patient',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.primary),
        ),
        if (isDoctor && user.degree != null)
          Text(
            user.degree!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoPills(AppUser user, bool isDoctor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _infoPill(Icons.email_outlined, user.email),
          const SizedBox(height: 10),
          _infoPill(
            Icons.location_on_outlined,
            isDoctor ? 'Global Medical Center' : 'CareConnect Patient Network',
          ),
        ],
      ),
    );
  }

  Widget _buildDailyClinicalHoursSection(
    BuildContext context,
    WidgetRef ref,
    AppUser doctor,
  ) {
    final allPossibleSlots = [
      '09:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '01:00 PM',
      '02:00 PM',
      '03:00 PM',
      '04:00 PM',
      '05:00 PM',
    ];
    final currentMap = doctor.clinicalHours ?? {};
    final currentDaySlots = currentMap[_selectedDay] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Clinical Availability',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const Icon(
                  Icons.calendar_month,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Day Selector with smooth animation
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _days.map((day) {
                  final isSel = _selectedDay == day;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDay = day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.cardGray,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          day.substring(0, 3),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSel ? Colors.white : AppColors.textPrimary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(
                key: ValueKey(_selectedDay),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Slots for $_selectedDay',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (currentDaySlots.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'No slots available for $_selectedDay',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentDaySlots.map((slot) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            slot,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: AppColors.cardGray, height: 1),
            const SizedBox(height: 16),
            Text(
              'Edit Availability',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allPossibleSlots.map((slot) {
                final isSelected = currentDaySlots.contains(slot);
                return GestureDetector(
                  onTap: () {
                    final updatedMap = Map<String, List<String>>.from(
                      currentMap,
                    );
                    final daySlots = List<String>.from(
                      updatedMap[_selectedDay] ?? [],
                    );
                    if (isSelected) {
                      daySlots.remove(slot);
                    } else {
                      daySlots.add(slot);
                    }
                    daySlots.sort();
                    updatedMap[_selectedDay] = daySlots;
                    ref
                        .read(firestoreServiceProvider)
                        .updateDoctorAvailability(doctor.id, updatedMap);
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.cardGray,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 4,
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      slot,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isDoctor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0F000000),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDoctor ? 'Clinical Activity' : 'Health Activity',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isDoctor ? 'Patients Seen' : 'Appointments',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
                Text(
                  isDoctor ? '1,284' : '15',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.85,
                backgroundColor: AppColors.cardGray,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Account Settings',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _settingsTile(
              Icons.security,
              Colors.blue,
              'Security & Privacy',
              'Password and Permissions',
              () {},
            ),
            _settingsTile(
              Icons.notifications_outlined,
              Colors.orange,
              'Notifications',
              'Alerts and Reminders',
              () {},
            ),
            _settingsTile(
              Icons.logout,
              AppColors.error,
              'Logout',
              'End current session',
              () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/login');
              },
              isRed: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorProfessionalDetails(
    BuildContext context,
    WidgetRef ref,
    AppUser doctor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Professional Details',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () => _showEditDoctorProfileDialog(context, ref, doctor),
                  icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (doctor.bio != null && doctor.bio!.isNotEmpty) ...[
              Text(
                'About',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                doctor.bio!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const Divider(height: 24),
            ],
            Row(
              children: [
                _profStat('Exp', '${doctor.experienceYears ?? 0} Yrs'),
                _profStat('Degree', doctor.degree ?? 'N/A'),
                _profStat('Spec', doctor.specialization ?? 'N/A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _profStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showEditDoctorProfileDialog(
    BuildContext context,
    WidgetRef ref,
    AppUser doctor,
  ) {
    final nameC = TextEditingController(text: doctor.name);
    final specC = TextEditingController(text: doctor.specialization);
    final degreeC = TextEditingController(text: doctor.degree);
    final bioC = TextEditingController(text: doctor.bio);
    final expC = TextEditingController(text: doctor.experienceYears?.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Professional Profile',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _editField('Full Name', nameC, Icons.person_outline),
              _editField('Specialization', specC, Icons.medical_services_outlined),
              _editField('Degree (e.g. MBBS, MD)', degreeC, Icons.school_outlined),
              _editField('Years of Experience', expC, Icons.work_outline, isNumeric: true),
              _editField('About / Bio', bioC, Icons.info_outline, maxLines: 4),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(firestoreServiceProvider).updateDoctorProfile(
                        uid: doctor.id,
                        name: nameC.text.trim(),
                        specialization: specC.text.trim(),
                        degree: degreeC.text.trim(),
                        bio: bioC.text.trim(),
                        experienceYears: int.tryParse(expC.text.trim()) ?? 0,
                      );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.cardGray),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(
    IconData icon,
    Color iconColor,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isRed = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isRed ? AppColors.error : iconColor, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: isRed ? AppColors.error : AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: isRed ? AppColors.error : AppColors.textHint,
      ),
    );
  }
}
