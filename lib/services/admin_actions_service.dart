import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminActionsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Log admin action to audit trail
  Future<void> logAdminAction({
    required String adminId,
    required String adminName,
    required String action,
    required String targetType, // 'doctor', 'user', 'system'
    required String targetId,
    required String targetName,
    String? details,
    String? reason,
  }) async {
    try {
      await _db.collection('admin_logs').add({
        'adminId': adminId,
        'adminName': adminName,
        'action':
            action, // 'approved', 'rejected', 'blocked', 'unblocked', 'deleted', 'login', 'logout'
        'targetType': targetType,
        'targetId': targetId,
        'targetName': targetName,
        'details': details,
        'reason': reason,
        'timestamp': Timestamp.now(),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      debugPrint('Admin action logged: $action on $targetType');
    } catch (e) {
      debugPrint('Error logging admin action: $e');
      rethrow;
    }
  }

  // Get all admin logs with pagination
  Stream<List<Map<String, dynamic>>> getAdminLogs({
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _db
        .collection('admin_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: endDate);
    }

    return query.snapshots().map((snap) {
      return snap.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  // Get logs for specific target
  Stream<List<Map<String, dynamic>>> getTargetLogs(String targetId) {
    return _db
        .collection('admin_logs')
        .where('targetId', isEqualTo: targetId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) => doc.data()).toList();
        });
  }

  // Get admin activity stats
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      // Total admins
      final adminsSnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      // Total approved doctors
      final approvedDocsSnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('isApproved', isEqualTo: true)
          .get();

      // Total pending doctors
      final pendingDocsSnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('isApproved', isEqualTo: false)
          .get();

      // Total users
      final usersSnapshot = await _db.collection('users').get();

      // Recent logs (last 24 hours)
      final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));
      final recentLogsSnapshot = await _db
          .collection('admin_logs')
          .where('timestamp', isGreaterThan: oneDayAgo)
          .get();

      return {
        'totalAdmins': adminsSnapshot.size,
        'totalDoctors': approvedDocsSnapshot.size + pendingDocsSnapshot.size,
        'approvedDoctors': approvedDocsSnapshot.size,
        'pendingDoctors': pendingDocsSnapshot.size,
        'totalUsers': usersSnapshot.size,
        'recentActionsCount': recentLogsSnapshot.size,
        'doctorApprovalRate': approvedDocsSnapshot.size > 0
            ? ((approvedDocsSnapshot.size /
                          (approvedDocsSnapshot.size +
                              pendingDocsSnapshot.size)) *
                      100)
                  .toStringAsFixed(1)
            : 'N/A',
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      debugPrint('Error getting admin stats: $e');
      rethrow;
    }
  }

  // Get monthly admin actions breakdown
  Future<Map<String, int>> getMonthlyActionsBreakdown() async {
    try {
      final startOfMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        1,
      );
      final snapshot = await _db
          .collection('admin_logs')
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .get();

      final breakdown = <String, int>{};

      for (var doc in snapshot.docs) {
        final action = doc['action'] as String?;
        if (action != null) {
          breakdown[action] = (breakdown[action] ?? 0) + 1;
        }
      }

      return breakdown;
    } catch (e) {
      debugPrint('Error getting actions breakdown: $e');
      return {};
    }
  }

  // Clear old logs (keep last 90 days)
  Future<void> clearOldLogs() async {
    try {
      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
      final snapshot = await _db
          .collection('admin_logs')
          .where('timestamp', isLessThan: ninetyDaysAgo)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('Old logs cleared, removed ${snapshot.size} documents');
    } catch (e) {
      debugPrint('Error clearing old logs: $e');
      rethrow;
    }
  }

  // Get blocked doctors count
  Future<int> getBlockedDoctorsCount() async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('isApproved', isEqualTo: false)
          .get();

      return snapshot.docs
          .where((doc) => (doc['blockedAt'] as Timestamp?) != null)
          .length;
    } catch (e) {
      debugPrint('Error getting blocked doctors count: $e');
      return 0;
    }
  }
}
