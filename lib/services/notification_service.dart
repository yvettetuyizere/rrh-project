import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('NotificationService');

  // Notification channels
  static const String _reportsChannelId = 'reports_channel';
  static const String _reportsChannelName = 'Reports';
  static const String _reportsChannelDescription =
      'Notifications for new reports';

  static const String _urgentChannelId = 'urgent_channel';
  static const String _urgentChannelName = 'Urgent Notifications';
  static const String _urgentChannelDescription =
      'High priority urgent notifications';

  // State management
  bool _isInitialized = false;
  String? _currentFcmToken;

  // Configuration
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  bool get isInitialized => _isInitialized;
  String? get currentFcmToken => _currentFcmToken;

  void _initializeLogger() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.time}: ${record.loggerName}: ${record.message}');
    });
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.info('NotificationService already initialized');
      return;
    }

    try {
      await _initializeConfiguration();
      final permissionGranted = await _requestNotificationPermissions();

      if (!permissionGranted) {
        _logger.warning('Notification permissions not granted');
        return;
      }

      await _initializeLocalNotifications();
      await _createNotificationChannels();
      _setupMessageHandlers();
      await _handleFcmToken();

      _isInitialized = true;
      _logger.info('NotificationService initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize NotificationService: $e');
      // Don't rethrow, just log the error
    }
  }

  Future<void> _initializeConfiguration() async {
    try {
      await AppConfig.instance.initialize();
      _logger.info('Configuration initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize configuration: $e');
      // Don't throw, just log the error
    }
  }

  Future<bool> _requestNotificationPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      _logger.info(
          'Notification permission status: ${settings.authorizationStatus}');
      return isAuthorized;
    } catch (e) {
      _logger.severe('Error requesting notification permissions: $e');
      return false;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitializationSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    final initialized = await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (initialized != true) {
      throw Exception('Failed to initialize local notifications');
    }
  }

  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Reports channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            _reportsChannelId,
            _reportsChannelName,
            description: _reportsChannelDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        // Urgent channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            _urgentChannelId,
            _urgentChannelName,
            description: _urgentChannelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          ),
        );

        _logger.info('Android notification channels created');
      }
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _handleFcmToken() async {
    try {
      final fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        _currentFcmToken = fcmToken;
        await _saveFcmTokenToFirestore(fcmToken);
      }
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _currentFcmToken = newToken;
        _saveFcmTokenToFirestore(newToken);
      });
    } catch (e) {
      _logger.severe('Error handling FCM token: $e');
    }
  }

  Future<void> _saveFcmTokenToFirestore(String fcmToken) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _logger.warning('User not authenticated; cannot save FCM token.');
      return;
    }

    try {
      await _firestore.collection('users').doc(currentUser.uid).set({
        'fcmToken': fcmToken,
        'lastUpdated': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
      }, SetOptions(merge: true));

      _logger.info('FCM token saved for user ${currentUser.uid}');
    } catch (e) {
      _logger.severe('Error saving FCM token: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.info('Foreground message received: ${message.messageId}');

    final notificationData = _extractNotificationData(message);
    await _displayLocalNotification(
      title: notificationData.title,
      body: notificationData.body,
      payload: notificationData.reportId,
      isUrgent: notificationData.isUrgent,
    );
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    _logger
        .info('Remote notification tapped for message: ${message.messageId}');
    final reportId = message.data['reportId'];
    _handleNotificationNavigation(reportId);
  }

  void _onNotificationTap(NotificationResponse response) {
    _logger.info('Local notification tapped with payload: ${response.payload}');
    _handleNotificationNavigation(response.payload);
  }

  void _handleNotificationNavigation(String? reportId) {
    if (_isValidReportId(reportId)) {
      _navigateToReportDetail(reportId!);
    } else {
      _navigateToDashboard();
    }
  }

  bool _isValidReportId(String? reportId) {
    return reportId != null && reportId.isNotEmpty && reportId != 'null';
  }

  void _navigateToReportDetail(String reportId) {
    _performNavigation(() {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        context.go('/report/$reportId');
        _logger.info('Successfully navigated to report: $reportId');
      }
    }, 'report/$reportId');
  }

  void _navigateToDashboard() {
    _performNavigation(() {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        context.go('/home');
        _logger.info('Successfully navigated to dashboard');
      }
    }, 'dashboard');
  }

  void _performNavigation(VoidCallback navigationAction, String destination) {
    try {
      navigationAction();
    } catch (e) {
      _logger.severe('Navigation failed for $destination: $e');
      // Fallback navigation with traditional Navigator
      _attemptFallbackNavigation(destination);
    }
  }

  void _attemptFallbackNavigation(String destination) {
    try {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        if (destination.startsWith('report/')) {
          final reportId = destination.split('/')[1];
          Navigator.pushNamed(context, '/reportDetail', arguments: reportId);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
        _logger.info('Fallback navigation successful for $destination');
      }
    } catch (e) {
      _logger.severe('All navigation attempts failed for $destination: $e');
    }
  }

  NotificationData _extractNotificationData(RemoteMessage message) {
    return NotificationData(
      title: message.notification?.title ?? 'New Report',
      body: message.notification?.body ?? 'A new report has been submitted',
      reportId: message.data['reportId'] ?? '',
      isUrgent: message.data['urgent'] == 'true' ||
          message.data['priority'] == 'high',
    );
  }

  Future<void> _displayLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool isUrgent = false,
  }) async {
    final channelId = isUrgent ? _urgentChannelId : _reportsChannelId;
    final channelName = isUrgent ? _urgentChannelName : _reportsChannelName;

    final androidNotificationDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription:
          isUrgent ? _urgentChannelDescription : _reportsChannelDescription,
      importance: isUrgent ? Importance.max : Importance.high,
      priority: isUrgent ? Priority.max : Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: isUrgent,
    );

    const iosNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _localNotifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> sendDirectFcmNotification({
    required String fcmToken,
    required String title,
    required String body,
    String? reportId,
    bool isUrgent = false,
    Map<String, String>? additionalData,
  }) async {
    if (!_canSendNotification(fcmToken)) {
      throw NotificationDeliveryException('Invalid FCM token provided');
    }

    try {
      await _sendFcmWithRetry(
        fcmToken: fcmToken,
        title: title,
        body: body,
        reportId: reportId,
        isUrgent: isUrgent,
        additionalData: additionalData,
      );
    } catch (e) {
      _logger.severe('Failed to send FCM notification: $e');
      rethrow;
    }
  }

  Future<void> _sendFcmWithRetry({
    required String fcmToken,
    required String title,
    required String body,
    String? reportId,
    bool isUrgent = false,
    Map<String, String>? additionalData,
    int attempt = 1,
  }) async {
    try {
      await _sendFcmRequest(
        fcmToken: fcmToken,
        title: title,
        body: body,
        reportId: reportId,
        isUrgent: isUrgent,
        additionalData: additionalData,
      );
    } catch (e) {
      if (attempt < _maxRetryAttempts) {
        _logger.warning('FCM send attempt $attempt failed, retrying: $e');
        await Future.delayed(_retryDelay);
        await _sendFcmWithRetry(
          fcmToken: fcmToken,
          title: title,
          body: body,
          reportId: reportId,
          isUrgent: isUrgent,
          additionalData: additionalData,
          attempt: attempt + 1,
        );
      } else {
        throw NotificationDeliveryException(
            'Failed to send FCM after $attempt attempts: $e');
      }
    }
  }

  Future<void> _sendFcmRequest({
    required String fcmToken,
    required String title,
    required String body,
    String? reportId,
    bool isUrgent = false,
    Map<String, String>? additionalData,
  }) async {
    final serverKey = AppConfig.instance.fcmServerKey;
    final fcmEndpoint = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final data = <String, String>{
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'reportId': reportId ?? '',
      'urgent': isUrgent.toString(),
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      ...?additionalData,
    };

    final payload = {
      "to": fcmToken,
      "notification": {
        "title": title,
        "body": body,
        "sound": "default",
      },
      "data": data,
      "android": {
        "priority": isUrgent ? "high" : "normal",
        "ttl": "86400s", // 24 hours
      },
      "apns": {
        "headers": {
          "apns-priority": isUrgent ? "10" : "5",
          "apns-expiration": (DateTime.now()
                      .add(const Duration(hours: 24))
                      .millisecondsSinceEpoch ~/
                  1000)
              .toString(),
        },
        "payload": {
          "aps": {
            "sound": "default",
            "badge": 1,
          }
        }
      }
    };

    final httpResponse = await http.post(
      fcmEndpoint,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode(payload),
    );

    if (_isSuccessfulHttpResponse(httpResponse.statusCode)) {
      _logger.info(
          'FCM notification sent successfully to token: ${_maskToken(fcmToken)}');
    } else {
      final errorBody = httpResponse.body;
      _logger.warning('Failed to send FCM notification: $errorBody');
      throw NotificationDeliveryException(
          'FCM request failed with status: ${httpResponse.statusCode}');
    }
  }

  String _maskToken(String token) {
    if (token.length <= 10) return token;
    return '${token.substring(0, 10)}...${token.substring(token.length - 4)}';
  }

  bool _canSendNotification(String fcmToken) {
    return fcmToken.isNotEmpty && fcmToken.length > 20;
  }

  bool _isSuccessfulHttpResponse(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  // Batch notification methods
  Future<void> sendBatchNotifications({
    required List<String> fcmTokens,
    required String title,
    required String body,
    String? reportId,
    bool isUrgent = false,
  }) async {
    final futures = fcmTokens.map((token) => sendDirectFcmNotification(
          fcmToken: token,
          title: title,
          body: body,
          reportId: reportId,
          isUrgent: isUrgent,
        ));

    try {
      await Future.wait(futures, eagerError: false);
      _logger.info(
          'Batch notification completed successfully for ${fcmTokens.length} tokens');
    } catch (e) {
      _logger.warning('Some notifications in batch failed: $e');
      // Continue processing - individual failures are logged in sendDirectFcmNotification
    }
  }

  // Utility methods
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
    _logger.info('All local notifications cleared');
  }

  Future<void> clearNotification(int notificationId) async {
    await _localNotifications.cancel(notificationId);
    _logger.info('Notification $notificationId cleared');
  }

  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'hasToken': _currentFcmToken != null,
      'tokenLength': _currentFcmToken?.length ?? 0,
      'configuration': getConfigurationStatus(),
    };
  }

  Map<String, String> getConfigurationStatus() {
    try {
      return AppConfig.instance.getConfigSummary();
    } catch (e) {
      return {'error': 'Configuration not initialized: $e'};
    }
  }

  void dispose() {
    _logger.info('NotificationService disposed');
  }

  factory NotificationService() => _instance;
  NotificationService._internal() {
    _initializeLogger();
  }
}

// Data classes
class NotificationData {
  final String title;
  final String body;
  final String reportId;
  final bool isUrgent;

  NotificationData({
    required this.title,
    required this.body,
    required this.reportId,
    this.isUrgent = false,
  });
}

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final backgroundLogger = Logger('BackgroundMessageHandler');
  backgroundLogger.info('Processing background message: ${message.messageId}');

  // Handle navigation from background message if needed
  final reportId = message.data['reportId'];
  if (reportId != null && reportId.isNotEmpty) {
    // Store pending navigation for when app becomes active
    backgroundLogger.info('Background message contains reportId: $reportId');
  }
}

// Custom exception classes
class NotificationDeliveryException implements Exception {
  final String message;
  NotificationDeliveryException(this.message);

  @override
  String toString() => 'NotificationDeliveryException: $message';
}

class NotificationPermissionException implements Exception {
  final String message;
  NotificationPermissionException(this.message);

  @override
  String toString() => 'NotificationPermissionException: $message';
}

class ConfigurationException implements Exception {
  final String message;
  ConfigurationException(this.message);

  @override
  String toString() => 'ConfigurationException: $message';
}
