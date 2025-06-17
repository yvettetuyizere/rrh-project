// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/report.dart';

class ApiService {
  static const String baseUrl = 'https://AIzaSyAusq8vUZpGhV16R2yF4B1RCUvCAeykwBsapi'; // 🔁 Replace with your actual API base URL

  /// Fetch all reports
  static Future<List<Report>> fetchReports() async {
    final response = await http.get(Uri.parse('$baseUrl/reports'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Report.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reports');
    }
  }

  /// Create a new report
  static Future<Report> createReport(Report report) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reports'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(report.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Report.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create report');
    }
  }

  /// Update an existing report
  static Future<Report> updateReport(String id, Report report) async {
    final response = await http.put(
      Uri.parse('$baseUrl/reports/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(report.toJson()),
    );

    if (response.statusCode == 200) {
      return Report.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update report');
    }
  }

  /// Delete a report
  static Future<void> deleteReport(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/reports/$id'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete report');
    }
  }
}
