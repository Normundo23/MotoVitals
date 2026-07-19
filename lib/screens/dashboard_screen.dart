import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/maintenance_part.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/health_ring.dart';
import 'fuel/fuel_tracker_screen.dart';
import 'garage/garage_selector_widget.dart';

class DashboardScreen extends StatelessWidget {
  /// Callback to switch to the Marketplace tab (index 1) in MainLayout.
  final VoidCallback? onGoToMarketplace;

  const DashboardScreen({super.key, this.onGoToMarketplace});

  // ── Odometer Update Bottom Sheet ────────────────────────────────────────────
  void _showOdometerUpdateSheet(BuildContext context, double currentOdo) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Update Odometer',
                    style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current: ${currentOdo.toStringAsFixed(0)} km',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'New Odometer Reading',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixText: 'km',
                      suffixStyle: const TextStyle(color: Colors.white54),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      final parsed = double.tryParse(val);
                      if (parsed == null) return 'Must be a number';
                      if (parsed < currentOdo) {
                        return 'Cannot be less than ${currentOdo.toStringAsFixed(0)} km';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => isSaving = true);
                            try {
                              final newOdo = double.parse(controller.text.trim());
                              await context.read<VehicleProvider>().updateOdometer(newOdo);
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              setSheetState(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Save Reading', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Log Service Confirmation Dialog ─────────────────────────────────────────
  void _showLogServiceDialog(BuildContext context, MaintenancePart part, double currentOdo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Service', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Mark "${part.name}" as serviced at ${currentOdo.toStringAsFixed(0)} km?\n\nThis will reset its health to 100%.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<VehicleProvider>().logService(part.name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${part.name} serviced at ${currentOdo.toStringAsFixed(0)} km ✓', style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Confirm', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, child) {
        final vehicle = vehicleProvider.currentVehicle;

        return Scaffold(
          backgroundColor: const Color(0xFF12121A),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const GarageSelectorWidget(),
          ),
          floatingActionButton: vehicle != null
              ? FloatingActionButton.extended(
                  onPressed: () => _showOdometerUpdateSheet(context, vehicle.odo),
                  backgroundColor: Colors.deepPurpleAccent,
                  icon: const Icon(Icons.speed_rounded, color: Colors.white),
                  label: Text('Update Odo', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                )
              : null,
          body: Builder(builder: (context) {
            if (vehicleProvider.isLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent));
            }
            if (vehicleProvider.error != null) {
              return Center(child: Text('Error: ${vehicleProvider.error}', style: const TextStyle(color: Colors.redAccent)));
            }
            if (vehicle == null) return _buildEmptyGarageState();

            final currentOdo = vehicle.odo;
            final primaryPart = vehicle.parts.isNotEmpty ? vehicle.parts.first : null;
            final secondaryParts = vehicle.parts.length > 1 ? vehicle.parts.sublist(1) : <MaintenancePart>[];

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      '${vehicle.make} ${vehicle.modelName}'.trim(),
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showOdometerUpdateSheet(context, currentOdo),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Odometer: ${currentOdo.toStringAsFixed(0)} km', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit, size: 14, color: Colors.deepPurpleAccent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Spec badge
                    Builder(builder: (ctx) {
                      if (vehicle.specModelId == null) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.verified_rounded, size: 13, color: Colors.deepPurpleAccent),
                          const SizedBox(width: 5),
                          Text('Spec-matched intervals',
                              style: GoogleFonts.inter(color: Colors.deepPurpleAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                        ]),
                      );
                    }),

                    const SizedBox(height: 44),

                    if (primaryPart != null) ...[
                      Center(
                        child: HealthRing(
                          currentOdo: currentOdo,
                          lastOilChangeOdo: primaryPart.lastServiceOdo,
                          serviceInterval: primaryPart.interval,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showLogServiceDialog(context, primaryPart, currentOdo),
                            icon: const Icon(Icons.build_circle_outlined, color: Colors.deepPurpleAccent, size: 18),
                            label: Text('Log Oil Change', style: GoogleFonts.inter(color: Colors.deepPurpleAccent, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.deepPurpleAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FuelTrackerScreen())),
                            icon: const Icon(Icons.local_gas_station_rounded, color: Colors.white, size: 18),
                            label: Text('Fuel', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurpleAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 40),

                    if (secondaryParts.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Maintenance Schedule', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(height: 16),
                      ...secondaryParts.map((part) => _buildMaintenanceTracker(context, part, currentOdo)),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // ── Maintenance Card ─────────────────────────────────────────────────────────
  Widget _buildMaintenanceTracker(BuildContext context, MaintenancePart part, double currentOdo) {
    final healthPercentage = part.getRemainingLifePercentage(currentOdo);
    final healthColor = healthPercentage > 0.5
        ? Colors.greenAccent
        : (healthPercentage > 0.2 ? Colors.orangeAccent : Colors.redAccent);
    final showBuyButton = part.name.toLowerCase().contains('brake') && healthPercentage <= 0.20;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(part.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              Text('${(healthPercentage * 100).toStringAsFixed(0)}% Health', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: healthColor)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: healthPercentage,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(healthColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showLogServiceDialog(context, part, currentOdo),
                  icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white54),
                  label: Text('Log Service', style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (showBuyButton) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onGoToMarketplace,
                    icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 16),
                    label: Text('Buy RCB Pads', style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────────
  Widget _buildEmptyGarageState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.two_wheeler, size: 80, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 24),
            Text('Your garage is empty', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Go to the Profile tab to add your first vehicle.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
