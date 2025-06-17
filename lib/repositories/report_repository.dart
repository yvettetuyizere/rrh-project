import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/report.dart';

// File location: lib/repositories/report_repository.dart

class ReportRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ReportRepository(this._firestore, this._storage);

  CollectionReference get _reportsCollection => _firestore.collection('reports');

  Future<List<Report>> getReports() async {
    try {
      final snapshot = await _reportsCollection
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  Future<Report> createReport(Report report, {File? image, File? file}) async {
    try {
      String? imageUrl;
      String? fileUrl;

      if (image != null) {
        final imageRef = _storage
            .ref()
            .child('reports/images/${DateTime.now().millisecondsSinceEpoch}');
        await imageRef.putFile(image);
        imageUrl = await imageRef.getDownloadURL();
      }

      if (file != null) {
        final fileRef = _storage
            .ref()
            .child('reports/files/${DateTime.now().millisecondsSinceEpoch}');
        await fileRef.putFile(file);
        fileUrl = await fileRef.getDownloadURL();
      }

      final now = DateTime.now();

      final docRef = await _reportsCollection.add({
        ...report.toFirestore(),
        'imageUrl': imageUrl,
        'fileUrl': fileUrl,
        'createdAt': Timestamp.fromDate(now),
      });

      return report.copyWith(
  id: docRef.id,
  imageUrl: imageUrl,
  fileUrl: fileUrl,
  createdAt: Timestamp.fromDate(now),
);

    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _reportsCollection.doc(reportId).delete();
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  Future<void> approveReport(String reportId, String approvedBy) async {
    try {
      await _reportsCollection.doc(reportId).update({
        'isApproved': true,
        'approvedBy': approvedBy,
        'approvedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to approve report: $e');
    }
  }
}