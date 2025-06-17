// lib/config/app_config.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._();
  
  AppConfig._();
  
  String? _fcmServerKey;
  String? _firebaseApiKey;
  String? _projectId;
  
  // Getters with validation
  String get fcmServerKey {
    if (_fcmServerKey == null || _fcmServerKey!.isEmpty) {
      throw ConfigurationException('FCM Server Key not configured');
    }
    return _fcmServerKey!;
  }
  
  String get firebaseApiKey {
    if (_firebaseApiKey == null || _firebaseApiKey!.isEmpty) {
      throw ConfigurationException('Firebase API Key not configured');
    }
    return _firebaseApiKey!;
  }
  
  String get projectId {
    if (_projectId == null || _projectId!.isEmpty) {
      throw ConfigurationException('Project ID not configured');
    }
    return _projectId!;
  }
  
  // Initialize configuration from multiple sources
  Future<void> initialize() async {
    try {
      // Priority order: Environment variables -> Assets -> Default values
      await _loadFromEnvironment();
      await _loadFromAssets();
      _setDefaultsIfNeeded();
      
      _validateConfiguration();
    } catch (e) {
      if (kDebugMode) {
        print('Configuration initialization error: $e');
      }
      rethrow;
    }
  }
  
  // Load from environment variables (for production/CI)
  Future<void> _loadFromEnvironment() async {
    _fcmServerKey ??= Platform.environment['FCM_SERVER_KEY'];
    _firebaseApiKey ??= Platform.environment['FIREBASE_API_KEY'];
    _projectId ??= Platform.environment['FIREBASE_PROJECT_ID'];
  }
  
  // Load from secure assets file
  Future<void> _loadFromAssets() async {
    try {
      final configString = await rootBundle.loadString('assets/config/app_config.json');
      final configMap = Map<String, dynamic>.from(
        // You would parse JSON here if using JSON format
        // For security, consider using a custom format or encryption
        _parseSecureConfig(configString)
      );
      
      _fcmServerKey ??= configMap['fcm_server_key'];
      _firebaseApiKey ??= configMap['firebase_api_key'];
      _projectId ??= configMap['project_id'];
    } catch (e) {
      if (kDebugMode) {
        print('Could not load config from assets: $e');
      }
      // Don't rethrow - this is optional
    }
  }
  
  // Set development defaults (only for debug mode)
  void _setDefaultsIfNeeded() {
    if (kDebugMode) {
      _fcmServerKey ??= 'debug_fcm_key';
      _firebaseApiKey ??= 'debug_api_key';
      _projectId ??= 'debug_project';
    }
  }
  
  // Validate that all required config is present
  void _validateConfiguration() {
    final missingKeys = <String>[];
    
    if (_fcmServerKey == null || _fcmServerKey!.isEmpty) {
      missingKeys.add('FCM_SERVER_KEY');
    }
    if (_firebaseApiKey == null || _firebaseApiKey!.isEmpty) {
      missingKeys.add('FIREBASE_API_KEY');
    }
    if (_projectId == null || _projectId!.isEmpty) {
      missingKeys.add('FIREBASE_PROJECT_ID');
    }
    
    if (missingKeys.isNotEmpty) {
      throw ConfigurationException(
        'Missing required configuration keys: ${missingKeys.join(', ')}'
      );
    }
  }
  
  // Simple config parser (implement encryption/obfuscation as needed)
  Map<String, String> _parseSecureConfig(String configString) {
    final lines = configString.split('\n');
    final config = <String, String>{};
    
    for (final line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;
      
      final parts = line.split('=');
      if (parts.length == 2) {
        config[parts[0].trim()] = parts[1].trim();
      }
    }
    
    return config;
  }
  
  // For debugging (don't expose sensitive values)
  Map<String, String> getConfigSummary() {
    return {
      'fcm_server_key_configured': (_fcmServerKey?.isNotEmpty ?? false).toString(),
      'firebase_api_key_configured': (_firebaseApiKey?.isNotEmpty ?? false).toString(),
      'project_id_configured': (_projectId?.isNotEmpty ?? false).toString(),
      'environment': kDebugMode ? 'debug' : 'release',
    };
  }
}

class ConfigurationException implements Exception {
  final String message;
  ConfigurationException(this.message);
  
  @override
  String toString() => 'ConfigurationException: $message';
}