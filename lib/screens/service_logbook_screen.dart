import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/service_log.dart';
import '../providers/vehicle_provider.dart';
import '../services/database_service.dart';

class ServiceLogbookScreen extends StatelessWidget {
  const ServiceLogbookScreen({super.key});

  // Icon per part type
  IconData _iconForPart(String partName) {
    final name = partName.toLowerCase();
    if (name.contains('oil')) return Icons.opacity_rounded;
    if (name.contains('brake')) return Icons.brightness_1_rounded;
    if (name.contains('chain')) return Icons.link_rounded;
    if (name.contains('coolant')) return Icons.water_drop_rounded;
    if (name.contains('tire') || name.contains('tyre')) return Icons.tire_repair_rounded;
    return Icons.build_rounded;
  }

  Color _colorForPart(String partName) {
    final name = partName.toLowerCase();
    if (name.contains('oil')) return Colors.amberAccent;
    if (name.contains('brake')) return Colors.redAccent;
    if (name.contains('chain')) return Colors.blueAccent;
    if (name.contains('coolant')) return Colors.cyanAccent;
    return Colors.deepPurpleAccent;
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleProvider>().currentVehicle;

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Service Logbook',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Tooltip(
              message: 'Verified maintenance history for resale transparency',
              child: Icon(Icons.verified_rounded,
                  color: Colors.greenAccent.shade400, size: 22),
            ),
          ),
        ],
      ),
      body: vehicle == null
          ? _buildEmptyState(hasVehicle: false)
          : StreamBuilder<List<ServiceLog>>(
              stream: DatabaseService().serviceLogStream(vehicle.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.deepPurpleAccent));
                }

                final logs = snapshot.data ?? [];

                if (logs.isEmpty) return _buildEmptyState(hasVehicle: true);

                return Column(
                  children: [
                    // Header summary banner
                    _buildSummaryBanner(vehicle.make, vehicle.modelName, logs),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final isFirst = index == 0;
                          return _buildLogEntry(log, isFirst);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSummaryBanner(
      String make, String modelName, List<ServiceLog> logs) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2C), Color(0xFF252538)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_rounded,
                color: Colors.greenAccent.shade400, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$make $modelName',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  '${logs.length} verified service${logs.length == 1 ? '' : 's'} on record',
                  style: GoogleFonts.inter(
                      color: Colors.greenAccent.shade400, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(ServiceLog log, bool isLatest) {
    final partColor = _colorForPart(log.partName);
    final partIcon = _iconForPart(log.partName);
    final dateStr =
        '${log.serviceDate.day}/${log.serviceDate.month}/${log.serviceDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest
              ? Colors.deepPurpleAccent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Part icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: partColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(partIcon, color: partColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        log.partName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isLatest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'LATEST',
                          style: GoogleFonts.inter(
                            color: Colors.deepPurpleAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.speed_rounded,
                        size: 13, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      '${log.odoAtService.toStringAsFixed(0)} km',
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.calendar_today_rounded,
                        size: 13, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.notes!,
                      style: GoogleFonts.inter(
                          color: Colors.white60, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool hasVehicle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 72, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 24),
            Text(
              hasVehicle ? 'No services logged yet' : 'No vehicle added',
              style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              hasVehicle
                  ? 'Tap "Log Service" on the Dashboard after your next oil change or maintenance.'
                  : 'Add a vehicle from the Profile tab to start your service history.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
