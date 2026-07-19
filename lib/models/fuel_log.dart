import 'package:cloud_firestore/cloud_firestore.dart';

class FuelLog {
  final String id;
  final String vehicleId;
  final double liters;
  final double price;
  final double odo;
  final bool isFullTank;
  final DateTime date;

  FuelLog({
    required this.id,
    required this.vehicleId,
    required this.liters,
    required this.price,
    required this.odo,
    this.isFullTank = true,
    required this.date,
  });

  factory FuelLog.fromJson(Map<String, dynamic> json, String documentId) {
    return FuelLog(
      id: documentId,
      vehicleId: json['vehicleId'] as String? ?? '',
      liters: (json['liters'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      odo: (json['odo'] as num?)?.toDouble() ?? 0.0,
      isFullTank: json['isFullTank'] as bool? ?? true,
      date: json['date'] != null
          ? (json['date'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'liters': liters,
      'price': price,
      'odo': odo,
      'isFullTank': isFullTank,
      'date': Timestamp.fromDate(date),
    };
  }
}
