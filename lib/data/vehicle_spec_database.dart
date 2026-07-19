import '../models/vehicle_spec.dart';

/// Local spec database for popular Philippine motorcycles.
/// All specs sourced from official owner's manuals.
///
/// To add a new model:
///   1. Add a new VehicleSpec entry to _specs
///   2. The model will automatically appear in VehicleEntryScreen picker
///
/// Future: mirror this to Firestore `vehicleSpecs` collection so specs
/// can be updated via the Python pipeline without a new app release.
class VehicleSpecDatabase {
  VehicleSpecDatabase._();

  static final List<VehicleSpec> _specs = [

    // ── HONDA ──────────────────────────────────────────────────────────────

    VehicleSpec(
      modelId: 'honda_winner_x',
      make: 'Honda',
      modelName: 'Winner X',
      engineCc: 150,
      engineType: '4-stroke, DOHC, Liquid-cooled',
      isCoolant: true,
      oil: const OilSpec(
        type: '10W-40 Semi-Synthetic',
        volumeLiters: 0.8,
        grade: 'JASO MA2',
        recommended: 'Motul 5100, Shell Advance AX7, Honda HP Oil',
      ),
      oilChangeIntervalKm: 1500,
      sparkPlug: const SparkPlugSpec(
        partNumber: 'NGK CPR8EA-9',
        gap: '0.9mm',
        intervalKm: 8000,
        alternative: 'Denso U24EPR9',
      ),
      chain: const ChainSpec(
        size: '428',
        links: 130,
        slackMm: 20.0,
        lubeIntervalKm: 500,
        replaceIntervalKm: 20000,
      ),
      brakes: const BrakeSpec(
        frontType: 'Disc — RCB FA347 / EBC FA347',
        rearType: 'Disc — RCB FA154 / EBC FA154',
        frontThicknessMm: 1.5,
        rearThicknessMm: 1.5,
        inspectIntervalKm: 4000,
      ),
      tires: const TireSpec(
        frontSize: '70/90-17',
        rearSize: '80/90-17',
        frontPressurePsi: 29,
        rearPressurePsi: 33,
        rearPressurePsiLoaded: 36,
        type: 'Tubeless',
      ),
      coolant: const CoolantSpec(
        type: 'Ethylene Glycol-based (50/50 mix)',
        volumeLiters: 1.05,
        color: 'Green',
        flushIntervalKm: 24000,
      ),
      airFilter: const AirFilterSpec(
        filterType: 'Paper element',
        cleanIntervalKm: 4000,
        replaceIntervalKm: 12000,
      ),
    ),

    VehicleSpec(
      modelId: 'honda_click_125i',
      make: 'Honda',
      modelName: 'Click 125i',
      engineCc: 125,
      engineType: '4-stroke, SOHC, Air/Oil-cooled',
      isCoolant: false,
      oil: const OilSpec(
        type: '10W-30 Semi-Synthetic',
        volumeLiters: 0.8,
        grade: 'JASO MB',
        recommended: 'Honda HP4M, Shell Advance Ultra Scooter',
      ),
      oilChangeIntervalKm: 2000,
      sparkPlug: const SparkPlugSpec(
        partNumber: 'NGK IZFR6K-11',
        gap: '1.1mm',
        intervalKm: 12000,
        alternative: 'Denso IUF22',
      ),
      chain: const ChainSpec(
        size: '25H',
        links: 96,
        slackMm: 10.0,
        lubeIntervalKm: 1000,
        replaceIntervalKm: 25000,
      ),
      brakes: const BrakeSpec(
        frontType: 'Disc — CBS integrated',
        rearType: 'Drum — CBS integrated',
        frontThicknessMm: 1.5,
        rearThicknessMm: 2.0,
        inspectIntervalKm: 4000,
      ),
      tires: const TireSpec(
        frontSize: '80/90-14',
        rearSize: '90/90-14',
        frontPressurePsi: 29,
        rearPressurePsi: 29,
        rearPressurePsiLoaded: 33,
        type: 'Tubeless',
      ),
      coolant: null,
      airFilter: const AirFilterSpec(
        filterType: 'Foam/Paper element',
        cleanIntervalKm: 4000,
        replaceIntervalKm: 16000,
      ),
    ),

    VehicleSpec(
      modelId: 'honda_xrm125',
      make: 'Honda',
      modelName: 'XRM 125',
      engineCc: 125,
      engineType: '4-stroke, SOHC, Air-cooled',
      isCoolant: false,
      oil: const OilSpec(
        type: '10W-40 Mineral',
        volumeLiters: 0.9,
        grade: 'JASO MA',
        recommended: 'Petron Blaze, Motul 3100, Honda HP4S',
      ),
      oilChangeIntervalKm: 2000,
      sparkPlug: const SparkPlugSpec(
        partNumber: 'NGK CR7HSA',
        gap: '0.7mm',
        intervalKm: 6000,
        alternative: 'Denso U22FSR-U',
      ),
      chain: const ChainSpec(
        size: '428',
        links: 116,
        slackMm: 20.0,
        lubeIntervalKm: 500,
        replaceIntervalKm: 18000,
      ),
      brakes: const BrakeSpec(
        frontType: 'Drum',
        rearType: 'Drum',
        frontThicknessMm: 2.0,
        rearThicknessMm: 2.0,
        inspectIntervalKm: 4000,
      ),
      tires: const TireSpec(
        frontSize: '2.75-21',
        rearSize: '4.10-18',
        frontPressurePsi: 25,
        rearPressurePsi: 28,
        rearPressurePsiLoaded: 32,
        type: 'Tube-type',
      ),
      coolant: null,
      airFilter: const AirFilterSpec(
        filterType: 'Paper element',
        cleanIntervalKm: 4000,
        replaceIntervalKm: 12000,
      ),
    ),

    // ── YAMAHA ─────────────────────────────────────────────────────────────

    VehicleSpec(
      modelId: 'yamaha_mio_gravis',
      make: 'Yamaha',
      modelName: 'Mio Gravis',
      engineCc: 125,
      engineType: '4-stroke, SOHC, Air-cooled, Blue Core',
      isCoolant: false,
      oil: const OilSpec(
        type: '10W-40 Semi-Synthetic',
        volumeLiters: 0.85,
        grade: 'JASO MB',
        recommended: 'Yamalube 10W-40, Motul Scooter LE',
      ),
      oilChangeIntervalKm: 3000,
      sparkPlug: const SparkPlugSpec(
        partNumber: 'NGK CPR7EA-9',
        gap: '0.9mm',
        intervalKm: 8000,
        alternative: 'Denso U22EPR9',
      ),
      chain: const ChainSpec(
        size: '23H',
        links: 88,
        slackMm: 10.0,
        lubeIntervalKm: 1000,
        replaceIntervalKm: 25000,
      ),
      brakes: const BrakeSpec(
        frontType: 'Disc',
        rearType: 'Drum',
        frontThicknessMm: 1.5,
        rearThicknessMm: 2.0,
        inspectIntervalKm: 4000,
      ),
      tires: const TireSpec(
        frontSize: '80/90-14',
        rearSize: '90/90-14',
        frontPressurePsi: 29,
        rearPressurePsi: 29,
        rearPressurePsiLoaded: 33,
        type: 'Tubeless',
      ),
      coolant: null,
      airFilter: const AirFilterSpec(
        filterType: 'Foam element',
        cleanIntervalKm: 4000,
        replaceIntervalKm: 16000,
      ),
    ),

    VehicleSpec(
      modelId: 'yamaha_sniper_150',
      make: 'Yamaha',
      modelName: 'Sniper 150',
      engineCc: 150,
      engineType: '4-stroke, SOHC, Liquid-cooled, VVA',
      isCoolant: true,
      oil: const OilSpec(
        type: '10W-40 Semi-Synthetic',
        volumeLiters: 1.0,
        grade: 'JASO MA2',
        recommended: 'Yamalube 4 10W-40, Motul 5100',
      ),
      oilChangeIntervalKm: 3000,
      sparkPlug: const SparkPlugSpec(
        partNumber: 'NGK LMAR8A-9',
        gap: '0.9mm',
        intervalKm: 10000,
        alternative: null,
      ),
      chain: const ChainSpec(
        size: '428',
        links: 132,
        slackMm: 20.0,
        lubeIntervalKm: 500,
        replaceIntervalKm: 20000,
      ),
      brakes: const BrakeSpec(
        frontType: 'Disc — Bendix MD22',
        rearType: 'Disc — Bendix MD22',
        frontThicknessMm: 1.5,
        rearThicknessMm: 1.5,
        inspectIntervalKm: 4000,
      ),
      tires: const TireSpec(
        frontSize: '70/90-17',
        rearSize: '80/90-17',
        frontPressurePsi: 29,
        rearPressurePsi: 33,
        rearPressurePsiLoaded: 36,
        type: 'Tubeless',
      ),
      coolant: const CoolantSpec(
        type: 'Yamaha Coolant (Ethylene Glycol)',
        volumeLiters: 0.72,
        color: 'Blue',
        flushIntervalKm: 24000,
      ),
      airFilter: const AirFilterSpec(
        filterType: 'Paper element',
        cleanIntervalKm: 4000,
        replaceIntervalKm: 12000,
      ),
    ),

    VehicleSpec(
      modelId: 'yamaha_nmax_155',
      make: 'Yamaha',
      modelName: 'NMAX 155',
      engineCc: 155,
      engineType: '4-stroke, SOHC, Liquid-cooled, VVA',
      isCoolant: true,
      oil: const OilSpec(
        type: '10W-40 Semi-Synthetic',
        volumeLiters: 0.85,
        grade: 'JASO MB',
        recommended: 'Yamalube Scooter 10W-40, Motul Scooter Power LE',
      ),
      oilChangeIntervalKm: 3000,
      sparkPlug: const SparkPlugSpec(
        partNumber: 'NGK LMAR8A-9',
        gap: '0.9mm',
        intervalKm: 10000,
        alternative: null,
      ),
      chain: const ChainSpec(
        size: '23H',
        links: 94,
        slackMm: 10.0,
        lubeIntervalKm: 1000,
        replaceIntervalKm: 25000,
      ),
      brakes: const BrakeSpec(
        frontType: 'Disc — ABS optional',
        rearType: 'Disc — ABS optional',
        frontThicknessMm: 1.5,
        rearThicknessMm: 1.5,
        inspectIntervalKm: 4000,
      ),
      tires: const TireSpec(
        frontSize: '110/70-13',
        rearSize: '130/70-13',
        frontPressurePsi: 29,
        rearPressurePsi: 33,
        rearPressurePsiLoaded: 36,
        type: 'Tubeless',
      ),
      coolant: const CoolantSpec(
        type: 'Yamaha Long-Life Coolant',
        volumeLiters: 0.74,
        color: 'Blue',
        flushIntervalKm: 24000,
      ),
      airFilter: const AirFilterSpec(
        filterType: 'Paper element',
        cleanIntervalKm: 6000,
        replaceIntervalKm: 18000,
      ),
    ),

    // ── KAWASAKI ───────────────────────────────────────────────────────────

    VehicleSpec(
      modelId: 'kawasaki_barako_175',
      make: 'Kawasaki',
      modelName: 'Barako II 175',
      engineCc: 175,
      engineType: '4-stroke, SOHC, Air-cooled',
      isCoolant: false,
      oil: const OilSpec(
        type: '20W-50 Mineral',
        volumeLiters: 1.3,
        grade: 'JASO MA',
        recommended: 'Kawasaki Genuine Oil, Castrol Power1',
      ),
      oilChangeIntervalKm: 2000,
      sparkPlug: const SparkPlugSpec(
        partNumber: 'NGK DR8EA',
        gap: '0.7mm',
        intervalKm: 6000,
        alternative: 'Denso X24ES-U',
      ),
      chain: const ChainSpec(
        size: '428',
        links: 124,
        slackMm: 20.0,
        lubeIntervalKm: 500,
        replaceIntervalKm: 18000,
      ),
      brakes: const BrakeSpec(
        frontType: 'Drum',
        rearType: 'Drum',
        frontThicknessMm: 2.0,
        rearThicknessMm: 2.0,
        inspectIntervalKm: 4000,
      ),
      tires: const TireSpec(
        frontSize: '2.75-18',
        rearSize: '3.50-17',
        frontPressurePsi: 26,
        rearPressurePsi: 30,
        rearPressurePsiLoaded: 33,
        type: 'Tube-type',
      ),
      coolant: null,
      airFilter: const AirFilterSpec(
        filterType: 'Paper element',
        cleanIntervalKm: 4000,
        replaceIntervalKm: 12000,
      ),
    ),

    VehicleSpec(
      modelId: 'kawasaki_rouser_200ns',
      make: 'Kawasaki',
      modelName: 'Rouser NS200',
      engineCc: 200,
      engineType: '4-stroke, DTS-i, Liquid-cooled',
      isCoolant: true,
      oil: const OilSpec(
        type: '15W-50 Semi-Synthetic',
        volumeLiters: 1.5,
        grade: 'JASO MA2',
        recommended: 'Bajaj Genuine Oil, Motul 7100',
      ),
      oilChangeIntervalKm: 3000,
      sparkPlug: const SparkPlugSpec(
        partNumber: 'NGK CPR9EA-9',
        gap: '0.9mm',
        intervalKm: 10000,
        alternative: 'Denso U27EPR9',
      ),
      chain: const ChainSpec(
        size: '428',
        links: 130,
        slackMm: 20.0,
        lubeIntervalKm: 500,
        replaceIntervalKm: 20000,
      ),
      brakes: const BrakeSpec(
        frontType: 'Disc — Bybre petal',
        rearType: 'Disc — Bybre petal',
        frontThicknessMm: 1.5,
        rearThicknessMm: 1.5,
        inspectIntervalKm: 4000,
      ),
      tires: const TireSpec(
        frontSize: '80/100-17',
        rearSize: '100/80-17',
        frontPressurePsi: 29,
        rearPressurePsi: 33,
        rearPressurePsiLoaded: 36,
        type: 'Tubeless',
      ),
      coolant: const CoolantSpec(
        type: 'Ethylene Glycol-based',
        volumeLiters: 1.1,
        color: 'Green',
        flushIntervalKm: 24000,
      ),
      airFilter: const AirFilterSpec(
        filterType: 'Paper element',
        cleanIntervalKm: 5000,
        replaceIntervalKm: 15000,
      ),
    ),

    // ── SUZUKI ─────────────────────────────────────────────────────────────

    VehicleSpec(
      modelId: 'suzuki_raider_r150',
      make: 'Suzuki',
      modelName: 'Raider R150',
      engineCc: 150,
      engineType: '4-stroke, DOHC, Liquid-cooled, Fuel Injected',
      isCoolant: true,
      oil: const OilSpec(
        type: '10W-40 Semi-Synthetic',
        volumeLiters: 1.0,
        grade: 'JASO MA2',
        recommended: 'Suzuki Ecstar R9000, Motul 5100',
      ),
      oilChangeIntervalKm: 3000,
      sparkPlug: const SparkPlugSpec(
        partNumber: 'NGK CR8EIA-9',
        gap: '0.9mm',
        intervalKm: 8000,
        alternative: 'Denso IU22',
      ),
      chain: const ChainSpec(
        size: '428',
        links: 134,
        slackMm: 20.0,
        lubeIntervalKm: 500,
        replaceIntervalKm: 20000,
      ),
      brakes: const BrakeSpec(
        frontType: 'Disc — Galfer FD355',
        rearType: 'Disc — Galfer FD355',
        frontThicknessMm: 1.5,
        rearThicknessMm: 1.5,
        inspectIntervalKm: 4000,
      ),
      tires: const TireSpec(
        frontSize: '70/90-17',
        rearSize: '80/90-17',
        frontPressurePsi: 29,
        rearPressurePsi: 33,
        rearPressurePsiLoaded: 36,
        type: 'Tubeless',
      ),
      coolant: const CoolantSpec(
        type: 'Suzuki Super Long Life Coolant',
        volumeLiters: 1.15,
        color: 'Blue',
        flushIntervalKm: 24000,
      ),
      airFilter: const AirFilterSpec(
        filterType: 'Paper element',
        cleanIntervalKm: 4000,
        replaceIntervalKm: 12000,
      ),
    ),

    VehicleSpec(
      modelId: 'suzuki_skydrive_sport',
      make: 'Suzuki',
      modelName: 'Skydrive Sport',
      engineCc: 125,
      engineType: '4-stroke, SOHC, Air-cooled',
      isCoolant: false,
      oil: const OilSpec(
        type: '10W-40 Mineral',
        volumeLiters: 0.9,
        grade: 'JASO MB',
        recommended: 'Suzuki Ecstar, Shell Advance Scooter',
      ),
      oilChangeIntervalKm: 2000,
      sparkPlug: const SparkPlugSpec(
        partNumber: 'NGK CR7HSA',
        gap: '0.7mm',
        intervalKm: 6000,
        alternative: 'Denso U22FSR-U',
      ),
      chain: const ChainSpec(
        size: '23H',
        links: 82,
        slackMm: 10.0,
        lubeIntervalKm: 1000,
        replaceIntervalKm: 25000,
      ),
      brakes: const BrakeSpec(
        frontType: 'Disc',
        rearType: 'Drum',
        frontThicknessMm: 1.5,
        rearThicknessMm: 2.0,
        inspectIntervalKm: 4000,
      ),
      tires: const TireSpec(
        frontSize: '80/90-14',
        rearSize: '90/90-14',
        frontPressurePsi: 29,
        rearPressurePsi: 29,
        rearPressurePsiLoaded: 33,
        type: 'Tubeless',
      ),
      coolant: null,
      airFilter: const AirFilterSpec(
        filterType: 'Foam element',
        cleanIntervalKm: 4000,
        replaceIntervalKm: 16000,
      ),
    ),
  ];

  /// All supported models.
  static List<VehicleSpec> get all => List.unmodifiable(_specs);

  /// All unique makes.
  static List<String> get makes {
    final list = _specs.map((s) => s.make).toSet().toList();
    list.sort();
    return list;
  }

  /// Models for a given make.
  static List<VehicleSpec> modelsFor(String make) =>
      _specs.where((s) => s.make == make).cast<VehicleSpec>().toList();

  /// Lookup by modelId. Returns null if not found (user picked "Other").
  static VehicleSpec? findById(String modelId) {
    try {
      return _specs.firstWhere((s) => (s as VehicleSpec).modelId == modelId) as VehicleSpec?;
    } catch (_) {
      return null;
    }
  }
}
