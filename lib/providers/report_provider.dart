import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/report.dart';

class ReportProvider extends ChangeNotifier {
  final CollectionReference _reportsCollection =
      FirebaseFirestore.instance.collection('reports');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<Report> _reports = [];
  List<Report> get reports => _reports;

  Report getById(String id) {
    return _reports.firstWhere((report) => report.id == id);
  }

  List<Report> getFilteredReports(String query) {
    if (query.isEmpty) {
      return _reports;
    }
    final lowerQuery = query.toLowerCase();
    return _reports.where((report) {
      return report.title.toLowerCase().contains(lowerQuery) ||
          report.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Adds a new report, optionally uploading an image and/or file to Firebase Storage.
  Future<void> addReport(Report report, {File? image, File? file}) async {
    String? imageUrl;
    String? fileUrl;

    // Upload image if provided
    if (image != null) {
      final imageRef = _storage
          .ref()
          .child('reports/images/${DateTime.now().millisecondsSinceEpoch}');
      await imageRef.putFile(image);
      imageUrl = await imageRef.getDownloadURL();
    }

    // Upload file if provided
    if (file != null) {
      final fileRef = _storage
          .ref()
          .child('reports/files/${DateTime.now().millisecondsSinceEpoch}');
      await fileRef.putFile(file);
      fileUrl = await fileRef.getDownloadURL();
    }

    // Use current timestamp for createdAt
    final now = DateTime.now();
    final newReport = report.copyWith(
      imageUrl: imageUrl,
      fileUrl: fileUrl,
      createdAt: Timestamp.fromDate(now),
    );

    // Add new report to Firestore and get doc ID
    final docRef = await _reportsCollection.add(newReport.toFirestore());

    // Add locally with the new document ID
    _reports.insert(0, newReport.copyWith(id: docRef.id)); // Insert at top
    notifyListeners();
  }

  /// Fetch all reports ordered by createdAt descending
  Future<void> fetchReports() async {
    final snapshot =
        await _reportsCollection.orderBy('createdAt', descending: true).get();

    _reports = snapshot.docs
        .map((doc) => Report.fromJson({'id': doc.id, ...doc.data() as Map<String, dynamic>}))
        .toList();

    notifyListeners();
  }

  /// Update an existing report
  Future<void> updateReport(Report report) async {
    if (report.id == null) return;

    await _reportsCollection.doc(report.id).update(report.toFirestore());

    final index = _reports.indexWhere((r) => r.id == report.id);
    if (index != -1) {
      _reports[index] = report;
      notifyListeners();
    }
  }

  /// Delete a report by ID
  Future<void> deleteReport(String id) async {
    await _reportsCollection.doc(id).delete();
    _reports.removeWhere((r) => r.id == id);
    notifyListeners();
  }
  // Total number of reports
int get totalReports => _reports.length;

Map<String, int> get reportTypesCount {
  final Map<String, int> counts = {};
  for (final report in _reports) {
    final type = report.type.toLowerCase();
    counts[type] = (counts[type] ?? 0) + 1;
  }
  return counts;
}

Map<String, int> get severityCount {
  final Map<String, int> counts = {};
  for (final report in _reports) {
    final severity = report.severity.toLowerCase();
    counts[severity] = (counts[severity] ?? 0) + 1;
  }
  return counts;
}

List<Report> get recentReports => _reports.take(5).toList();

}
