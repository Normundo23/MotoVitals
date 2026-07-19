import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart';
import '../models/service_log.dart';
import '../services/database_service.dart';
import 'garage/vehicle_entry_screen.dart';
import 'service_logbook_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool firebaseConfigured;
  const ProfileScreen({super.key, this.firebaseConfigured = false});

  Future<void> _logout() async {
    if (firebaseConfigured) await FirebaseAuth.instance.signOut();
  }

  // Estimated savings: each logged service = avg shop markup saved (₱200)
  double _calcSavings(List<ServiceLog> logs) => logs.length * 200.0;

  @override
  Widget build(BuildContext context) {
    final user = firebaseConfigured ? FirebaseAuth.instance.currentUser : null;
    final vehicle = context.watch<VehicleProvider>().currentVehicle;

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Avatar & name ──────────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          Colors.deepPurpleAccent.withValues(alpha: 0.35),
                          Colors.transparent,
                        ]),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor:
                            Colors.deepPurpleAccent.withValues(alpha: 0.15),
                        child: const Icon(Icons.person_rounded,
                            size: 46, color: Colors.deepPurpleAccent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user?.displayName ?? 'Moto Rider',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'Guest Mode',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.inter(fontSize: 13, color: Colors.white38),
              ),
              const SizedBox(height: 28),

              // ── Vehicle card ───────────────────────────────────────────────
              if (vehicle != null)
                _InfoCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.two_wheeler_rounded,
                            color: Colors.deepPurpleAccent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${vehicle.make} ${vehicle.modelName}',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            Text(
                              '${vehicle.odo.toStringAsFixed(0)} km on clock',
                              style: GoogleFonts.inter(
                                  color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.circle,
                          size: 10, color: Colors.greenAccent),
                    ],
                  ),
                ),
              if (vehicle != null) const SizedBox(height: 14),

              // ── Savings card (real data) ───────────────────────────────────
              vehicle != null
                  ? StreamBuilder<List<ServiceLog>>(
                      stream: DatabaseService()
                          .serviceLogStream(vehicle.id),
                      builder: (context, snap) {
                        final logs = snap.data ?? [];
                        final savings = _calcSavings(logs);
                        return _SavingsCard(
                            savings: savings, logCount: logs.length);
                      },
                    )
                  : const _SavingsCard(savings: 0, logCount: 0),
              const SizedBox(height: 24),

              // ── Menu items ─────────────────────────────────────────────────
              _MenuTile(
                icon: Icons.two_wheeler_rounded,
                label: 'Add / Edit Vehicle',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const VehicleEntryScreen())),
              ),
              _MenuTile(
                icon: Icons.history_rounded,
                label: 'Service Logbook',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ServiceLogbookScreen())),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),

              // ── Logout ─────────────────────────────────────────────────────
              _MenuTile(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                color: Colors.redAccent,
                onTap: _logout,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Savings Card ──────────────────────────────────────────────────────────────

class _SavingsCard extends StatelessWidget {
  final double savings;
  final int logCount;
  const _SavingsCard({required this.savings, required this.logCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF134E2A), Color(0xFF1B6B3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.greenAccent.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_rounded, color: Colors.greenAccent, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estimated Savings',
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '₱${savings.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '$logCount service${logCount == 1 ? '' : 's'} self-performed',
                  style: GoogleFonts.inter(
                      color: Colors.greenAccent.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

// ── Menu Tile ─────────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        color: c,
                        fontSize: 15,
                        fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right_rounded, color: c.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }
}
