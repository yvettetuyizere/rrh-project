import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

enum WeatherCondition {
  clear(Icons.wb_sunny),
  clouds(Icons.cloud),
  rain(Icons.water_drop),
  snow(Icons.ac_unit),
  thunderstorm(Icons.flash_on),
  other(Icons.help_outline);

  const WeatherCondition(this.icon);
  final IconData icon;
}

class WeatherSafeZonesScreen extends StatefulWidget {
  const WeatherSafeZonesScreen({super.key});

  @override
  State<WeatherSafeZonesScreen> createState() => _WeatherSafeZonesScreenState();
}

class _WeatherSafeZonesScreenState extends State<WeatherSafeZonesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _locationError;
  LatLng _currentLocation = const LatLng(-1.9403, 29.8739); // Default to Rubavu
  String _climateData = 'Loading climate data...';
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  static const String _apiKey = '2f32da99ee6e6c6d3380328c3782c359';

  static const LatLng rwandaCenter = LatLng(-1.9403, 29.8739);

  final Map<String, LatLng> rwandaCities = {
    'Kigali': const LatLng(-1.9441, 30.0619),
    'Butare': const LatLng(-2.5967, 29.7397),
    'Gisenyi': const LatLng(-1.7028, 29.2564),
    'Ruhengeri': const LatLng(-1.4997, 29.6347),
    'Kibuye': const LatLng(-2.0603, 29.3478),
    'Byumba': const LatLng(-1.5764, 30.0675),
    'Cyangugu': const LatLng(-2.4847, 28.9075),
    'Rwamagana': const LatLng(-1.9486, 30.4347),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeNotifications();
    _initializeData();
    _addRwandaCityMarkers();
  }

  void _initializeNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await flutterLocalNotificationsPlugin.initialize(settings);
  }

  Future<void> showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'weather_channel',
      'Weather Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
  }

  Future<void> _initializeData() async {
    try {
      await _getCurrentLocation();
      await _getClimateData();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Error loading location data';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      await Geolocator.requestPermission();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          if (mounted) setState(() => _locationError = 'Location permission denied');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: _currentLocation,
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
          );
        });
      }
    } catch (e) {
      log('Error getting location: $e');
      if (mounted) setState(() => _locationError = 'Could not get your location');
    }
  }

  Future<void> _getClimateData() async {
    try {
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=${_currentLocation.latitude}&lon=${_currentLocation.longitude}&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weatherMain = data['weather'][0]['main'].toString().toLowerCase();
        final temp = data['main']['temp'];
        final humidity = data['main']['humidity'];
        final windSpeed = data['wind']['speed'];

        final displayData =
            'Temperature: ${temp.toStringAsFixed(1)}°C\nHumidity: $humidity%\nWind: ${windSpeed.toStringAsFixed(1)} km/h';

        if (mounted) {
          setState(() {
            _climateData = displayData;
          });
        }

       String title = 'Weather Alert';
String body = '';

switch (weatherMain) {
  case 'rain':
    body = 'Rain is expected. ☔\nTemperature: ${temp.toStringAsFixed(1)}°C\nHumidity: $humidity%\nWind: ${windSpeed.toStringAsFixed(1)} km/h';
    break;
  case 'thunderstorm':
    body = 'Thunderstorm warning! ⚡\nTemperature: ${temp.toStringAsFixed(1)}°C\nHumidity: $humidity%\nWind: ${windSpeed.toStringAsFixed(1)} km/h';
    break;
  case 'clear':
    body = 'Clear skies today. 🌞\nTemperature: ${temp.toStringAsFixed(1)}°C\nHumidity: $humidity%\nWind: ${windSpeed.toStringAsFixed(1)} km/h';
    break;
  case 'clouds':
    body = 'It’s cloudy today. ☁️\nTemperature: ${temp.toStringAsFixed(1)}°C\nHumidity: $humidity%\nWind: ${windSpeed.toStringAsFixed(1)} km/h';
    break;
  default:
    body = 'Current weather:\nTemperature: ${temp.toStringAsFixed(1)}°C\nHumidity: $humidity%\nWind: ${windSpeed.toStringAsFixed(1)} km/h';
}

await showLocalNotification(title, body);

      }
    } catch (e) {
      log('Weather fetch error: $e');
      if (mounted) {
        setState(() {
          _climateData = 'Failed to load weather data';
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _locationError = null;
    });
    await _initializeData();
  }

  void _addRwandaCityMarkers() {
    final newMarkers = <Marker>{};
    rwandaCities.forEach((city, location) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(city),
          position: location,
          infoWindow: InfoWindow(
            title: city,
            snippet: 'Major city in Rwanda',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
    setState(() {
      _markers.addAll(newMarkers);
    });
  }

  void _centerMapOnRwanda() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: rwandaCenter,
          zoom: 7,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather & Safe Zones'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _centerMapOnRwanda,
            tooltip: 'Center on Rwanda',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Safe Zones'),
            Tab(icon: Icon(Icons.wb_sunny), text: 'Weather'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locationError != null
              ? Center(child: Text(_locationError!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMapTab(),
                    _buildWeatherTab(),
                  ],
                ),
    );
  }

  Widget _buildMapTab() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentLocation,
        zoom: 12,
      ),
      markers: _markers,
      onMapCreated: (controller) {
        _mapController = controller;
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentLocation),
        );
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildWeatherTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Weather',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_climateData),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Weather Alerts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('No active weather alerts'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
