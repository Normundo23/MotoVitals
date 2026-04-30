import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/database_service.dart';

class VehicleEntryScreen extends StatefulWidget {
  const VehicleEntryScreen({super.key});

  @override
  State<VehicleEntryScreen> createState() => _VehicleEntryScreenState();
}

class _VehicleEntryScreenState extends State<VehicleEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelNameController = TextEditingController();
  final _odoController = TextEditingController();

  DateTime? _purchaseDate;
  bool _isLoading = false;

  // The existing vehicle, if any (used to detect edit vs create)
  Vehicle? _existingVehicle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill fields if the user already has a vehicle (edit mode)
    if (_existingVehicle == null) {
      final provider = context.read<VehicleProvider>();
      final vehicle = provider.currentVehicle;
      if (vehicle != null) {
        _existingVehicle = vehicle;
        _makeController.text = vehicle.make;
        _modelNameController.text = vehicle.modelName;
        _odoController.text = vehicle.odo.toStringAsFixed(0);
        _purchaseDate = vehicle.purchaseDate;
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepPurpleAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_purchaseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a purchase date.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in.");

      final db = DatabaseService();
      final odoValue = double.parse(_odoController.text);

      if (odoValue <= 0) throw Exception("Odometer must be positive.");

      // EDIT MODE: reuse existing vehicle ID and preserve existing parts
      // CREATE MODE: generate a new Firestore document ID
      final String vehicleId = _existingVehicle?.id ??
          FirebaseFirestore.instance.collection('vehicles').doc().id;

      // If editing and new odo is less than existing, block it
      if (_existingVehicle != null && odoValue < _existingVehicle!.odo) {
        throw Exception(
            "New odometer (${odoValue.toStringAsFixed(0)} km) cannot be less than current (${_existingVehicle!.odo.toStringAsFixed(0)} km).");
      }

      final vehicleToSave = Vehicle(
        id: vehicleId,
        ownerId: user.uid,
        make: _makeController.text.trim(),
        modelName: _modelNameController.text.trim(),
        modelType: _existingVehicle?.modelType ?? VehicleModelType.other,
        odo: odoValue,
        purchaseDate: _purchaseDate,
        // Preserve existing parts on edit; DatabaseService will add defaults on create
        parts: _existingVehicle?.parts ?? [],
      );

      await db.saveVehicle(vehicleToSave);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _existingVehicle != null
                ? 'Vehicle updated!'
                : 'Vehicle added to Garage!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelNameController.dispose();
    _odoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = _existingVehicle != null;

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Vehicle' : 'Add Vehicle',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditMode ? 'Update Your Ride' : 'Garage Entry',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEditMode
                      ? 'Update your motorcycle details below.'
                      : 'Register a new motorcycle to start tracking.',
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Make Field
                TextFormField(
                  controller: _makeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Make (e.g., Honda, Yamaha)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Model Field
                TextFormField(
                  controller: _modelNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Model Name (e.g., Winner X)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Odometer Field
                TextFormField(
                  controller: _odoController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Current Odometer (km)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    suffixText: 'km',
                    suffixStyle: const TextStyle(color: Colors.white54),
                    helperText: isEditMode
                        ? 'Current: ${_existingVehicle!.odo.toStringAsFixed(0)} km'
                        : null,
                    helperStyle: const TextStyle(color: Colors.white38),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    final parsed = double.tryParse(val);
                    if (parsed == null) return 'Must be a number';
                    if (parsed <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Purchase Date Field
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _purchaseDate == null
                              ? 'Select Purchase Date'
                              : 'Purchase Date: ${_purchaseDate!.toLocal().toString().split(' ')[0]}',
                          style: TextStyle(
                            color: _purchaseDate == null
                                ? Colors.white54
                                : Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(Icons.calendar_today,
                            color: Colors.white54),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Save Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditMode ? 'Update Vehicle' : 'Save Vehicle',
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
