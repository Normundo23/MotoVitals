import 'package:flutter_test/flutter_test.dart';
import 'package:moto_vitals/models/service_log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('ServiceLog', () {
    final now = DateTime.now();
    final timestamp = Timestamp.fromDate(now);

    test('fromJson creates a valid ServiceLog', () {
      final json = {
        'vehicleId': 'veh123',
        'partName': 'Oil Filter',
        'odoAtService': 10000.0,
        'serviceDate': timestamp,
        'notes': 'Regular maintenance',
      };

      final log = ServiceLog.fromJson(json, 'log123');

      expect(log.id, 'log123');
      expect(log.vehicleId, 'veh123');
      expect(log.partName, 'Oil Filter');
      expect(log.odoAtService, 10000.0);
      expect(log.serviceDate, now);
      expect(log.notes, 'Regular maintenance');
    });

    test('toJson returns a valid map', () {
      final log = ServiceLog(
        id: 'log123',
        vehicleId: 'veh123',
        partName: 'Oil Filter',
        odoAtService: 10000.0,
        serviceDate: now,
        notes: 'Regular maintenance',
      );

      final json = log.toJson();

      expect(json['vehicleId'], 'veh123');
      expect(json['partName'], 'Oil Filter');
      expect(json['odoAtService'], 10000.0);
      expect(json['serviceDate'], isA<Timestamp>());
      expect((json['serviceDate'] as Timestamp).toDate(), now);
      expect(json['notes'], 'Regular maintenance');
    });
  });
}
