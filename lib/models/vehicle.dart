import 'package:cloud_firestore/cloud_firestore.dart';
import 'maintenance_part.dart';

enum VehicleModelType { hondaWinnerX, other }

class Vehicle {
  final String id;
  final String ownerId;
  final String make;
  final VehicleModelType modelType;
  final String modelName;
  final double odo;
  final DateTime? purchaseDate;
  final List<MaintenancePart> parts;

  /// Links to VehicleSpecDatabase.findById() for spec-aware maintenance.
  /// Null means the user picked "Other / not listed".
  final String? specModelId;

  Vehicle({
    required this.id,
    required this.ownerId,
    required this.make,
    required this.modelType,
    this.modelName = '',
    required this.odo,
    this.purchaseDate,
    this.parts = const [],
    this.specModelId,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json, String documentId) {
    return Vehicle(
      id: documentId,
      ownerId: json['ownerId'] as String? ?? '',
      make: json['make'] as String? ?? 'Unknown Make',
      modelType: VehicleModelType.values.firstWhere(
        (e) => e.name == json['modelType'],
        orElse: () => VehicleModelType.other,
      ),
      modelName: json['modelName'] as String? ?? '',
      odo: (json['odo'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: json['purchaseDate'] != null
          ? (json['purchaseDate'] as Timestamp).toDate()
          : null,
      parts: (json['parts'] as List<dynamic>?)
              ?.map((e) => MaintenancePart.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      specModelId: json['specModelId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'make': make,
      'modelType': modelType.name,
      'modelName': modelName,
      'odo': odo,
      'purchaseDate':
          purchaseDate != null ? Timestamp.fromDate(purchaseDate!) : null,
      'parts': parts.map((e) => e.toJson()).toList(),
      'specModelId': specModelId,
    };
  }
}
