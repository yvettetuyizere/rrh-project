import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final String baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'https://api.example.com';

  factory ApiService() => _instance;

  ApiService._internal();

  // Headers
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Users API
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: _headers,
      body: json.encode(userData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create user: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load users: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUser(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateUser(
      int id, Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: _headers,
      body: json.encode(userData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete user: ${response.body}');
    }
  }

  // Incidents API
  Future<Map<String, dynamic>> createIncident(
      Map<String, dynamic> incidentData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/incidents'),
      headers: _headers,
      body: json.encode(incidentData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create incident: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getIncidents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/incidents'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load incidents: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getIncident(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/incidents/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load incident: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateIncident(
      int id, Map<String, dynamic> incidentData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/incidents/$id'),
      headers: _headers,
      body: json.encode(incidentData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update incident: ${response.body}');
    }
  }

  Future<void> deleteIncident(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/incidents/$id'),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete incident: ${response.body}');
    }
  }
}
