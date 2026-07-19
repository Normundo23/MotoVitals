import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/alert_engine.dart';

class AlertsScreen extends StatelessWidget {
  final VoidCallback? onGoToMarketplace;
  const AlertsScreen({super.key, this.onGoToMarketplace});

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleProvider>(
      builder: (context, provider, _) {
        final vehicle = provider.currentVehicle;

        return Scaffold(
          backgroundColor: const Color(0xFF12121A),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Predictive Alerts',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          body: () {
            if (provider.isLoading) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: Colors.deepPurpleAccent));
            }
            if (vehicle == null) {
              return _buildEmptyState(
                  'No vehicle found',
                  'Add a vehicle from the Profile tab to get predictive alerts.',
                  Icons.two_wheeler_rounded);
            }
            if (vehicle.parts.isEmpty) {
              return _buildEmptyState(
                  'No parts tracked',
                  'Add maintenance parts to your vehicle to receive alerts.',
                  Icons.build_rounded);
            }

            final alerts = AlertEngine.generate(
              parts: vehicle.parts,
              currentOdo: vehicle.odo,
            );

            final criticals =
                alerts.where((a) => a.severity == AlertSeverity.critical).toList();
            final warnings =
                alerts.where((a) => a.severity == AlertSeverity.warning).toList();
            final goods =
                alerts.where((a) => a.severity == AlertSeverity.good).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ── Vehicle chip ────────────────────────────────────────────
                _VehicleChip(
                    make: vehicle.make,
                    model: vehicle.modelName,
                    odo: vehicle.odo),
                const SizedBox(height: 20),

                // ── Summary banner ──────────────────────────────────────────
                _SummaryBanner(
                  criticalCount: criticals.length,
                  warningCount: warnings.length,
                ),
                const SizedBox(height: 24),

                // ── Critical ────────────────────────────────────────────────
                if (criticals.isNotEmpty) ...[
                  const _SectionHeader(
                      label: 'Action Required',
                      color: Colors.redAccent,
                      icon: Icons.error_rounded),
                  const SizedBox(height: 10),
                  ...criticals.map((a) => _AlertCard(
                        alert: a,
                        onGoToMarketplace: onGoToMarketplace,
                      )),
                  const SizedBox(height: 20),
                ],

                // ── Warning ─────────────────────────────────────────────────
                if (warnings.isNotEmpty) ...[
                  const _SectionHeader(
                      label: 'Coming Up',
                      color: Colors.orangeAccent,
                      icon: Icons.warning_rounded),
                  const SizedBox(height: 10),
                  ...warnings.map((a) => _AlertCard(
                        alert: a,
                        onGoToMarketplace: onGoToMarketplace,
                      )),
                  const SizedBox(height: 20),
                ],

                // ── Good ────────────────────────────────────────────────────
                if (goods.isNotEmpty) ...[
                  const _SectionHeader(
                      label: 'All Good',
                      color: Colors.greenAccent,
                      icon: Icons.check_circle_rounded),
                  const SizedBox(height: 10),
                  ...goods.map((a) => _AlertCard(alert: a)),
                ],
              ],
            );
          }(),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 24),
            Text(title,
                style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Vehicle Chip ──────────────────────────────────────────────────────────────

class _VehicleChip extends StatelessWidget {
  final String make, model;
  final double odo;
  const _VehicleChip(
      {required this.make, required this.model, required this.odo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          const Icon(Icons.two_wheeler_rounded,
              color: Colors.deepPurpleAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$make $model — ${odo.toStringAsFixed(0)} km',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Banner ────────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final int criticalCount, warningCount;
  const _SummaryBanner(
      {required this.criticalCount, required this.warningCount});

  @override
  Widget build(BuildContext context) {
    final allClear = criticalCount == 0 && warningCount == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: allClear
              ? [const Color(0xFF1B4332), const Color(0xFF2D6A4F)]
              : criticalCount > 0
                  ? [const Color(0xFF4A0000), const Color(0xFF7B1111)]
                  : [const Color(0xFF4A2C00), const Color(0xFF7B4F11)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            allClear
                ? Icons.shield_rounded
                : criticalCount > 0
                    ? Icons.error_rounded
                    : Icons.warning_rounded,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allClear
                      ? 'Your bike is in great shape!'
                      : criticalCount > 0
                          ? '$criticalCount item${criticalCount > 1 ? 's' : ''} need immediate attention'
                          : '$warningCount item${warningCount > 1 ? 's' : ''} coming up soon',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  allClear
                      ? 'All maintenance parts are within healthy ranges.'
                      : 'Check the alerts below for actionable recommendations.',
                  style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _SectionHeader(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.outfit(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
      ],
    );
  }
}

// ── Alert Card ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final MaintenanceAlert alert;
  final VoidCallback? onGoToMarketplace;
  const _AlertCard({required this.alert, this.onGoToMarketplace});

  Color get _severityColor {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return Colors.redAccent;
      case AlertSeverity.warning:
        return Colors.orangeAccent;
      case AlertSeverity.good:
        return Colors.greenAccent;
    }
  }

  IconData get _severityIcon {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return Icons.error_rounded;
      case AlertSeverity.warning:
        return Icons.warning_amber_rounded;
      case AlertSeverity.good:
        return Icons.check_circle_rounded;
    }
  }

  bool get _showBuyButton =>
      alert.severity == AlertSeverity.critical &&
      alert.partName.toLowerCase().contains('brake');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert.severity == AlertSeverity.good
              ? Colors.white.withValues(alpha: 0.05)
              : _severityColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_severityIcon, color: _severityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.headline,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    const SizedBox(height: 4),
                    // Health bar
                    LinearProgressIndicator(
                      value: alert.remainingPercent.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_severityColor),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(alert.remainingPercent * 100).toStringAsFixed(0)}% remaining',
                      style: GoogleFonts.inter(
                          color: _severityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Suggestion
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(alert.suggestion,
                      style: GoogleFonts.inter(
                          color: Colors.white60, fontSize: 13, height: 1.5)),
                ),
              ],
            ),
          ),

          // Buy button for critical brake pads
          if (_showBuyButton && onGoToMarketplace != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onGoToMarketplace,
                icon: const Icon(Icons.shopping_cart_checkout_rounded,
                    color: Colors.white, size: 16),
                label: Text('Shop RCB Brake Pads',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
