import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // "patient", "doctor", or "admin"
  final DateTime createdAt;
  final Map<String, List<String>>? clinicalHours; // For doctors: {"Monday": ["09:00 AM", ...], "Tuesday": [...]}
  final bool isApproved; // For doctors: false by default, true once approved by admin
  final DateTime? approvedAt; // When doctor was approved by admin

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.clinicalHours,
    this.isApproved = true, // Patients/admins are approved by default
    this.approvedAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    Map<String, List<String>>? hours;
    if (data['clinicalHours'] != null) {
      if (data['clinicalHours'] is Map) {
        try {
          final rawHours = data['clinicalHours'] as Map<dynamic, dynamic>;
          hours = rawHours.map((key, value) => MapEntry(key.toString(), List<String>.from(value)));
        } catch (_) {}
      } else if (data['clinicalHours'] is List) {
        try {
          final legacyList = List<String>.from(data['clinicalHours']);
          hours = {
            'Monday': legacyList, 'Tuesday': legacyList, 'Wednesday': legacyList,
            'Thursday': legacyList, 'Friday': legacyList, 'Saturday': legacyList, 'Sunday': legacyList
          };
        } catch (_) {}
      }
    }

    return AppUser(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'patient',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      clinicalHours: hours,
      isApproved: data['isApproved'] ?? (data['role'] != 'doctor'),
      approvedAt: data['approvedAt'] != null ? (data['approvedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'clinicalHours': clinicalHours,
      'isApproved': isApproved,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }
}
