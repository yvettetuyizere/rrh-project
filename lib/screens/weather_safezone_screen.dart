import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Replace with your actual API key from OpenWeatherMap
const String openWeatherApiKey = 'AIzaSyAusq8vUZpGhV16R2yF4B1RCUvCAeykwBs';

class WeatherSafeZonesScreen extends StatefulWidget {
  // Callback to send weather data updates
  final void Function({
    double? temperature,
    int? humidity,
    String? description,
    bool? willRainSoon,
  })? onWeatherUpdated;

  const WeatherSafeZonesScreen({super.key, this.onWeatherUpdated});

  @override
  WeatherSafeZonesScreenState createState() => WeatherSafeZonesScreenState();
}

class WeatherSafeZonesScreenState extends State<WeatherSafeZonesScreen> {
  LatLng? _currentLocation;
  String? _weatherDescription;
  double? _temperature;
  int? _humidity;
  bool _willRainSoon = false;

  bool _loading = true;
  String? _error;

  final List<LatLng> _safeZones = [
    const LatLng(-1.9441, 30.0619), // Kigali
    const LatLng(-2.0000, 30.1000), // Mock location
  ];

  @override
  void initState() {
    super.initState();
    _initLocationAndWeather();
  }

  Future<void> _initLocationAndWeather() async {
    try {
      // Get current location with new LocationSettings API
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _currentLocation = LatLng(position.latitude, position.longitude);

      // Fetch weather data from OpenWeatherMap
      await _fetchWeather();

      // Notify parent widget via callback if provided
      if (widget.onWeatherUpdated != null) {
        widget.onWeatherUpdated!(
          temperature: _temperature,
          humidity: _humidity,
          description: _weatherDescription,
          willRainSoon: _willRainSoon,
        );
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to get location or weather: $e';
        _loading = false;
      });
    }
  }

  Future<void> _fetchWeather() async {
    if (_currentLocation == null) return;

    final lat = _currentLocation!.latitude;
    final lon = _currentLocation!.longitude;

    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$openWeatherApiKey&units=metric';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        _temperature = (data['main']['temp'] as num).toDouble();
        _humidity = (data['main']['humidity'] as num).toInt();
        _weatherDescription = data['weather'][0]['description'];

        final weatherMain =
            data['weather'][0]['main'].toString().toLowerCase();
        _willRainSoon = weatherMain.contains('rain') ||
            weatherMain.contains('drizzle') ||
            weatherMain.contains('thunderstorm');
      });
    } else {
      setState(() {
        _error = 'Failed to fetch weather data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Zones & Weather'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation!,
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('current_location'),
                            position: _currentLocation!,
                            infoWindow: const InfoWindow(title: 'Your Location'),
                          ),
                          ..._safeZones.map(
                            (zone) => Marker(
                              markerId: MarkerId(zone.toString()),
                              position: zone,
                              infoWindow: const InfoWindow(title: 'Safe Zone'),
                            ),
                          ),
                        },
                        onMapCreated: (controller) {
                          // You can use controller if needed
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Weather',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                                'Temperature: ${_temperature?.toStringAsFixed(1) ?? '--'} °C'),
                            Text('Humidity: ${_humidity ?? '--'} %'),
                            Text('Condition: ${_weatherDescription ?? '--'}'),
                            const SizedBox(height: 20),
                            if (_willRainSoon)
                              Row(
                                children: const [
                                  Icon(Icons.warning, color: Colors.red),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Warning: Rain expected soon! Please take precautions.',
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
    );
  }
}
