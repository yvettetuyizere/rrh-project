import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Procedures',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '1. Stay calm and assess the situation\n'
                      '2. Move to higher ground immediately\n'
                      '3. Follow evacuation routes to safe zones\n'
                      '4. Keep emergency supplies ready\n'
                      '5. Stay informed through official channels',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Emergency Contacts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildEmergencyContactCard(
              'Police',
              '112',
              Icons.local_police,
              Colors.blue,
            ),
            _buildEmergencyContactCard(
              'Fire Department',
              '114',
              Icons.fire_truck,
              Colors.red,
            ),
            _buildEmergencyContactCard(
              'Ambulance',
              '912',
              Icons.medical_services,
              Colors.green,
            ),
            _buildEmergencyContactCard(
              'Flood Emergency',
              '112',
              Icons.warning_amber_rounded,
              Colors.orange,
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Kit Checklist',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '• First aid kit\n'
                      '• Flashlight and batteries\n'
                      '• Non-perishable food\n'
                      '• Medications\n'
                      '• Important documents\n'
                      '• Cash\n'
                      '• Phone charger\n'
                      '• Emergency blanket\n'
                      '• Whistle',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard(
    String title,
    String phoneNumber,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(phoneNumber),
        trailing: IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () => _makePhoneCall(phoneNumber),
        ),
      ),
    );
  }
}
