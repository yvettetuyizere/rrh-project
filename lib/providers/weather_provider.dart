import 'package:flutter/foundation.dart';

class WeatherProvider extends ChangeNotifier {
  double? temperature;
  int? humidity;
  String? description;
  bool willRainSoon = false;

  void updateWeather({
    double? temperature,
    int? humidity,
    String? description,
    bool? willRainSoon,
  }) {
    this.temperature = temperature ?? this.temperature;
    this.humidity = humidity ?? this.humidity;
    this.description = description ?? this.description;
    this.willRainSoon = willRainSoon ?? this.willRainSoon;
    notifyListeners();
  }
}
