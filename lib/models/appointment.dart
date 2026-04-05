import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String doctorName;
  final String? doctorSpecialization;
  final String? doctorDegree;
  final DateTime date;
  final String timeSlot;
  final String status; // 'pending', 'upcoming', 'completed', 'cancelled', 'rescheduled'
  final String? cancellationReason;
  final String type; // 'Checkup', 'Consultation', etc.

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
    this.doctorSpecialization,
    this.doctorDegree,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.cancellationReason,
    required this.type,
  });

  factory Appointment.fromMap(Map<String, dynamic> data, String documentId) {
    return Appointment(
      id: documentId,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      patientName: data['patientName'] ?? 'Unknown',
      doctorName: data['doctorName'] ?? 'Unknown',
      doctorSpecialization: data['doctorSpecialization'],
      doctorDegree: data['doctorDegree'],
      date: (data['date'] as Timestamp).toDate(),
      timeSlot: data['timeSlot'] ?? '',
      status: data['status'] ?? 'pending',
      cancellationReason: data['cancellationReason'],
      type: data['type'] ?? 'Consultation',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'patientName': patientName,
      'doctorName': doctorName,
      'doctorSpecialization': doctorSpecialization,
      'doctorDegree': doctorDegree,
      'date': Timestamp.fromDate(date),
      'timeSlot': timeSlot,
      'status': status,
      'cancellationReason': cancellationReason,
      'type': type,
    };
  }
}
