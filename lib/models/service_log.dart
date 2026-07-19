import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single verified service entry in the Digital Logbook.
/// Stored under: vehicles/{vehicleId}/serviceLogs/{logId}
class ServiceLog {
  final String id;
  final String vehicleId;
  final String partName;
  final double odoAtService;
  final DateTime serviceDate;
  final String? notes;

  ServiceLog({
    required this.id,
    required this.vehicleId,
    required this.partName,
    required this.odoAtService,
    required this.serviceDate,
    this.notes,
  });

  factory ServiceLog.fromJson(Map<String, dynamic> json, String documentId) {
    return ServiceLog(
      id: documentId,
      vehicleId: json['vehicleId'] as String? ?? '',
      partName: json['partName'] as String? ?? 'Unknown Part',
      odoAtService: (json['odoAtService'] as num?)?.toDouble() ?? 0.0,
      serviceDate: json['serviceDate'] != null
          ? (json['serviceDate'] as Timestamp).toDate()
          : DateTime.now(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'partName': partName,
      'odoAtService': odoAtService,
      'serviceDate': Timestamp.fromDate(serviceDate),
      'notes': notes,
    };
  }
}
