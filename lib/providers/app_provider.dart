import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import '../data/remote/api_service.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _incidents = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get incidents => _incidents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize the provider
  Future<void> initialize() async {
    await _notificationService.initialize();
    await loadData();
  }

  // Load data from both local and remote sources
  Future<void> loadData() async {
    _setLoading(true);
    try {
      // Load from local database first
      final localUsers = await _dbHelper.getUsers();
      final localIncidents = await _dbHelper.getIncidents();

      _users = localUsers;
      _incidents = localIncidents;

      // Then try to sync with remote
      await _syncWithRemote();
    } catch (e) {
      _setError('Failed to load data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sync local data with remote
  Future<void> _syncWithRemote() async {
    try {
      final remoteUsers = await _apiService.getUsers();
      final remoteIncidents = await _apiService.getIncidents();

      // Update local database with remote data
      for (var user in remoteUsers) {
        await _dbHelper.insertUser(user);
      }

      for (var incident in remoteIncidents) {
        await _dbHelper.insertIncident(incident);
      }

      // Refresh local data
      _users = await _dbHelper.getUsers();
      _incidents = await _dbHelper.getIncidents();

      notifyListeners();
    } catch (e) {
      _setError('Failed to sync with remote: $e');
    }
  }

  // User operations
  Future<void> createUser(Map<String, dynamic> userData) async {
    _setLoading(true);
    try {
      // Create in remote first
      final remoteUser = await _apiService.createUser(userData);

      // Then save locally
      await _dbHelper.insertUser(remoteUser);

      // Refresh data
      await loadData();
    } catch (e) {
      _setError('Failed to create user: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUser(Map<String, dynamic> userData) async {
    _setLoading(true);
    try {
      // Update in remote first
      final remoteUser = await _apiService.updateUser(userData['id'], userData);

      // Then update locally
      await _dbHelper.updateUser(remoteUser);

      // Refresh data
      await loadData();
    } catch (e) {
      _setError('Failed to update user: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteUser(int id) async {
    _setLoading(true);
    try {
      // Delete from remote first
      await _apiService.deleteUser(id);

      // Then delete locally
      await _dbHelper.deleteUser(id);

      // Refresh data
      await loadData();
    } catch (e) {
      _setError('Failed to delete user: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Incident operations
  Future<void> createIncident(Map<String, dynamic> incidentData) async {
    _setLoading(true);
    try {
      // Create in remote first
      final remoteIncident = await _apiService.createIncident(incidentData);

      // Then save locally
      await _dbHelper.insertIncident(remoteIncident);

      // Refresh data
      await loadData();
    } catch (e) {
      _setError('Failed to create incident: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateIncident(Map<String, dynamic> incidentData) async {
    _setLoading(true);
    try {
      // Update in remote first
      final remoteIncident =
          await _apiService.updateIncident(incidentData['id'], incidentData);

      // Then update locally
      await _dbHelper.updateIncident(remoteIncident);

      // Refresh data
      await loadData();
    } catch (e) {
      _setError('Failed to update incident: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteIncident(int id) async {
    _setLoading(true);
    try {
      // Delete from remote first
      await _apiService.deleteIncident(id);

      // Then delete locally
      await _dbHelper.deleteIncident(id);

      // Refresh data
      await loadData();
    } catch (e) {
      _setError('Failed to delete incident: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
