// services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DashboardOperations {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Simulate or fetch real data from Firestore
      // You can replace this with actual Firestore queries
      
      Map<String, dynamic> stats = {
        'totalUsers': 0,
        'onlineUsers': 0,
        'activeReports': 0,
        'resolvedReports': 0,
        'weatherStatus': 'Clear',
        'temperature': '24°C',
        'activeAlerts': 0,
      };

      // Try to get real data from Firestore collections
      try {
        // Count users (you might want to have a users collection)
        final usersSnapshot = await _firestore.collection('users').get();
        stats['totalUsers'] = usersSnapshot.docs.length;

        // Count active reports
        final reportsSnapshot = await _firestore
            .collection('reports')
            .where('status', isEqualTo: 'active')
            .get();
        stats['activeReports'] = reportsSnapshot.docs.length;

        // Count resolved reports
        final resolvedSnapshot = await _firestore
            .collection('reports')
            .where('status', isEqualTo: 'resolved')
            .get();
        stats['resolvedReports'] = resolvedSnapshot.docs.length;

        // Count active alerts
        final alertsSnapshot = await _firestore
            .collection('alerts')
            .where('active', isEqualTo: true)
            .get();
        stats['activeAlerts'] = alertsSnapshot.docs.length;

        // Simulate online users (you'd implement real presence for this)
        stats['onlineUsers'] = (stats['totalUsers'] * 0.3).round();

      } catch (e) {
        if (kDebugMode) {
          print('Error fetching some dashboard stats: $e');
        }
        // Return default values if Firestore queries fail
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getDashboardStats: $e');
      }
      // Return default values
      return {
        'totalUsers': 0,
        'onlineUsers': 0,
        'activeReports': 0,
        'resolvedReports': 0,
        'weatherStatus': 'Unknown',
        'temperature': 'N/A',
        'activeAlerts': 0,
      };
    }
  }

  /// Record user activity
  static Future<void> recordActivity(String action, {Map<String, dynamic>? details}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('user_activities').add({
        'userId': user.uid,
        'userEmail': user.email,
        'action': action,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'type': _getActivityType(action),
        'icon': _getActivityIcon(action),
      });

      if (kDebugMode) {
        print('Activity recorded: $action');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error recording activity: $e');
      }
    }
  }

  /// Get recent activities
  static Future<List<Map<String, dynamic>>> getRecentActivities({int limit = 10}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching recent activities: $e');
      }
      
      // Return sample data if Firestore query fails
      return _getSampleActivities();
    }
  }

  /// Get all user activities for the current user
  static Future<List<Map<String, dynamic>>> getUserActivities() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user activities: $e');
      }
      return [];
    }
  }

  /// Helper method to determine activity type
  static String _getActivityType(String action) {
    if (action.toLowerCase().contains('error') || action.toLowerCase().contains('failed')) {
      return 'error';
    } else if (action.toLowerCase().contains('warning') || action.toLowerCase().contains('alert')) {
      return 'warning';
    } else if (action.toLowerCase().contains('success') || action.toLowerCase().contains('completed')) {
      return 'success';
    } else {
      return 'info';
    }
  }

  /// Helper method to determine activity icon
  static String _getActivityIcon(String action) {
    final actionLower = action.toLowerCase();
    
    if (actionLower.contains('refresh') || actionLower.contains('reload')) {
      return 'refresh';
    } else if (actionLower.contains('report')) {
      return 'report';
    } else if (actionLower.contains('warning') || actionLower.contains('alert')) {
      return 'warning';
    } else if (actionLower.contains('success') || actionLower.contains('completed')) {
      return 'check';
    } else if (actionLower.contains('build') || actionLower.contains('create')) {
      return 'build';
    } else {
      return 'info';
    }
  }

  /// Sample activities for when Firestore is not available
  static List<Map<String, dynamic>> _getSampleActivities() {
    final now = DateTime.now();
    return [
      {
        'action': 'Dashboard Refreshed',
        'timestamp': now.subtract(const Duration(minutes: 2)),
        'type': 'info',
        'icon': 'refresh',
      },
      {
        'action': 'Profile Updated',
        'timestamp': now.subtract(const Duration(hours: 1)),
        'type': 'success',
        'icon': 'check',
      },
      {
        'action': 'New Report Created',
        'timestamp': now.subtract(const Duration(hours: 3)),
        'type': 'info',
        'icon': 'report',
      },
      {
        'action': 'Weather Alert Received',
        'timestamp': now.subtract(const Duration(hours: 6)),
        'type': 'warning',
        'icon': 'warning',
      },
      {
        'action': 'Emergency Contact Added',
        'timestamp': now.subtract(const Duration(days: 1)),
        'type': 'success',
        'icon': 'build',
      },
    ];
  }

  /// Initialize user document (call this after successful login)
  static Future<void> initializeUserDocument() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = _firestore.collection('users').doc(user.uid);
      
      // Check if user document exists
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        // Create user document with basic info
        await userDoc.set({
          'email': user.email,
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        
        if (kDebugMode) {
          print('User document created for ${user.email}');
        }
      } else {
        // Update last login
        await userDoc.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        
        if (kDebugMode) {
          print('User document updated for ${user.email}');
        }
      }

      // Record login activity
      await recordActivity('User Login', details: {
        'loginTime': DateTime.now().toIso8601String(),
        'platform': 'mobile',
      });

    } catch (e) {
      if (kDebugMode) {
        print('Error initializing user document: $e');
      }
    }
  }

  /// Update user status to offline
  static Future<void> setUserOffline() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'isActive': false,
        'lastSeenAt': FieldValue.serverTimestamp(),
      });

      // Record logout activity
      await recordActivity('User Logout', details: {
        'logoutTime': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      if (kDebugMode) {
        print('Error setting user offline: $e');
      }
    }
  }
}