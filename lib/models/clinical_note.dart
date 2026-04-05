import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicalNote {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime date;
  final String observation;
  final String diagnosis;

  ClinicalNote({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.date,
    required this.observation,
    required this.diagnosis,
  });

  factory ClinicalNote.fromMap(Map<String, dynamic> data, String documentId) {
    return ClinicalNote(
      id: documentId,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      observation: data['observation'] ?? '',
      diagnosis: data['diagnosis'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'date': Timestamp.fromDate(date),
      'observation': observation,
      'diagnosis': diagnosis,
    };
  }
}
