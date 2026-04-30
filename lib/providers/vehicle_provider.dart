import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/maintenance_part.dart';
import '../services/database_service.dart';

class VehicleProvider extends ChangeNotifier {
  final DatabaseService _db;
  Vehicle? _currentVehicle;
  bool _isLoading = true;
  String? _error;

  Vehicle? get currentVehicle => _currentVehicle;
  bool get isLoading => _isLoading;
  String? get error => _error;

  VehicleProvider({DatabaseService? db}) : _db = db ?? DatabaseService() {
    _listenToVehicle();
  }

  void _listenToVehicle() {
    _db.userVehicleStream.listen(
      (vehicle) {
        _currentVehicle = vehicle;
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

  /// Updates the odometer reading. New odo must be >= current odo.
  Future<void> updateOdometer(double newOdo) async {
    if (_currentVehicle == null) return;
    if (newOdo <= 0) throw Exception("Odometer must be positive.");
    if (newOdo < _currentVehicle!.odo) {
      throw Exception(
          "New odometer cannot be less than current odometer (${_currentVehicle!.odo.toStringAsFixed(0)} km).");
    }

    final updatedVehicle = Vehicle(
      id: _currentVehicle!.id,
      ownerId: _currentVehicle!.ownerId,
      make: _currentVehicle!.make,
      modelType: _currentVehicle!.modelType,
      modelName: _currentVehicle!.modelName,
      odo: newOdo,
      purchaseDate: _currentVehicle!.purchaseDate,
      parts: _currentVehicle!.parts, // Odo update does not reset part service
    );

    await _db.saveVehicle(updatedVehicle);
    // The stream will automatically update _currentVehicle
  }

  /// Logs a service for a specific part by resetting its lastServiceOdo
  /// to the current odometer reading. This is the Digital Service Logbook entry.
  ///
  /// [partName] must match the part's name exactly.
  Future<void> logService(String partName) async {
    if (_currentVehicle == null) return;

    final currentOdo = _currentVehicle!.odo;

    final updatedParts = _currentVehicle!.parts.map((part) {
      if (part.name == partName) {
        // Reset lastServiceOdo to current odometer — part is now "fresh"
        return MaintenancePart(
          name: part.name,
          interval: part.interval,
          lastServiceOdo: currentOdo,
        );
      }
      return part;
    }).toList();

    final updatedVehicle = Vehicle(
      id: _currentVehicle!.id,
      ownerId: _currentVehicle!.ownerId,
      make: _currentVehicle!.make,
      modelType: _currentVehicle!.modelType,
      modelName: _currentVehicle!.modelName,
      odo: currentOdo,
      purchaseDate: _currentVehicle!.purchaseDate,
      parts: updatedParts,
    );

    await _db.saveVehicle(updatedVehicle);
    // Stream will update UI automatically
  }
}
