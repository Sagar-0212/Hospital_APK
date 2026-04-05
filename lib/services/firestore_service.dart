import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/appointment.dart';
import '../models/medical_record.dart';
import '../models/prescription.dart';
import '../models/clinical_note.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // USER Methods
  Future<void> createUser(AppUser user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, doc.id);
  }

  Stream<AppUser?> getUserStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return AppUser.fromMap(doc.data()!, doc.id);
        });
  }

  // UPDATED: Now supports Map structure
  Future<void> updateDoctorAvailability(
    String uid,
    Map<String, List<String>> hours,
  ) async {
    await _db.collection('users').doc(uid).update({'clinicalHours': hours});
  }

  Future<void> updateDoctorProfile({
    required String uid,
    required String name,
    required String specialization,
    required String degree,
    required String bio,
    required int experienceYears,
  }) async {
    await _db.collection('users').doc(uid).update({
      'name': name,
      'specialization': specialization,
      'degree': degree,
      'bio': bio,
      'experienceYears': experienceYears,
    });
  }

  // APPOINTMENT Methods
  Future<void> createAppointment(Appointment app) async {
    await _db.collection('appointments').doc(app.id).set(app.toMap());
  }

  Future<void> updateAppointmentStatus(
    String appId,
    String status, {
    String? reason,
  }) async {
    final data = {'status': status};
    if (reason != null) data['cancellationReason'] = reason;
    await _db.collection('appointments').doc(appId).update(data);
  }

  Future<void> rescheduleAppointment(
    String appId,
    DateTime date,
    String slot,
  ) async {
    await _db.collection('appointments').doc(appId).update({
      'date': Timestamp.fromDate(date),
      'timeSlot': slot,
      'status': 'rescheduled',
    });
  }

  // FIX: Use simple queries without orderBy to avoid composite index requirements.
  // Sorting is done in-memory after fetching.
  Stream<List<Appointment>> getPatientAppointments(String patientId) {
    return _db
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .handleError((error) {
          debugPrint('Firestore Error (patientAppointments): $error');
        })
        .map((snap) {
          final list = snap.docs
              .map((d) => Appointment.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Stream<List<Appointment>> getDoctorAppointments(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .handleError((error) {
          debugPrint('Firestore Error (doctorAppointments): $error');
        })
        .map((snap) {
          final list = snap.docs
              .map((d) => Appointment.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Stream<List<AppUser>> getAvailableDoctors() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .snapshots()
        .handleError((error) {
          debugPrint('Firestore Error (availableDoctors): $error');
        })
        .map(
          (snap) =>
              snap.docs.map((d) => AppUser.fromMap(d.data(), d.id)).toList(),
        );
  }

  // MEDICAL RECORDS Methods
  Future<void> createMedicalRecord(MedicalRecord record) async {
    await _db.collection('medical_records').doc(record.id).set(record.toMap());
  }

  Stream<List<MedicalRecord>> getPatientRecords(String patientId) {
    return _db
        .collection('medical_records')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .handleError((error) {
          debugPrint('Firestore Error (patientRecords): $error');
        })
        .map((snap) {
          final list = snap.docs
              .map((d) => MedicalRecord.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<Prescription>> getPatientPrescriptions(String patientId) {
    return _db
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .handleError((error) {
          debugPrint('Firestore Error (patientPrescriptions): $error');
        })
        .map((snap) {
          final list = snap.docs
              .map((d) => Prescription.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Future<void> createPrescription(Prescription prescription) async {
    await _db
        .collection('prescriptions')
        .doc(prescription.id)
        .set(prescription.toMap());
  }

  Stream<List<ClinicalNote>> getPatientNotes(String patientId) {
    return _db
        .collection('clinical_notes')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .handleError((error) {
          debugPrint('Firestore Error (patientNotes): $error');
        })
        .map((snap) {
          final list = snap.docs
              .map((d) => ClinicalNote.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Future<void> createClinicalNote(ClinicalNote note) async {
    await _db.collection('clinical_notes').doc(note.id).set(note.toMap());
  }

  // ADMIN Methods
  Stream<List<AppUser>> getPendingDoctors() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .handleError((error) {
          debugPrint('Firestore Error (pendingDoctors): $error');
        })
        .map((snap) {
          final list = snap.docs
              .map((d) => AppUser.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<AppUser>> getApprovedDoctors() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .handleError((error) {
          debugPrint('Firestore Error (approvedDoctors): $error');
        })
        .map((snap) {
          final list = snap.docs
              .map((d) => AppUser.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<AppUser>> getAllDoctors() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .snapshots()
        .handleError((error) {
          debugPrint('Firestore Error (allDoctors): $error');
        })
        .map((snap) {
          final list = snap.docs
              .map((d) => AppUser.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> approveDoctor(String doctorId) async {
    await _db.collection('users').doc(doctorId).update({
      'isApproved': true,
      'approvedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ADMIN: Reject (Delete) Doctor
  Future<void> rejectDoctor(String doctorId) async {
    await _db.collection('users').doc(doctorId).delete();
  }

  // ADMIN: Block Doctor
  Future<void> blockDoctor(String doctorId) async {
    await _db.collection('users').doc(doctorId).update({
      'isApproved': false,
      'blockedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<List<AppUser>> getAllUsers() {
    return _db
        .collection('users')
        .snapshots()
        .handleError((error) {
          debugPrint('Firestore Error (allUsers): $error');
        })
        .map((snap) {
          final list = snap.docs
              .map((d) => AppUser.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }
}
