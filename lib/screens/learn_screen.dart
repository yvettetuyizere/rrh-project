import 'package:flutter/material.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'Understanding Floods',
            Icons.water,
            'Learn about different types of floods and their causes',
            [
              'Flash floods occur suddenly and can be deadly',
              'River floods develop slowly over days or weeks',
              'Coastal floods are caused by storm surges and high tides',
              'Urban floods happen when drainage systems are overwhelmed',
            ],
          ),
          _buildSection(
            'Flood Safety Tips',
            Icons.safety_check,
            'Essential safety measures during floods',
            [
              'Never walk or drive through floodwaters',
              'Stay away from downed power lines',
              'Keep emergency supplies ready',
              'Follow evacuation orders immediately',
              'Stay informed through official channels',
            ],
          ),
          _buildSection(
            'Preparing for Floods',
            Icons.home_repair_service,
            'Steps to prepare your home and family',
            [
              'Create an emergency plan with your family',
              'Prepare an emergency kit with essential supplies',
              'Elevate electrical appliances and utilities',
              'Install flood barriers and seal basement walls',
              'Keep important documents in waterproof containers',
            ],
          ),
          _buildSection(
            'After a Flood',
            Icons.cleaning_services,
            'What to do once floodwaters recede',
            [
              'Wait for authorities to declare it safe to return',
              'Document damage with photos for insurance',
              'Clean and disinfect everything that got wet',
              'Check for structural damage before entering',
              'Be aware of potential health hazards',
            ],
          ),
          _buildSection(
            'Community Response',
            Icons.people,
            'How communities can work together',
            [
              'Participate in community flood drills',
              'Join local emergency response teams',
              'Share information with neighbors',
              'Help vulnerable community members',
              'Report flood damage to authorities',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    String subtitle,
    List<String> points,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: const Color(0xFF80441E)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...points.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, color: Color(0xFF80441E)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
