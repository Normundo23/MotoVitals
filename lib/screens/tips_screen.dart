import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/vehicle_spec_database.dart';
import '../models/vehicle_spec.dart';

class TipsScreen extends StatelessWidget {
  final String? specModelId;

  const TipsScreen({super.key, this.specModelId});

  @override
  Widget build(BuildContext context) {
    final spec = specModelId != null
        ? VehicleSpecDatabase.findById(specModelId!)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Maintenance Tips',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (spec != null) ...[
            _buildSpecHeader(spec),
            const SizedBox(height: 24),
          ],
          _buildGeneralTips(),
          const SizedBox(height: 24),
          _buildSeasonalTips(),
        ],
      ),
    );
  }

  Widget _buildSpecHeader(VehicleSpec spec) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurpleAccent.withValues(alpha: 0.2),
            Colors.deepPurpleAccent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: Colors.deepPurpleAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tips for ${spec.make} ${spec.modelName}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSpecTipRow('Engine', '${spec.engineCc}cc · ${spec.engineType}'),
          _buildSpecTipRow('Oil', '${spec.oil.volumeLiters}L ${spec.oil.type}'),
          _buildSpecTipRow(
              'Oil Interval', '${spec.oilChangeIntervalKm} km'),
        ],
      ),
    );
  }

  Widget _buildSpecTipRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'General Maintenance',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTipCard(
          icon: Icons.opacity_rounded,
          title: 'Oil Changes',
          color: Colors.amberAccent,
          tips: [
            'Check oil level before every ride',
            'Change oil every 1,500-3,000 km depending on type',
            'Use manufacturer-recommended oil grade',
            'Warm up engine before draining oil',
          ],
        ),
        const SizedBox(height: 12),
        _buildTipCard(
          icon: Icons.link_rounded,
          title: 'Chain Maintenance',
          color: Colors.blueAccent,
          tips: [
            'Clean and lubricate chain every 500 km',
            'Check chain slack regularly (10-20mm)',
            'Adjust tension when chain is warm',
            'Replace chain if it has stretched beyond limits',
          ],
        ),
        const SizedBox(height: 12),
        _buildTipCard(
          icon: Icons.brightness_1_rounded,
          title: 'Brake System',
          color: Colors.redAccent,
          tips: [
            'Check brake pad thickness monthly',
            'Replace pads before they wear to metal',
            'Bleed brakes if lever feels spongy',
            'Check brake fluid level and color',
          ],
        ),
        const SizedBox(height: 12),
        _buildTipCard(
          icon: Icons.air_rounded,
          title: 'Air Filter',
          color: Colors.greenAccent,
          tips: [
            'Clean air filter every 4,000 km',
            'Replace every 12,000-16,000 km',
            'Use compressed air to clean (don\'t wash with oil)',
            'Check more frequently in dusty conditions',
          ],
        ),
      ],
    );
  }

  Widget _buildSeasonalTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seasonal Tips',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTipCard(
          icon: Icons.water_drop_rounded,
          title: 'Rainy Season',
          color: Colors.cyanAccent,
          tips: [
            'Check tire tread depth for wet grip',
            'Ensure brakes are responsive in wet conditions',
            'Apply chain lube after every rainy ride',
            'Check electrical connections for corrosion',
            'Use waterproof covers when parked',
          ],
        ),
        const SizedBox(height: 12),
        _buildTipCard(
          icon: Icons.wb_sunny_rounded,
          title: 'Summer / Hot Weather',
          color: Colors.orangeAccent,
          tips: [
            'Check coolant level and quality',
            'Monitor engine temperature',
            'Ensure proper tire pressure (heat increases pressure)',
            'Check battery fluid level',
            'Park in shade when possible',
          ],
        ),
      ],
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<String> tips,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: Colors.white54, fontSize: 14)),
                    Expanded(
                      child: Text(
                        tip,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
