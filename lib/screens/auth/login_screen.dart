import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../core/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isPatient = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regSpecCtrl = TextEditingController();
  final _regDegreeCtrl = TextEditingController();

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

  Future<void> _handleSignIn() async {
    if (_loginEmailCtrl.text.isEmpty || _loginPassCtrl.text.isEmpty) {
      _showError('Please enter email and password');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final role = isPatient ? 'patient' : 'doctor';
      await ref
          .read(authServiceProvider)
          .signIn(
            _loginEmailCtrl.text.trim(),
            _loginPassCtrl.text.trim(),
            role,
          );
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (_regNameCtrl.text.isEmpty ||
        _regEmailCtrl.text.isEmpty ||
        _regPassCtrl.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }
    if (_regPassCtrl.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final role = isPatient ? 'patient' : 'doctor';
      await ref
          .read(authServiceProvider)
          .register(
            _regEmailCtrl.text.trim(),
            _regPassCtrl.text.trim(),
            _regNameCtrl.text.trim(),
            role,
            specialization: isPatient ? null : _regSpecCtrl.text.trim(),
            degree: isPatient ? null : _regDegreeCtrl.text.trim(),
          );
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient Decor
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  // Logo Section
                  _buildHeader(),
                  const SizedBox(height: 48),

                  // Role Selection Toggle
                  _buildRoleToggle(),
                  const SizedBox(height: 32),

                  // Sign In / Register Tabs
                  _buildAuthTabs(),
                  const SizedBox(height: 32),

                  // Form Content
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _tabController.index == 0 ? 320 : 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildSignInForm(), _buildRegisterForm()],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildFooterInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'CareConnect',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDark,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Your health, our priority.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.cardGray,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Row(
        children: [
          _buildRoleTab('Patient', true, Icons.person_rounded),
          _buildRoleTab('Doctor', false, Icons.medical_services_rounded),
        ],
      ),
    );
  }

  Widget _buildRoleTab(String label, bool isPatientRole, IconData icon) {
    final isSelected =
        (isPatientRole && isPatient) || (!isPatientRole && !isPatient);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isPatient = isPatientRole),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) => setState(() {}),
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Existing User'),
          Tab(text: 'New User'),
        ],
      ),
    );
  }

  Widget _buildSignInForm() {
    return Column(
      children: [
        _buildInputField(
          _loginEmailCtrl,
          'Email Address',
          Icons.email_outlined,
          false,
        ),
        const SizedBox(height: 20),
        _buildInputField(
          _loginPassCtrl,
          'Password',
          Icons.lock_outline_rounded,
          true,
        ),
        const SizedBox(height: 32),
        _buildActionButton('Sign In to Account', _handleSignIn),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        _buildInputField(
          _regNameCtrl,
          'Full Name',
          Icons.person_outline_rounded,
          false,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          _regEmailCtrl,
          'Email Address',
          Icons.email_outlined,
          false,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          _regPassCtrl,
          'Password',
          Icons.lock_outline_rounded,
          true,
        ),
        if (!isPatient) ...[
          const SizedBox(height: 16),
          _buildInputField(
            _regSpecCtrl,
            'Specialization (e.g. Cardiology)',
            Icons.workspace_premium_outlined,
            false,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            _regDegreeCtrl,
            'Degree (e.g. MBBS, MD)',
            Icons.school_outlined,
            false,
          ),
        ],
        const SizedBox(height: 24),
        _buildActionButton(
          'Create ${isPatient ? "Patient" : "Doctor"} Profile',
          _handleRegister,
        ),
      ],
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint,
    IconData icon,
    bool isPassword,
  ) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: AppColors.textHint,
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildFooterInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        isPatient
            ? 'Manage your health easily. Access appointments, prescriptions, and safe medical records in one place.'
            : 'Deliver better care. Manage patients, clinical notes, and send prescriptions directly through the portal.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textHint,
          height: 1.4,
        ),
      ),
    );
  }
}
