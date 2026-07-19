import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/maintenance_part.dart';
import '../models/service_log.dart';
import '../services/database_service.dart';

class VehicleProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<Vehicle> _vehicles = [];
  String? _selectedVehicleId;
  bool _isLoading = true;
  String? _error;

  List<Vehicle> get vehicles => _vehicles;
  
  Vehicle? get currentVehicle {
    if (_vehicles.isEmpty) return null;
    if (_selectedVehicleId != null) {
      try {
        return _vehicles.firstWhere((v) => v.id == _selectedVehicleId);
      } catch (_) {
        return _vehicles.first;
      }
    }
    return _vehicles.first;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  VehicleProvider({DatabaseService? db}) : _db = db ?? DatabaseService() {
    _listenToVehicles();
  }

  void selectVehicle(String id) {
    _selectedVehicleId = id;
    notifyListeners();
  }

  void _listenToVehicles() {
    _db.userVehiclesStream.listen(
      (vehicles) {
        _vehicles = vehicles;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  /// Updates odometer reading. Must be >= current odo.
  Future<void> updateOdometer(double newOdo) async {
    final vehicle = currentVehicle;
    if (vehicle == null) return;
    if (newOdo <= 0) throw Exception("Odometer must be positive.");
    if (newOdo < vehicle.odo) {
      throw Exception(
          "New odometer cannot be less than current (${vehicle.odo.toStringAsFixed(0)} km).");
    }

    final updatedVehicle = Vehicle(
      id: vehicle.id,
      ownerId: vehicle.ownerId,
      make: vehicle.make,
      modelType: vehicle.modelType,
      modelName: vehicle.modelName,
      odo: newOdo,
      purchaseDate: vehicle.purchaseDate,
      parts: vehicle.parts,
      specModelId: vehicle.specModelId,
    );

    await _db.saveVehicle(updatedVehicle);
  }

  /// Logs a service for a part:
  /// 1. Resets the part's lastServiceOdo on the vehicle doc
  /// 2. Writes a ServiceLog entry to the serviceLogs subcollection
  Future<void> logService(String partName, {String? notes}) async {
    final vehicle = currentVehicle;
    if (vehicle == null) return;

    final currentOdo = vehicle.odo;

    final updatedParts = vehicle.parts.map((part) {
      if (part.name == partName) {
        return MaintenancePart(
          name: part.name,
          interval: part.interval,
          lastServiceOdo: currentOdo,
        );
      }
      return part;
    }).toList();

    final updatedVehicle = Vehicle(
      id: vehicle.id,
      ownerId: vehicle.ownerId,
      make: vehicle.make,
      modelType: vehicle.modelType,
      modelName: vehicle.modelName,
      odo: currentOdo,
      purchaseDate: vehicle.purchaseDate,
      parts: updatedParts,
      specModelId: vehicle.specModelId,
    );

    await _db.saveVehicle(updatedVehicle);

    // Write to Digital Service Logbook subcollection
    final log = ServiceLog(
      id: '',
      vehicleId: vehicle.id,
      partName: partName,
      odoAtService: currentOdo,
      serviceDate: DateTime.now(),
      notes: notes,
    );
    await _db.addServiceLog(log);
  }
}
