import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/database_service.dart';
import '../../data/vehicle_spec_database.dart';
import '../../models/vehicle_spec.dart';
import 'spec_sheet_screen.dart';

class VehicleEntryScreen extends StatefulWidget {
  const VehicleEntryScreen({super.key});
  @override
  State<VehicleEntryScreen> createState() => _VehicleEntryScreenState();
}

class _VehicleEntryScreenState extends State<VehicleEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odoController = TextEditingController();
  final _customMakeController = TextEditingController();
  final _customModelController = TextEditingController();

  DateTime? _purchaseDate;
  bool _isLoading = false;
  String? _selectedMake;
  VehicleSpec? _selectedSpec;
  bool _isCustomModel = false;
  Vehicle? _existingVehicle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_existingVehicle == null) {
      final vehicle = context.read<VehicleProvider>().currentVehicle;
      if (vehicle != null) {
        _existingVehicle = vehicle;
        _odoController.text = vehicle.odo.toStringAsFixed(0);
        _purchaseDate = vehicle.purchaseDate;
        if (vehicle.specModelId != null) {
          _selectedSpec = VehicleSpecDatabase.findById(vehicle.specModelId!);
          _selectedMake = _selectedSpec?.make;
        } else {
          _isCustomModel = true;
          _selectedMake = 'Other';
          _customMakeController.text = vehicle.make;
          _customModelController.text = vehicle.modelName;
        }
      }
    }
  }

  @override
  void dispose() {
    _odoController.dispose();
    _customMakeController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext ctx) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (c, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.deepPurpleAccent,
            onPrimary: Colors.white,
            surface: Color(0xFF1E1E2C),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(color: Colors.white)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_purchaseDate == null) { _snack('Select a purchase date', Colors.redAccent); return; }
    if (!_isCustomModel && _selectedSpec == null) { _snack('Select a model', Colors.redAccent); return; }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final odo = double.parse(_odoController.text);
      if (odo <= 0) throw Exception('Odometer must be positive');
      if (_existingVehicle != null && odo < _existingVehicle!.odo) {
        throw Exception('Cannot be less than current odo (${_existingVehicle!.odo.toStringAsFixed(0)} km)');
      }
      final vehicleId = _existingVehicle?.id ?? FirebaseFirestore.instance.collection('vehicles').doc().id;
      final make = _isCustomModel ? _customMakeController.text.trim() : _selectedSpec!.make;
      final modelName = _isCustomModel ? _customModelController.text.trim() : _selectedSpec!.modelName;
      final newVehicle = Vehicle(
        id: vehicleId, ownerId: user.uid, make: make,
        modelType: VehicleModelType.other, modelName: modelName,
        odo: odo, purchaseDate: _purchaseDate,
        specModelId: _isCustomModel ? null : _selectedSpec!.modelId,
        parts: _existingVehicle?.parts ?? [],
      );
      await DatabaseService().saveVehicle(newVehicle);
      if (!mounted) return;
      _snack(_existingVehicle != null ? 'Vehicle updated!' : 'Vehicle added!', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      _snack(e.toString(), Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _deco(String hint, {String? suffix, String? helper}) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: Colors.white24),
    filled: true, fillColor: const Color(0xFF1E1E2C),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 1.5)),
    suffixText: suffix, suffixStyle: const TextStyle(color: Colors.white38),
    helperText: helper, helperStyle: const TextStyle(color: Colors.white38, fontSize: 12),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
  );

  @override
  Widget build(BuildContext context) {
    final makes = [...VehicleSpecDatabase.makes, 'Other'];
    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(_existingVehicle != null ? 'Edit Vehicle' : 'Add Vehicle',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(_existingVehicle != null ? 'Update Your Ride' : 'Garage Entry',
                  style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Select your model to load manufacturer-spec maintenance intervals.',
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 28),

              // Make
              _label('Manufacturer'),
              _PickerTile(
                value: _selectedMake,
                placeholder: 'Select make',
                options: makes,
                onSelected: (val) => setState(() {
                  if (val == 'Other') { _isCustomModel = true; _selectedMake = 'Other'; _selectedSpec = null; }
                  else { _isCustomModel = false; _selectedMake = val; _selectedSpec = null; }
                }),
              ),
              const SizedBox(height: 16),

              // Model picker (known makes)
              if (_selectedMake != null && !_isCustomModel) ...[
                _label('Model'),
                _ModelPicker(
                  make: _selectedMake!,
                  selected: _selectedSpec,
                  onSelected: (s) => setState(() => _selectedSpec = s),
                ),
                const SizedBox(height: 16),
              ],

              // Custom fields
              if (_isCustomModel) ...[
                _label('Make (custom)'),
                TextFormField(
                  controller: _customMakeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _deco('e.g. Rusi, Kawasaki'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _label('Model (custom)'),
                TextFormField(
                  controller: _customModelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _deco('e.g. TMX 125 Alpha'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],

              // Spec preview
              if (_selectedSpec != null) ...[
                _SpecPreviewCard(
                  spec: _selectedSpec!,
                  onViewFull: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SpecSheetScreen(spec: _selectedSpec!))),
                ),
                const SizedBox(height: 20),
              ],

              // Odometer
              _label('Current Odometer'),
              TextFormField(
                controller: _odoController,
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _deco('e.g. 12000', suffix: 'km',
                    helper: _existingVehicle != null ? 'Current: ${_existingVehicle!.odo.toStringAsFixed(0)} km' : null),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final p = double.tryParse(v);
                  if (p == null) return 'Must be a number';
                  if (p <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Purchase date
              _label('Purchase Date'),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_purchaseDate == null ? 'Select date' : _purchaseDate!.toLocal().toString().split(' ')[0],
                        style: TextStyle(color: _purchaseDate == null ? Colors.white38 : Colors.white, fontSize: 15)),
                    const Icon(Icons.calendar_today_rounded, color: Colors.white38, size: 18),
                  ]),
                ),
              ),
              const SizedBox(height: 40),

              // Save button
              GestureDetector(
                onTap: _isLoading ? null : _save,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: _isLoading ? null : const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    color: _isLoading ? Colors.white12 : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _isLoading ? [] : [BoxShadow(color: Colors.deepPurpleAccent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Center(child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_existingVehicle != null ? 'Update Vehicle' : 'Save Vehicle',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String? value;
  final String placeholder;
  final List<String> options;
  final ValueChanged<String> onSelected;
  const _PickerTile({required this.value, required this.placeholder, required this.options, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: const Color(0xFF1A1A24),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: options.map((o) => ListTile(
              title: Text(o, style: GoogleFonts.inter(color: Colors.white)),
              trailing: value == o ? const Icon(Icons.check_rounded, color: Colors.deepPurpleAccent) : null,
              onTap: () => Navigator.pop(context, o),
            )).toList(),
          ),
        );
        if (picked != null) onSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value != null ? Colors.deepPurpleAccent.withValues(alpha: 0.4) : Colors.transparent),
        ),
        child: Row(children: [
          Expanded(child: Text(value ?? placeholder, style: TextStyle(color: value != null ? Colors.white : Colors.white38, fontSize: 15))),
          const Icon(Icons.expand_more_rounded, color: Colors.white38, size: 20),
        ]),
      ),
    );
  }
}

