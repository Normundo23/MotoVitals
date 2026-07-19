import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/vehicle_spec.dart';

class SpecSheetScreen extends StatelessWidget {
  final VehicleSpec spec;
  const SpecSheetScreen({super.key, required this.spec});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${spec.make} ${spec.modelName}',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E2C), Color(0xFF252538)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.two_wheeler_rounded,
                        color: Colors.deepPurpleAccent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${spec.make} ${spec.modelName}',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text(
                            '${spec.engineCc}cc · ${spec.engineType}',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: spec.isCoolant
                        ? Colors.cyanAccent.withValues(alpha: 0.1)
                        : Colors.orangeAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    spec.isCoolant ? 'Liquid-cooled' : 'Air-cooled',
                    style: GoogleFonts.inter(
                      color: spec.isCoolant
                          ? Colors.cyanAccent
                          : Colors.orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Oil ───────────────────────────────────────────────────────────
          _Section(
            icon: Icons.opacity_rounded,
            iconColor: Colors.amberAccent,
            title: 'Engine Oil',
            rows: [
              _SpecRow('Type', spec.oil.type),
              _SpecRow('Volume', '${spec.oil.volumeLiters} L'),
              _SpecRow('Grade', spec.oil.grade),
              _SpecRow('Change every', '${spec.oilChangeIntervalKm} km'),
              _SpecRow('Recommended', spec.oil.recommended),
            ],
          ),

          // ── Spark Plug ────────────────────────────────────────────────────
          _Section(
            icon: Icons.flash_on_rounded,
            iconColor: Colors.yellowAccent,
            title: 'Spark Plug',
            rows: [
              _SpecRow('Part number', spec.sparkPlug.partNumber),
              if (spec.sparkPlug.alternative != null)
                _SpecRow('Alternative', spec.sparkPlug.alternative!),
              _SpecRow('Electrode gap', spec.sparkPlug.gap),
              _SpecRow('Replace every', '${spec.sparkPlug.intervalKm} km'),
            ],
          ),

          // ── Chain ─────────────────────────────────────────────────────────
          _Section(
            icon: Icons.link_rounded,
            iconColor: Colors.blueAccent,
            title: 'Drive Chain',
            rows: [
              _SpecRow('Size', spec.chain.size),
              _SpecRow('Links', '${spec.chain.links}'),
              _SpecRow('Max slack', '${spec.chain.slackMm} mm'),
              _SpecRow('Lube every', '${spec.chain.lubeIntervalKm} km'),
              _SpecRow('Replace every', '${spec.chain.replaceIntervalKm} km'),
            ],
          ),

          // ── Brakes ────────────────────────────────────────────────────────
          _Section(
            icon: Icons.brightness_1_rounded,
            iconColor: Colors.redAccent,
            title: 'Brakes',
            rows: [
              _SpecRow('Front', spec.brakes.frontType),
              _SpecRow('Rear', spec.brakes.rearType),
              _SpecRow('Front min. thickness', '${spec.brakes.frontThicknessMm} mm'),
              _SpecRow('Rear min. thickness', '${spec.brakes.rearThicknessMm} mm'),
              _SpecRow('Inspect every', '${spec.brakes.inspectIntervalKm} km'),
            ],
          ),

          // ── Tires ─────────────────────────────────────────────────────────
          _Section(
            icon: Icons.tire_repair_rounded,
            iconColor: Colors.greenAccent,
            title: 'Tires',
            rows: [
              _SpecRow('Type', spec.tires.type),
              _SpecRow('Front size', spec.tires.frontSize),
              _SpecRow('Rear size', spec.tires.rearSize),
              _SpecRow('Front pressure', '${spec.tires.frontPressurePsi} psi'),
              _SpecRow('Rear pressure (solo)', '${spec.tires.rearPressurePsi} psi'),
              _SpecRow('Rear pressure (loaded)', '${spec.tires.rearPressurePsiLoaded} psi'),
            ],
          ),

          // ── Coolant (if applicable) ───────────────────────────────────────
          if (spec.coolant != null)
            _Section(
              icon: Icons.water_drop_rounded,
              iconColor: Colors.cyanAccent,
              title: 'Coolant',
              rows: [
                _SpecRow('Type', spec.coolant!.type),
                _SpecRow('Volume', '${spec.coolant!.volumeLiters} L'),
                _SpecRow('Color', spec.coolant!.color),
                _SpecRow('Flush every', '${spec.coolant!.flushIntervalKm} km'),
              ],
            ),

          // ── Air Filter ────────────────────────────────────────────────────
          _Section(
            icon: Icons.air_rounded,
            iconColor: Colors.deepPurpleAccent,
            title: 'Air Filter',
            rows: [
              _SpecRow('Type', spec.airFilter.filterType),
              _SpecRow('Clean every', '${spec.airFilter.cleanIntervalKm} km'),
              _SpecRow('Replace every', '${spec.airFilter.replaceIntervalKm} km'),
            ],
          ),

          // ── Maintenance schedule summary ──────────────────────────────────
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Maintenance Schedule',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...spec.maintenanceIntervals.map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        Container(
                          width: 48,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${i.intervalKm ~/ 1000}k',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: Colors.deepPurpleAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(i.name,
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text(i.detail,
                                  style: GoogleFonts.inter(
                                      color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ]),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All specs are based on the manufacturer\'s official owner\'s manual. '
            'Actual intervals may vary based on riding conditions and usage patterns.',
            style: GoogleFonts.inter(
                color: Colors.white24, fontSize: 11, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<_SpecRow> rows;

  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

// ── Spec row ──────────────────────────────────────────────────────────────────

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  const _SpecRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
