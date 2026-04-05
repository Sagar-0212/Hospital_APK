import 'package:cloud_firestore/cloud_firestore.dart';

class Prescription {
  final String id;
  final String patientId;
  final String doctorId;
  final String medicineName;
  final String dosage;
  final String frequency;
  final int durationDays;
  final String status; // active, archived
  final String notes;
  final DateTime date;

  Prescription({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    required this.status,
    required this.notes,
    required this.date,
  });

  factory Prescription.fromMap(Map<String, dynamic> data, String documentId) {
    return Prescription(
      id: documentId,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      medicineName: data['medicineName'] ?? '',
      dosage: data['dosage'] ?? '',
      frequency: data['frequency'] ?? '',
      durationDays: data['durationDays'] ?? 0,
      status: data['status'] ?? 'active',
      notes: data['notes'] ?? '',
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'medicineName': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'durationDays': durationDays,
      'status': status,
      'notes': notes,
      'date': date,
    };
  }
}
