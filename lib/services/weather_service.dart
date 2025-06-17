import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  final String apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';

  factory WeatherService() => _instance;

  WeatherService._internal();

  // Get current weather for a location
  Future<Map<String, dynamic>> getCurrentWeather(double lat, double lon) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  // Get weather forecast for a location
  Future<Map<String, dynamic>> getWeatherForecast(
      double lat, double lon) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather forecast');
    }
  }

  // Get weather alerts for a location
  Future<List<Map<String, dynamic>>> getWeatherAlerts(
      double lat, double lon) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/onecall?lat=$lat&lon=$lon&exclude=current,minutely,hourly,daily&appid=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['alerts'] ?? []);
    } else {
      throw Exception('Failed to load weather alerts');
    }
  }

  // Get current location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Get location name from coordinates
  Future<String> getLocationName(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.locality}, ${place.country}';
      }
      return 'Unknown Location';
    } catch (e) {
      return 'Unknown Location';
    }
  }

  // Check for severe weather conditions
  bool isSevereWeather(Map<String, dynamic> weatherData) {
    final main = weatherData['main'];
    final weather = weatherData['weather'][0];

    // Check temperature extremes
    final temp = main['temp'] as double;
    if (temp < 0 || temp > 35) return true;

    // Check for severe weather conditions
    final condition = weather['main'].toString().toLowerCase();
    return condition.contains('thunderstorm') ||
        condition.contains('heavy rain') ||
        condition.contains('snow') ||
        condition.contains('extreme');
  }

  // Get weather alert message
  String getWeatherAlertMessage(Map<String, dynamic> weatherData) {
    final main = weatherData['main'];
    final weather = weatherData['weather'][0];
    final temp = main['temp'] as double;
    final condition = weather['main'].toString();
    final description = weather['description'].toString();

    if (temp < 0) {
      return 'Severe cold alert! Temperature is ${temp.toStringAsFixed(1)}°C. $description';
    } else if (temp > 35) {
      return 'Heat alert! Temperature is ${temp.toStringAsFixed(1)}°C. $description';
    } else if (condition.toLowerCase().contains('thunderstorm')) {
      return 'Thunderstorm alert! $description';
    } else if (condition.toLowerCase().contains('heavy rain')) {
      return 'Heavy rain alert! $description';
    } else if (condition.toLowerCase().contains('snow')) {
      return 'Snow alert! $description';
    }

    return 'Weather update: $description';
  }
}
