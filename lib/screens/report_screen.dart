import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/report.dart';
import '../providers/report_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Safe context usage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReportProvider>().fetchReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportProvider>().getFilteredReports(searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search reports...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
        ),
      ),
      body: reports.isEmpty
          ? const Center(child: Text('No reports found'))
          : ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                final createdAt = report.createdAt.toDate();
                final formattedTime = DateFormat.yMd().add_jm().format(createdAt);

                return ListTile(
                  title: Text(report.title),
                  subtitle: Text(report.description),
                  trailing: Text(formattedTime),
                  onTap: () {
                    // Navigate to detail screen if needed
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddReportDialog(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddReportDialog extends StatefulWidget {
  const AddReportDialog({super.key});

  @override
  State<AddReportDialog> createState() => _AddReportDialogState();
}

class _AddReportDialogState extends State<AddReportDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _typeController = TextEditingController();
  final _severityController = TextEditingController();

  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  Position? _currentPosition;
  String _locationStatus = 'Location not captured yet';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _typeController.dispose();
    _severityController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationStatus = 'Getting current location...';
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'Location services are disabled. Please enable location services.';
          _isGettingLocation = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Location permission denied. Please grant location permission.';
            _isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Location permissions are permanently denied. Please enable them in settings.';
          _isGettingLocation = false;
        });
        return;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      setState(() {
        _locationStatus = 'Location captured successfully!';
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Failed to get location: ${e.toString()}';
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final type = _typeController.text.trim();
    final severity = _severityController.text.trim();

    if ([title, desc, type, severity].any((element) => element.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_currentPosition == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available. Please wait or try refreshing location.'),
        ),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final report = Report(
      title: title,
      description: desc,
      userId: userId,
      createdAt: Timestamp.now(),
      type: type,
      severity: severity,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
    );

    // Store context references before async operation
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final reportProvider = context.read<ReportProvider>();

    try {
      await reportProvider.addReport(report);
      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Report added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error adding report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Report'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _severityController,
              decoration: const InputDecoration(labelText: 'Severity'),
            ),
            const SizedBox(height: 16),
            
            // Location Status Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _currentPosition != null 
                    ? Colors.green.shade50 
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _currentPosition != null 
                      ? Colors.green.shade200 
                      : Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _currentPosition != null 
                            ? Icons.location_on 
                            : Icons.location_searching,
                        color: _currentPosition != null 
                            ? Colors.green 
                            : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Location Status:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_locationStatus),
                  if (_currentPosition != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  if (_isGettingLocation) ...[
                    const SizedBox(height: 8),
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _isGettingLocation ? null : _getCurrentLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Location'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isSubmitting || _currentPosition == null) ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}