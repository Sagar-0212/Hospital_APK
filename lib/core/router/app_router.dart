import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/patient/patient_shell.dart';
import '../../screens/patient/patient_dashboard.dart';
import '../../screens/patient/patient_schedule.dart';
import '../../screens/patient/patient_reports.dart';
import '../../screens/patient/book_appointment_screen.dart';
import '../../screens/doctor/doctor_shell.dart';
import '../../screens/doctor/doctor_dashboard.dart';
import '../../screens/doctor/doctor_schedule.dart';
import '../../screens/doctor/doctor_patients.dart';
import '../../screens/doctor/clinical_notes_screen.dart';
import '../../screens/doctor/add_prescription_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/admin/admin_shell.dart';
import '../../screens/admin/admin_dashboard.dart';
import '../../screens/admin/admin_manage_doctors.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // While loading, stay put
      if (authState.isLoading) return null;

      final isAuth = authState.value != null;
      final isOnLogin = state.uri.toString() == '/login';

      if (!isAuth && !isOnLogin) return '/login';
      if (isAuth && isOnLogin) {
        // Role-based redirect resolved after user doc is fetched
        return null; // Will be handled by LoginScreen itself via authStateProvider
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginRedirectWrapper(),
      ),
      // Patient Shell
      ShellRoute(
        builder: (context, state, child) => PatientShell(child: child),
        routes: [
          GoRoute(
            path: '/patient/home',
            builder: (context, state) => const PatientDashboardScreen(),
          ),
          GoRoute(
            path: '/patient/schedule',
            builder: (context, state) => const PatientScheduleScreen(),
            routes: [
              GoRoute(
                path: 'book',
                builder: (context, state) => const BookAppointmentScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/patient/reports',
            builder: (context, state) => const PatientReportsScreen(),
          ),
          GoRoute(
            path: '/patient/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      // Doctor Shell
      ShellRoute(
        builder: (context, state, child) => DoctorShell(child: child),
        routes: [
          GoRoute(
            path: '/doctor/home',
            builder: (context, state) => const DoctorDashboardScreen(),
          ),
          GoRoute(
            path: '/doctor/patients',
            builder: (context, state) => const DoctorPatientsScreen(),
            routes: [
              GoRoute(
                path: 'notes/:id/:name',
                builder: (context, state) => ClinicalNotesScreen(
                  patientId: state.pathParameters['id']!,
                  patientName: state.pathParameters['name']!,
                ),
              ),
              GoRoute(
                path: 'prescription/:id',
                builder: (context, state) => AddPrescriptionScreen(
                  patientId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/doctor/schedule',
            builder: (context, state) => const DoctorScheduleScreen(),
          ),
          GoRoute(
            path: '/doctor/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      // Admin Shell
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboard(),
          ),
          GoRoute(
            path: '/admin/doctors',
            builder: (context, state) => const AdminManageDoctors(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const Placeholder(), // To be created
          ),
          GoRoute(
            path: '/admin/logs',
            builder: (context, state) => const Placeholder(), // To be created
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const Placeholder(), // To be created
          ),
        ],
      ),
    ],
  );
});

// This widget handles post-login routing based on role
class LoginRedirectWrapper extends ConsumerWidget {
  const LoginRedirectWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userAsync = ref.watch(currentUserProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginScreen();
        return userAsync.when(
          data: (appUser) {
            if (appUser == null) return const LoginScreen();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (appUser.role == 'admin') {
                context.go('/admin/dashboard');
              } else if (appUser.role == 'doctor') {
                // Only redirect unapproved doctors to profile for approval wait
                if (!appUser.isApproved) {
                  context.go('/doctor/profile');
                } else {
                  context.go('/doctor/home');
                }
              } else {
                context.go('/patient/home');
              }
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => const LoginScreen(),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const LoginScreen(),
    );
  }
}
