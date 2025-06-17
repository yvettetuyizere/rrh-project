import 'package:cloud_firestore/cloud_firestore.dart';

/// Standalone functions for handling Firebase Timestamp in JSON serialization.
Timestamp timestampFromJson(dynamic json) {
  if (json is Timestamp) return json;
  if (json is Map && json.containsKey('_seconds')) {
    return Timestamp(json['_seconds'], json['_nanoseconds'] ?? 0);
  }
  throw FormatException('Invalid Timestamp: $json');
}

dynamic timestampToJson(Timestamp timestamp) => timestamp;
