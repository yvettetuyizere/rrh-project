import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';

class ReportService {
  final CollectionReference _reportCollection =
      FirebaseFirestore.instance.collection('reports');

  // Create a new report document
  Future<void> createReport(Report report) async {
    await _reportCollection.add(report.toJson());
  }

  // Read all reports as a stream (for real-time updates)
  Stream<List<Report>> getReports() {
    return _reportCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add Firestore document ID
        return Report.fromJson(data);
      }).toList();
    });
  }

  // Update a report document by id
  Future<void> updateReport(Report report) async {
    if (report.id == null) throw Exception("Report ID is null");
    await _reportCollection.doc(report.id).update(report.toJson());
  }

  // Delete a report document by id
  Future<void> deleteReport(String id) async {
    await _reportCollection.doc(id).delete();
  }
}
