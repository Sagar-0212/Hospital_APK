import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/admin_actions_service.dart';
import '../models/appointment.dart';
import '../models/app_user.dart';
import '../models/medical_record.dart';
import '../models/prescription.dart';
import '../models/clinical_note.dart';

// Export auth providers
export '../services/auth_service.dart'
    show authServiceProvider, authStateProvider, currentUserProvider;

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

final adminActionsServiceProvider = Provider<AdminActionsService>(
  (ref) => AdminActionsService(),
);

// Patient Providers
final patientAppointmentsProvider = StreamProvider<List<Appointment>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.read(firestoreServiceProvider).getPatientAppointments(user.id);
});

final patientPrescriptionsProvider = StreamProvider<List<Prescription>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.read(firestoreServiceProvider).getPatientPrescriptions(user.id);
});

final availableDoctorsProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.read(firestoreServiceProvider).getAvailableDoctors();
});

final patientRecordsProvider =
    StreamProvider.family<List<MedicalRecord>, String>((ref, patientId) {
      return ref.read(firestoreServiceProvider).getPatientRecords(patientId);
    });

// Doctor Providers
final doctorAppointmentsProvider = StreamProvider<List<Appointment>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.read(firestoreServiceProvider).getDoctorAppointments(user.id);
});

final doctorPatientsProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>(
  (ref) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider);
    return appointmentsAsync.whenData((appointments) {
      final uniquePatients = <String, Map<String, dynamic>>{};
      for (var app in appointments) {
        if (!uniquePatients.containsKey(app.patientId)) {
          uniquePatients[app.patientId] = {
            'id': app.patientId,
            'name': app.patientName,
            'lastVisit': app.date,
          };
        } else {
          DateTime last = uniquePatients[app.patientId]!['lastVisit'];
          if (app.date.isAfter(last)) {
            uniquePatients[app.patientId]!['lastVisit'] = app.date;
          }
        }
      }
      return uniquePatients.values.toList();
    });
  },
);

final patientNotesProvider = StreamProvider.family<List<ClinicalNote>, String>((
  ref,
  patientId,
) {
  return ref.read(firestoreServiceProvider).getPatientNotes(patientId);
});

// Admin Providers
final pendingDoctorsProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.read(firestoreServiceProvider).getPendingDoctors();
});

final approvedDoctorsProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.read(firestoreServiceProvider).getApprovedDoctors();
});

final allDoctorsProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.read(firestoreServiceProvider).getAllDoctors();
});

final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.read(firestoreServiceProvider).getAllUsers();
});
