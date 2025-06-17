import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DashboardOperations {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize user document in Firestore after successful login
  static Future<void> initializeUserDocument() async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          print('DashboardOperations: No authenticated user found');
        }
        return;
      }

      final String userId = currentUser.uid;
      final String? userEmail = currentUser.email;

      if (kDebugMode) {
        print(
            'DashboardOperations: Initializing document for user: $userEmail');
      }

      // Reference to user document
      final DocumentReference userDoc =
          _firestore.collection('users').doc(userId);

      // Check if user document exists
      final DocumentSnapshot docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // Create new user document
        await userDoc.set({
          'uid': userId,
          'email': userEmail,
          'displayName': currentUser.displayName ?? '',
          'photoURL': currentUser.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'profile': {
            'firstName': '',
            'lastName': '',
            'phone': '',
            'location': '',
            'organization': '',
          },
          'preferences': {
            'notifications': true,
            'emailUpdates': true,
            'language': 'en',
          },
          'stats': {
            'reportsSubmitted': 0,
            'reportsResolved': 0,
            'lastReportDate': null,
          }
        });

        if (kDebugMode) {
          print('DashboardOperations: Created new user document');
        }
      } else {
        // Update existing user document with last login
        await userDoc.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        if (kDebugMode) {
          print('DashboardOperations: Updated existing user document');
        }
      }

      // Initialize user's reports collection if it doesn't exist
      final CollectionReference userReports = userDoc.collection('reports');
      final QuerySnapshot reportsSnapshot = await userReports.limit(1).get();

      if (reportsSnapshot.docs.isEmpty) {
        // Create a placeholder document to initialize the collection
        await userReports.doc('_placeholder').set({
          'isPlaceholder': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          print('DashboardOperations: Initialized user reports collection');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DashboardOperations: Error initializing user document: $e');
      }
      // Don't throw the error to prevent login failure
      // Just log it and continue
    }
  }

  /// Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        return null;
      }

      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('DashboardOperations: Error getting user data: $e');
      }
      return null;
    }
  }

  /// Update user profile information
  static Future<bool> updateUserProfile(
      Map<String, dynamic> profileData) async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        return false;
      }

      await _firestore.collection('users').doc(currentUser.uid).update({
        'profile': profileData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('DashboardOperations: User profile updated successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('DashboardOperations: Error updating user profile: $e');
      }
      return false;
    }
  }

  /// Get user's reports count
  static Future<int> getUserReportsCount() async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        return 0;
      }

      final QuerySnapshot reportsSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('reports')
          .where('isPlaceholder', isEqualTo: false)
          .get();

      return reportsSnapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('DashboardOperations: Error getting reports count: $e');
      }
      return 0;
    }
  }

  /// Update user preferences
  static Future<bool> updateUserPreferences(
      Map<String, dynamic> preferences) async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        return false;
      }

      await _firestore.collection('users').doc(currentUser.uid).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('DashboardOperations: Error updating preferences: $e');
      }
      return false;
    }
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Get counts from various collections
      final reportsSnapshot = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'active')
          .get();

      final weatherAlertsSnapshot = await _firestore
          .collection('weather_alerts')
          .where('status', isEqualTo: 'active')
          .get();

      final safeZonesSnapshot = await _firestore
          .collection('safe_zones')
          .where('status', isEqualTo: 'active')
          .get();

      final emergencyCallsSnapshot = await _firestore
          .collection('emergency_calls')
          .where('status', isEqualTo: 'active')
          .get();

      return {
        'activeReports': reportsSnapshot.docs.length,
        'weatherAlerts': weatherAlertsSnapshot.docs.length,
        'safeZones': safeZonesSnapshot.docs.length,
        'emergencyCalls': emergencyCallsSnapshot.docs.length,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting dashboard stats: $e');
      }
      // Return default values if there's an error
      return {
        'activeReports': 0,
        'weatherAlerts': 0,
        'safeZones': 0,
        'emergencyCalls': 0,
      };
    }
  }

  static Future<void> recordActivity(String action,
      {Map<String, dynamic>? details}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('activities').add({
        'userId': user.uid,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'details': details ?? {},
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error recording activity: $e');
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentActivities(
      {int limit = 5}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'action': data['action'],
          'timestamp': data['timestamp'],
          'details': data['details'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
