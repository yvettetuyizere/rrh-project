import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/report.dart';
import '../providers/report_provider.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final provider = context.read<ReportProvider>();
    await provider.fetchReports();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _openReportDialog({Report? report}) async {
    final result = await showDialog(
      context: context,
      builder: (_) => ReportDialog(report: report),
      barrierDismissible: false,
    );
    if (result == true && mounted) _loadReports();
  }

  void _showViewDialog(Report report) {
    showDialog(
      context: context,
      builder: (_) => ViewReportDialog(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportProvider>().reports;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReports),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _openReportDialog()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
              ? const Center(child: Text('No reports found'))
              : ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(report.title),
                        subtitle: Text(report.description),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'view') {
                              _showViewDialog(report);
                            } else if (value == 'edit') {
                              _openReportDialog(report: report);
                            } else if (value == 'delete') {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: Text('Delete report "${report.title}"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                  ],
                                ),
                              );

                              if (confirmed == true && mounted) {
                                await context.read<ReportProvider>().deleteReport(report.id!);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Report deleted'), backgroundColor: Colors.red),
                                );
                                _loadReports();
                              }
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'view', child: Text('View')),
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class ReportDialog extends StatefulWidget {
  final Report? report;
  const ReportDialog({super.key, this.report});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _typeController;
  late final TextEditingController _severityController;

  bool _gettingLocation = false;

  @override
  void initState() {
    super.initState();
    final r = widget.report;
    _titleController = TextEditingController(text: r?.title ?? '');
    _descriptionController = TextEditingController(text: r?.description ?? '');
    _typeController = TextEditingController(text: r?.type ?? '');
    _severityController = TextEditingController(text: r?.severity ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    _severityController.dispose();
    super.dispose();
  }

  Future<String> _getUserId() async {
    return 'user123'; // replace with actual auth logic
  }

  Future<Position> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() => _gettingLocation = false);
      throw Exception('Location permission denied');
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    setState(() => _gettingLocation = false);
    return pos;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = widget.report != null;
    final userId = await _getUserId();

    try {
      final position = await _getCurrentLocation();
      final newReport = Report(
        id: widget.report?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _typeController.text.trim(),
        severity: _severityController.text.trim(),
        createdAt: widget.report?.createdAt ?? Timestamp.now(),
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final provider = context.read<ReportProvider>();
      if (isEditing) {
        await provider.updateReport(newReport);
      } else {
        await provider.addReport(newReport);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Report updated' : 'Report added'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.report != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Report' : 'Add Report'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(_titleController, 'Title'),
              _buildTextField(_descriptionController, 'Description'),
              _buildTextField(_typeController, 'Type'),
              _buildTextField(_severityController, 'Severity'),
              if (_gettingLocation) const Padding(padding: EdgeInsets.only(top: 12), child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _gettingLocation ? null : _submit,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) => (value == null || value.isEmpty) ? 'Enter $label' : null,
      ),
    );
  }
}

class ViewReportDialog extends StatelessWidget {
  final Report report;
  const ViewReportDialog({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetail('Title', report.title),
            _buildDetail('Description', report.description),
            _buildDetail('Type', report.type),
            _buildDetail('Severity', report.severity),
            _buildDetail('User ID', report.userId),
            _buildDetail('Created At', report.createdAt.toDate().toString()),
            _buildDetail('Latitude', '${report.latitude}'),
            _buildDetail('Longitude', '${report.longitude}'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$label: $value', style: const TextStyle(fontSize: 14)),
    );
  }
}
