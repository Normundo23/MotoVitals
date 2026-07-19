import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/vehicle.dart';
import '../models/service_log.dart';

class DataExportService {
  static Future<void> exportVehicleData({
    required Vehicle vehicle,
    required List<ServiceLog> serviceLogs,
  }) async {
    final data = {
      'vehicle': vehicle.toJson(),
      'serviceLogs': serviceLogs.map((log) => log.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': 'Moto Vitals 1.0.0',
    };

    final jsonString = jsonEncode(data);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/moto_vitals_backup.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Moto Vitals Backup - ${vehicle.make} ${vehicle.modelName}',
      text: 'Backup of your motorcycle maintenance data from Moto Vitals.',
    );
  }

  static Future<void> exportServiceLogsAsCsv({
    required String vehicleName,
    required List<ServiceLog> serviceLogs,
  }) async {
    if (serviceLogs.isEmpty) {
      throw Exception('No service logs to export');
    }

    final csvHeader = 'Date,Odometer,Part,Notes\n';
    final csvRows = serviceLogs.map((log) {
      final date = '${log.serviceDate.day}/${log.serviceDate.month}/${log.serviceDate.year}';
      final odo = log.odoAtService.toStringAsFixed(0);
      final part = log.partName;
      final notes = log.notes?.replaceAll(',', ';') ?? '';
      return '$date,$odo,$part,$notes';
    }).join('\n');

    final csvContent = csvHeader + csvRows;
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/service_logs_$vehicleName.csv');
    await file.writeAsString(csvContent);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Service Logs - $vehicleName',
      text: 'Exported ${serviceLogs.length} service records.',
    );
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
