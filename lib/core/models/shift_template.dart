import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'shift_template.freezed.dart';
part 'shift_template.g.dart';

// Conversores personalizados para manejar Firebase Timestamp
class DateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const DateTimeConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    
    if (json is String) {
      return DateTime.parse(json);
    } else if (json is Timestamp) {
      return json.toDate();
    } else if (json is DateTime) {
      return json;
    }
    
    throw Exception('No se puede convertir $json a DateTime');
  }

  @override
  dynamic toJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}

@freezed
class ShiftTemplate with _$ShiftTemplate {
  const factory ShiftTemplate({
    required String id,
    required String name,
    @Default('#3B82F6') String colorHex, // Color por defecto (azul)
    required String startTime, // Formato "HH:mm"
    required String endTime,   // Formato "HH:mm"
    String? description,
    String? familyId, // Agregar familyId para mantener la relación
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _ShiftTemplate;

  factory ShiftTemplate.fromJson(Map<String, dynamic> json) => _$ShiftTemplateFromJson(json);
}





