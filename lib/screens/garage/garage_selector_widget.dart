import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/vehicle_provider.dart';

class GarageSelectorWidget extends StatelessWidget {
  const GarageSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent),
          );
        }

        final vehicles = provider.vehicles;
        if (vehicles.isEmpty) return const SizedBox.shrink();

        final current = provider.currentVehicle;
        if (current == null) return const SizedBox.shrink();

        return PopupMenuButton<String>(
          color: const Color(0xFF252538),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (id) => provider.selectVehicle(id),
          itemBuilder: (context) {
            return vehicles.map((v) {
              return PopupMenuItem<String>(
                value: v.id,
                child: Text(
                  v.modelName.isNotEmpty ? v.modelName : v.make,
                  style: GoogleFonts.inter(
                    color: v.id == current.id ? Colors.deepPurpleAccent : Colors.white,
                    fontWeight: v.id == current.id ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.two_wheeler_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                current.modelName.isNotEmpty ? current.modelName : current.make,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Icon(Icons.arrow_drop_down_rounded, color: Colors.white54),
            ],
          ),
        );
      },
    );
  }
}
