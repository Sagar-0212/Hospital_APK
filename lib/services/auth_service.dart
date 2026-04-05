import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/appointment.dart';
import 'firestore_service.dart';

// DEVELOPMENT MODE - Set to true to bypass firebase auth
// ignore: constant_identifier_names
const bool DEVELOPMENT_MODE = false;
// ignore: constant_identifier_names
const String DEV_USER_ROLE = 'doctor'; // 'patient', 'doctor', or 'admin'
// ignore: constant_identifier_names
const String DEV_USER_EMAIL = 'doctor@demo.com';
// ignore: constant_identifier_names
const String DEV_USER_NAME = 'Dr. Demo User';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  final firestoreService = FirestoreService();
  return firestoreService.getUserStream(user.uid);
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signIn(
    String email,
    String password,
    String expectedRole,
  ) async {
    try {
      // DEVELOPMENT MODE: Bypass Firebase auth
      if (DEVELOPMENT_MODE) {
        debugPrint('🔧 DEVELOPMENT MODE: Login bypassed for $DEV_USER_ROLE');
        debugPrint('   Email: $DEV_USER_EMAIL');
        debugPrint('   Role: $DEV_USER_ROLE');
        // Return null - development mode doesn't use real Firebase creds
        return null;
      }

      // 1. firebase auth sign in
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. verify role in firestore
      if (cred.user != null) {
        final fs = FirestoreService();
        final userDoc = await fs.getUser(cred.user!.uid);

        if (userDoc == null) {
          await _auth.signOut();
          throw Exception('User profile not found in database.');
        }

        if (userDoc.role != expectedRole) {
          await _auth.signOut();
          throw Exception(
            'This email is registered as a ${userDoc.role.toUpperCase()}. Please use the correct tab to login.',
          );
        }
      }
      return cred;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> register(
    String email,
    String password,
    String name,
    String role,
  ) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCred.user != null) {
        // Initialize default clinical hours for doctors
        Map<String, List<String>>? initialHours;
        if (role == 'doctor') {
          initialHours = {
            'Monday': [
              '09:00 AM',
              '10:00 AM',
              '11:00 AM',
              '01:00 PM',
              '02:00 PM',
              '03:00 PM',
              '04:00 PM',
            ],
            'Tuesday': [
              '09:00 AM',
              '10:00 AM',
              '11:00 AM',
              '01:00 PM',
              '02:00 PM',
              '03:00 PM',
              '04:00 PM',
            ],
            'Wednesday': [
              '09:00 AM',
              '10:00 AM',
              '11:00 AM',
              '01:00 PM',
              '02:00 PM',
              '03:00 PM',
              '04:00 PM',
            ],
            'Thursday': [
              '09:00 AM',
              '10:00 AM',
              '11:00 AM',
              '01:00 PM',
              '02:00 PM',
              '03:00 PM',
              '04:00 PM',
            ],
            'Friday': [
              '09:00 AM',
              '10:00 AM',
              '11:00 AM',
              '01:00 PM',
              '02:00 PM',
              '03:00 PM',
              '04:00 PM',
            ],
            'Saturday': ['10:00 AM', '11:00 AM', '12:00 PM'],
            'Sunday': [], // Closed by default
          };
        }

        final newUser = AppUser(
          id: userCred.user!.uid,
          name: name,
          email: email,
          role: role,
          createdAt: DateTime.now(),
          clinicalHours: initialHours,
          isApproved:
              role !=
              'doctor', // Doctors need admin approval, patients are auto-approved
        );

        final fs = FirestoreService();
        await fs.createUser(newUser);

        // Populate Dummy Demo Data
        if (role == 'doctor') {
          await fs.createAppointment(
            Appointment(
              id: 'demo_app_1',
              patientId: 'patient123',
              doctorId: newUser.id,
              patientName: 'Marcus Thorne',
              doctorName: newUser.name,
              date: DateTime.now().add(const Duration(hours: 2)),
              timeSlot: '09:00 AM',
              status: 'upcoming',
              type: 'Consultation',
            ),
          );
        } else {
          await fs.createAppointment(
            Appointment(
              id: 'demo_app_3',
              patientId: newUser.id,
              doctorId: 'doc123',
              patientName: newUser.name,
              doctorName: 'Dr. Elena Rossi',
              date: DateTime.now().add(const Duration(days: 1)),
              timeSlot: '10:00 AM',
              status: 'upcoming',
              type: 'Checkup',
            ),
          );
        }
      }
      return userCred;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
