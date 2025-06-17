import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enums.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flood Alerts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snapshot.data?.docs ?? [];

          if (alerts.isEmpty) {
            return const Center(child: Text('No alerts at the moment'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index].data() as Map<String, dynamic>;
              final severity = AlertSeverity.values.firstWhere(
                (e) => e.name == (alert['severity'] as String).toLowerCase(),
                orElse: () => AlertSeverity.medium,
              );
              final message = alert['message'] as String;
              final timestamp = (alert['timestamp'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: severity.color,
                    child: Icon(severity.icon, color: Colors.white),
                  ),
                  title: Text(
                    severity.displayName.toUpperCase(),
                    style: TextStyle(
                      color: severity.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(message),
                      const SizedBox(height: 4),
                      Text(
                        'Posted on ${timestamp.toString()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
