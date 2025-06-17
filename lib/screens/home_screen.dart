import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/dashboard_operations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'report_screen.dart';
import 'emergency_screen.dart';
import 'learn_screen.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import 'weather_safezone_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class WeatherDashboard extends StatelessWidget {
  const WeatherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherProvider>();

    if (weather.temperature == null) {
      return const Text('No weather data yet');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dashboard Weather Info:', style: Theme.of(context).textTheme.titleMedium),
        Text('Temperature: ${weather.temperature?.toStringAsFixed(1)} °C'),
        Text('Humidity: ${weather.humidity} %'),
        Text('Condition: ${weather.description}'),
        if (weather.willRainSoon)
          const Text(
            'Rain expected soon! Take precautions.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  static const _bottomNavItems = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.cloud_rounded),
      label: 'Weather',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.report_rounded),
      label: 'Report',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.emergency_rounded),
      label: 'Emergency',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.school_rounded),
      label: 'Learn',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDashboardData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final data = await DashboardOperations.getDashboardStats();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.forward();
      }
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() => _isLoading = true);
    _animationController.reset();
    await _loadDashboardData();
    await DashboardOperations.recordActivity(
      'Dashboard Refreshed',
      details: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF80441E),
              Color(0xFFA0541F),
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Rwanda Resilience Hub',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            onSelected: (value) async {
              if (value == 'profile') {
                context.push('/profile');
              } else if (value == 'change_password') {
                context.push('/change-password');
              } else if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                context.go('/splash');
              }
            },
            itemBuilder: (context) => [
              _buildPopupMenuItem('profile', Icons.person_rounded, 'Profile'),
              _buildPopupMenuItem('change_password', Icons.lock_rounded, 'Change Password'),
              const PopupMenuDivider(),
              _buildPopupMenuItem('logout', Icons.logout_rounded, 'Logout', isDestructive: true),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon, String text, {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive ? Colors.red[600] : const Color(0xFF80441E),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isDestructive ? Colors.red[600] : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        items: _bottomNavItems,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF80441E),
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const WeatherSafeZonesScreen();
      case 2:
        return const ReportScreen();
      case 3:
        return const EmergencyScreen();
      case 4:
        return const LearnScreen();
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF80441E)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading dashboard...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      color: const Color(0xFF80441E),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        _buildHeroSection(),
                        _buildWelcomeSection(),
                        const SizedBox(height: 32),
                        _buildQuickActions(),
                        const SizedBox(height: 32),
                        _buildStatsSection(),
                        const SizedBox(height: 32),
                        _buildRecentActivitySection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/pic12.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              cacheWidth: (MediaQuery.of(context).size.width * 2).toInt(),
              cacheHeight: 400,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stay Prepared, Stay Safe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your comprehensive disaster resilience companion',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';
    final timeOfDay = _getTimeOfDay();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$timeOfDay, $displayName',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF80441E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to keep Rwanda resilient today?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF80441E), Color(0xFFA0541F)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF80441E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Report Incident',
                  Icons.report_rounded,
                  Colors.blue,
                  () => setState(() => _selectedIndex = 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Emergency',
                  Icons.emergency_rounded,
                  Colors.red,
                  () => setState(() => _selectedIndex = 3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF80441E),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildEnhancedStatCard(
                'Active Reports',
                _dashboardData['activeReports']?.toString() ?? '0',
                Icons.report_rounded,
                Colors.blue,
                'reports today',
              ),
              _buildEnhancedStatCard(
                'Safe Zones',
                _dashboardData['safeZones']?.toString() ?? '0',
                Icons.location_on_rounded,
                Colors.green,
                'zones available',
              ),
              _buildEnhancedStatCard(
                'Weather Alerts',
                _dashboardData['weatherAlerts']?.toString() ?? '0',
                Icons.wb_sunny_rounded,
                Colors.orange,
                'active alerts',
              ),
              _buildEnhancedStatCard(
                'Emergency Contacts',
                _dashboardData['emergencyContacts']?.toString() ?? '0',
                Icons.phone_rounded,
                Colors.red,
                'contacts ready',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: 28),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF80441E),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF80441E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActivityItem(
                  'Weather alert issued for Kigali',
                  '2 hours ago',
                  Icons.warning_rounded,
                  Colors.orange,
                ),
                const Divider(height: 1),
                _buildActivityItem(
                  'New safe zone added in Nyamirambo',
                  '5 hours ago',
                  Icons.location_on_rounded,
                  Colors.green,
                ),
                const Divider(height: 1),
                _buildActivityItem(
                  'Emergency drill completed',
                  '1 day ago',
                  Icons.check_circle_rounded,
                  Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Keep the existing tab classes for compatibility
class WeatherTab extends StatelessWidget {
  const WeatherTab({super.key});
  
  @override
  Widget build(BuildContext context) {
    final weather = {
      'location': 'Kigali',
      'temperature': '24°C',
      'condition': 'Partly Cloudy',
      'humidity': '60%',
      'wind': '12 km/h',
    };
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                weather['location']!,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                weather['temperature']!,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange),
              ),
              const SizedBox(height: 8),
              Text(weather['condition']!, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Humidity: ${weather['humidity']}'),
                  const SizedBox(width: 16),
                  Text('Wind: ${weather['wind']}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Reports Screen'));
  }
}

class EmergencyTab extends StatelessWidget {
  const EmergencyTab({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Emergency Screen'));
  }
}

class LearnTab extends StatelessWidget {
  const LearnTab({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Learning Resources'));
  }
}

class SafeZonesTab extends StatefulWidget {
  const SafeZonesTab({super.key});
  
  @override
  State<SafeZonesTab> createState() => _SafeZonesTabState();
}

class _SafeZonesTabState extends State<SafeZonesTab> {
  final List<LatLng> _safeZones = [
    const LatLng(-1.9441, 30.0619), // Kigali
    const LatLng(-2.0000, 30.1000), // Mock location
  ];

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(-1.9441, 30.0619),
        zoom: 12,
      ),
      markers: _safeZones
          .map((zone) => Marker(
                markerId: MarkerId(zone.toString()),
                position: zone,
                infoWindow: const InfoWindow(title: 'Safe Zone'),
              ))
          .toSet(),
      onMapCreated: (controller) {},
    );
  }
}

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather')),
      body: const Center(child: Text('Weather details go here')),
    );
  }
}