import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecord {
  final String id;
  final String patientId;
  final String title;
  final String imageUrl;
  final String uploaderRole; // 'patient' or 'doctor'
  final DateTime createdAt;
  final String? doctorNote;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.title,
    required this.imageUrl,
    required this.uploaderRole,
    required this.createdAt,
    this.doctorNote,
  });

  factory MedicalRecord.fromMap(Map<String, dynamic> data, String documentId) {
    return MedicalRecord(
      id: documentId,
      patientId: data['patientId'] ?? '',
      title: data['title'] ?? 'Generic Record',
      imageUrl: data['imageUrl'] ?? '',
      uploaderRole: data['uploaderRole'] ?? 'patient',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      doctorNote: data['doctorNote'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'title': title,
      'imageUrl': imageUrl,
      'uploaderRole': uploaderRole,
      'createdAt': Timestamp.fromDate(createdAt),
      'doctorNote': doctorNote,
    };
  }
}
