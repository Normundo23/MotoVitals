/// Full manufacturer-spec maintenance data for a specific motorcycle model.
/// Stored locally in VehicleSpecDatabase — no Firestore reads needed.
class OilSpec {
  final String type;        // e.g. "10W-40 Semi-Synthetic"
  final double volumeLiters; // e.g. 0.8
  final String grade;       // e.g. "JASO MA2"
  final String recommended; // e.g. "Motul 5100, Shell Advance AX7"

  const OilSpec({
    required this.type,
    required this.volumeLiters,
    required this.grade,
    required this.recommended,
  });
}

class SparkPlugSpec {
  final String partNumber;      // e.g. "NGK CPR8EA-9"
  final String gap;             // e.g. "0.9mm"
  final int intervalKm;         // e.g. 8000
  final String? alternative;    // e.g. "Denso U24EPR9"

  const SparkPlugSpec({
    required this.partNumber,
    required this.gap,
    required this.intervalKm,
    this.alternative,
  });
}

class ChainSpec {
  final String size;            // e.g. "428"
  final int links;              // e.g. 130
  final double slackMm;         // e.g. 20.0 (allowable slack in mm)
  final int lubeIntervalKm;     // e.g. 500
  final int replaceIntervalKm;  // e.g. 20000

  const ChainSpec({
    required this.size,
    required this.links,
    required this.slackMm,
    required this.lubeIntervalKm,
    required this.replaceIntervalKm,
  });
}

class BrakeSpec {
  final String frontType;       // e.g. "Disc — RCB FA347"
  final String rearType;        // e.g. "Disc — RCB FA154"
  final double frontThicknessMm; // minimum pad thickness
  final double rearThicknessMm;
  final int inspectIntervalKm;  // e.g. 4000

  const BrakeSpec({
    required this.frontType,
    required this.rearType,
    required this.frontThicknessMm,
    required this.rearThicknessMm,
    required this.inspectIntervalKm,
  });
}

class TireSpec {
  final String frontSize;       // e.g. "70/90-17"
  final String rearSize;        // e.g. "80/90-17"
  final int frontPressurePsi;   // e.g. 29
  final int rearPressurePsi;    // e.g. 33
  final int rearPressurePsiLoaded; // e.g. 36 (with pillion)
  final String type;            // e.g. "Tubeless"

  const TireSpec({
    required this.frontSize,
    required this.rearSize,
    required this.frontPressurePsi,
    required this.rearPressurePsi,
    required this.rearPressurePsiLoaded,
    required this.type,
  });
}

class CoolantSpec {
  final String type;            // e.g. "Ethylene Glycol-based"
  final double volumeLiters;    // e.g. 1.05
  final String color;           // e.g. "Green"
  final int flushIntervalKm;    // e.g. 24000

  const CoolantSpec({
    required this.type,
    required this.volumeLiters,
    required this.color,
    required this.flushIntervalKm,
  });
}

class AirFilterSpec {
  final String filterType;      // e.g. "Paper element"
  final int cleanIntervalKm;    // e.g. 4000
  final int replaceIntervalKm;  // e.g. 12000

  const AirFilterSpec({
    required this.filterType,
    required this.cleanIntervalKm,
    required this.replaceIntervalKm,
  });
}

/// Top-level spec for a specific model.
class VehicleSpec {
  final String modelId;         // unique key e.g. "honda_winner_x"
  final String make;            // e.g. "Honda"
  final String modelName;       // e.g. "Winner X"
  final int engineCc;           // e.g. 150
  final String engineType;      // e.g. "4-stroke, DOHC, Liquid-cooled"
  final bool isCoolant;         // true = liquid cooled

  final OilSpec oil;
  final int oilChangeIntervalKm;

  final SparkPlugSpec sparkPlug;
  final ChainSpec chain;
  final BrakeSpec brakes;
  final TireSpec tires;
  final CoolantSpec? coolant;   // null for air-cooled
  final AirFilterSpec airFilter;

  /// Derived: returns a list of MaintenancePart-compatible intervals
  /// used to initialise the vehicle's parts on first save.
  List<SpecInterval> get maintenanceIntervals => [
    SpecInterval(name: 'Engine Oil', intervalKm: oilChangeIntervalKm,
        detail: '${oil.volumeLiters}L ${oil.type}'),
    SpecInterval(name: 'Spark Plug', intervalKm: sparkPlug.intervalKm,
        detail: sparkPlug.partNumber),
    SpecInterval(name: 'Air Filter (Clean)', intervalKm: airFilter.cleanIntervalKm,
        detail: airFilter.filterType),
    SpecInterval(name: 'Air Filter (Replace)', intervalKm: airFilter.replaceIntervalKm,
        detail: airFilter.filterType),
    SpecInterval(name: 'Chain Lubrication', intervalKm: chain.lubeIntervalKm,
        detail: 'Size ${chain.size}, slack ≤${chain.slackMm}mm'),
    SpecInterval(name: 'Brake Inspection', intervalKm: brakes.inspectIntervalKm,
        detail: 'Front ${brakes.frontThicknessMm}mm min'),
    if (coolant != null)
      SpecInterval(name: 'Coolant Flush', intervalKm: coolant!.flushIntervalKm,
          detail: '${coolant!.volumeLiters}L ${coolant!.type}'),
  ];

  const VehicleSpec({
    required this.modelId,
    required this.make,
    required this.modelName,
    required this.engineCc,
    required this.engineType,
    required this.isCoolant,
    required this.oil,
    required this.oilChangeIntervalKm,
    required this.sparkPlug,
    required this.chain,
    required this.brakes,
    required this.tires,
    this.coolant,
    required this.airFilter,
  });
}

/// Lightweight interval descriptor used to seed MaintenancePart list.
class SpecInterval {
  final String name;
  final int intervalKm;
  final String detail;
  const SpecInterval({
    required this.name,
    required this.intervalKm,
    required this.detail,
  });
}
