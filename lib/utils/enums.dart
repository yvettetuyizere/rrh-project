import 'package:flutter/material.dart';

enum AlertSeverity {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case AlertSeverity.low:
        return Colors.yellow;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.high:
        return Colors.red;
      case AlertSeverity.critical:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case AlertSeverity.low:
        return Icons.info;
      case AlertSeverity.medium:
        return Icons.warning;
      case AlertSeverity.high:
        return Icons.warning_amber_rounded;
      case AlertSeverity.critical:
        return Icons.error;
    }
  }
}

enum SafeZoneType {
  emergency,
  evacuation,
  shelter;

  String get displayName {
    switch (this) {
      case SafeZoneType.emergency:
        return 'Emergency Center';
      case SafeZoneType.evacuation:
        return 'Evacuation Point';
      case SafeZoneType.shelter:
        return 'Shelter';
    }
  }

  Color get color {
    switch (this) {
      case SafeZoneType.emergency:
        return Colors.red;
      case SafeZoneType.evacuation:
        return Colors.green;
      case SafeZoneType.shelter:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (this) {
      case SafeZoneType.emergency:
        return Icons.emergency;
      case SafeZoneType.evacuation:
        return Icons.directions_run;
      case SafeZoneType.shelter:
        return Icons.home;
    }
  }
}

enum ReportType {
  flood,
  landslide,
  infrastructureDamage,
  other;

  String get displayName {
    switch (this) {
      case ReportType.flood:
        return 'Flood';
      case ReportType.landslide:
        return 'Landslide';
      case ReportType.infrastructureDamage:
        return 'Infrastructure Damage';
      case ReportType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportType.flood:
        return Icons.water;
      case ReportType.landslide:
        return Icons.terrain;
      case ReportType.infrastructureDamage:
        return Icons.construction;
      case ReportType.other:
        return Icons.more_horiz;
    }
  }
}

enum WeatherCondition {
  clear,
  clouds,
  rain,
  snow,
  thunderstorm,
  other;

  String get displayName {
    switch (this) {
      case WeatherCondition.clear:
        return 'Clear';
      case WeatherCondition.clouds:
        return 'Cloudy';
      case WeatherCondition.rain:
        return 'Rainy';
      case WeatherCondition.snow:
        return 'Snowy';
      case WeatherCondition.thunderstorm:
        return 'Thunderstorm';
      case WeatherCondition.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case WeatherCondition.clear:
        return Icons.wb_sunny;
      case WeatherCondition.clouds:
        return Icons.cloud;
      case WeatherCondition.rain:
        return Icons.grain;
      case WeatherCondition.snow:
        return Icons.ac_unit;
      case WeatherCondition.thunderstorm:
        return Icons.flash_on;
      case WeatherCondition.other:
        return Icons.wb_sunny;
    }
  }
}
 