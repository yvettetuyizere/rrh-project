// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Report _$ReportFromJson(Map<String, dynamic> json) => Report(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      userId: json['userId'] as String,
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      imageUrl: json['imageUrl'] as String?,
      fileUrl: json['fileUrl'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: _$JsonConverterFromJson<Object, Timestamp>(
          json['approvedAt'], const TimestampConverter().fromJson),
      type: json['type'] as String,
      severity: json['severity'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
    );

Map<String, dynamic> _$ReportToJson(Report instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'userId': instance.userId,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'imageUrl': instance.imageUrl,
      'fileUrl': instance.fileUrl,
      'isApproved': instance.isApproved,
      'approvedBy': instance.approvedBy,
      'approvedAt': _$JsonConverterToJson<Object, Timestamp>(
          instance.approvedAt, const TimestampConverter().toJson),
      'type': instance.type,
      'severity': instance.severity,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'status': instance.status,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