class _ModelPicker extends StatelessWidget {
  final String make;
  final VehicleSpec? selected;
  final ValueChanged<VehicleSpec> onSelected;
  const _ModelPicker({required this.make, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final models = VehicleSpecDatabase.modelsFor(make);
    return Column(
      children: models.map((spec) => GestureDetector(
        onTap: () => onSelected(spec),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected?.modelId == spec.modelId ? Colors.deepPurpleAccent.withValues(alpha: 0.15) : const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected?.modelId == spec.modelId ? Colors.deepPurpleAccent : Colors.transparent, width: 1.5),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(spec.modelName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 2),
              Text('${spec.engineCc}cc · ${spec.engineType.split(',').first}',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
            ])),
            if (selected?.modelId == spec.modelId)
              const Icon(Icons.check_circle_rounded, color: Colors.deepPurpleAccent, size: 20),
          ]),
        ),
      )).toList(),
    );
  }
}

class _SpecPreviewCard extends StatelessWidget {
  final VehicleSpec spec;
  final VoidCallback onViewFull;
  const _SpecPreviewCard({required this.spec, required this.onViewFull});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.verified_rounded, color: Colors.deepPurpleAccent, size: 16),
          const SizedBox(width: 6),
          Text('Spec loaded: ${spec.make} ${spec.modelName}',
              style: GoogleFonts.outfit(color: Colors.deepPurpleAccent, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        _row('Oil', '${spec.oil.volumeLiters}L ${spec.oil.type}'),
        _row('Oil interval', '${spec.oilChangeIntervalKm} km'),
        _row('Spark plug', '${spec.sparkPlug.partNumber} · gap ${spec.sparkPlug.gap}'),
        _row('Tire pressure', 'F: ${spec.tires.frontPressurePsi} psi · R: ${spec.tires.rearPressurePsi} psi'),
        if (spec.coolant != null) _row('Coolant', '${spec.coolant!.volumeLiters}L ${spec.coolant!.type.split('(').first.trim()}'),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onViewFull,
          child: Text('View full spec sheet →', style: GoogleFonts.inter(color: Colors.deepPurpleAccent, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12))),
      Expanded(child: Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 12))),
    ]),
  );
}
