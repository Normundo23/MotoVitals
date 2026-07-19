import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/fuel_log.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/database_service.dart';
import 'package:intl/intl.dart';

class FuelTrackerScreen extends StatefulWidget {
  const FuelTrackerScreen({super.key});

  @override
  State<FuelTrackerScreen> createState() => _FuelTrackerScreenState();
}

class _FuelTrackerScreenState extends State<FuelTrackerScreen> {
  final _db = DatabaseService();

  // ── Calculation Logic ────────────────────────────────────────────────────────
  double _calculateAverageKml(List<FuelLog> logs) {
    if (logs.length < 2) return 0.0;
    
    // Sort oldest to newest
    final sorted = List<FuelLog>.from(logs)..sort((a, b) => a.date.compareTo(b.date));
    
    FuelLog? firstFull;
    FuelLog? lastFull;
    
    for (var log in sorted) {
      if (log.isFullTank) {
        firstFull ??= log;
        lastFull = log;
      }
    }

    if (firstFull == null || lastFull == null || firstFull.id == lastFull.id) return 0.0;

    double totalDistance = lastFull.odo - firstFull.odo;
    if (totalDistance <= 0) return 0.0;

    double totalLiters = 0.0;
    bool counting = false;
    for (var log in sorted) {
      if (log.id == firstFull.id) {
        counting = true;
        continue; // Don't count the liters of the *first* full tank for distance calculation
      }
      if (counting) {
        totalLiters += log.liters;
      }
      if (log.id == lastFull.id) break;
    }

    if (totalLiters <= 0) return 0.0;
    return totalDistance / totalLiters;
  }

  double _calculateTotalSpent(List<FuelLog> logs) {
    return logs.fold(0.0, (sum, log) => sum + log.price);
  }

  // ── Add Fuel Log Sheet ───────────────────────────────────────────────────────
  void _showAddFuelSheet(BuildContext context, String vehicleId, double currentOdo) {
    final odoCtrl = TextEditingController(text: currentOdo.toStringAsFixed(0));
    final litersCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    bool isFullTank = true;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text('Log Fuel Fill-up', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(child: _buildTextField(odoCtrl, 'Odometer (km)', isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(litersCtrl, 'Liters', isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(priceCtrl, 'Total Cost (₱)', isNumber: true),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: Text('Full Tank?', style: GoogleFonts.inter(color: Colors.white)),
                    subtitle: Text('Required for accurate Km/L calculations.', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                    value: isFullTank,
                    activeColor: Colors.deepPurpleAccent,
                    onChanged: (v) => setSheetState(() => isFullTank = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (!formKey.currentState!.validate()) return;
                      setSheetState(() => isSaving = true);
                      try {
                        final log = FuelLog(
                          id: '',
                          vehicleId: vehicleId,
                          liters: double.parse(litersCtrl.text),
                          price: double.parse(priceCtrl.text),
                          odo: double.parse(odoCtrl.text),
                          isFullTank: isFullTank,
                          date: DateTime.now(),
                        );
                        await _db.addFuelLog(log);
                        
                        // Update vehicle odo if new odo is higher
                        final newOdo = double.parse(odoCtrl.text);
                        if (newOdo > currentOdo && context.mounted) {
                           await context.read<VehicleProvider>().updateOdometer(newOdo);
                        }

                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setSheetState(() => isSaving = false);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Save Log', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (isNumber && double.tryParse(v) == null) return 'Invalid number';
        return null;
      },
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleProvider>().currentVehicle;

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Fuel Economy', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      floatingActionButton: vehicle != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddFuelSheet(context, vehicle.id, vehicle.odo),
              backgroundColor: Colors.deepPurpleAccent,
              icon: const Icon(Icons.local_gas_station_rounded, color: Colors.white),
              label: Text('Log Fuel', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
      body: vehicle == null
          ? Center(child: Text('Please select a vehicle in the Dashboard.', style: GoogleFonts.inter(color: Colors.white54)))
          : StreamBuilder<List<FuelLog>>(
              stream: _db.fuelLogStream(vehicle.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent));
                }
                
                final logs = snapshot.data ?? [];
                final avgKml = _calculateAverageKml(logs);
                final totalSpent = _calculateTotalSpent(logs);

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildStatCard('Avg Economy', avgKml > 0 ? '${avgKml.toStringAsFixed(1)} Km/L' : '--', Icons.speed_rounded)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildStatCard('Total Spent', '₱${totalSpent.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded)),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Fill-up History', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    if (logs.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                              const SizedBox(height: 16),
                              Text('No fuel logs yet', style: GoogleFonts.inter(color: Colors.white54)),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final log = logs[index];
                              return _buildLogCard(log);
                            },
                            childCount: logs.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurpleAccent, size: 28),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLogCard(FuelLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(log.isFullTank ? Icons.battery_charging_full_rounded : Icons.battery_4_bar_rounded, 
                color: log.isFullTank ? Colors.greenAccent : Colors.orangeAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${log.liters.toStringAsFixed(1)} L', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${log.odo.toStringAsFixed(0)} km', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₱${log.price.toStringAsFixed(2)}', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 15, fontWeight: FontWeight.w600)),
              Text(DateFormat('MMM d, y').format(log.date), style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
