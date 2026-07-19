import '../models/maintenance_part.dart';
import '../models/vehicle_spec.dart';
import '../data/vehicle_spec_database.dart';

enum AlertSeverity { critical, warning, good }

class MaintenanceAlert {
  final String partName;
  final double remainingKm;
  final double remainingPercent;
  final AlertSeverity severity;
  final String headline;
  final String suggestion;
  final String? specDetail; // e.g. "0.8L 10W-40 JASO MA2" for oil

  const MaintenanceAlert({
    required this.partName,
    required this.remainingKm,
    required this.remainingPercent,
    required this.severity,
    required this.headline,
    required this.suggestion,
    this.specDetail,
  });
}

class AlertEngine {
  static const double _criticalThreshold = 0.15;
  static const double _warningThreshold  = 0.40;

  // ── Spec-aware suggestion builder ────────────────────────────────────────────

  static String _suggestion(
    String partName,
    AlertSeverity severity,
    VehicleSpec? spec,
  ) {
    final name = partName.toLowerCase();
    final level = severity == AlertSeverity.critical ? 'critical'
        : severity == AlertSeverity.warning ? 'warning' : 'good';

    // Oil — include exact volume + grade from spec if available
    if (name.contains('engine oil') || name.contains('oil')) {
      final oilDetail = spec != null
          ? '${spec.oil.volumeLiters}L of ${spec.oil.type} (${spec.oil.grade}). Recommended: ${spec.oil.recommended}.'
          : 'the correct grade and volume for your model.';
      return switch (level) {
        'critical' => 'Change oil now. Use $oilDetail Stop-and-go Manila traffic degrades oil faster than highway riding.',
        'warning'  => 'Plan an oil change soon. You\'ll need $oilDetail',
        _          => 'Oil is in good shape. Re-check after long rides or rainy seasons.',
      };
    }

    // Spark plug — include part number from spec
    if (name.contains('spark plug')) {
      final plugDetail = spec != null
          ? 'Replace with ${spec.sparkPlug.partNumber} (gap: ${spec.sparkPlug.gap})${spec.sparkPlug.alternative != null ? ' or ${spec.sparkPlug.alternative}' : ''}.'
          : 'Check manufacturer-spec part number for your model.';
      return switch (level) {
        'critical' => 'Replace spark plug now. $plugDetail A worn plug causes misfires and poor fuel economy.',
        'warning'  => 'Spark plug replacement coming up. $plugDetail',
        _          => 'Spark plug is healthy. Inspect for fouling after extended idling.',
      };
    }

    // Chain — include slack spec
    if (name.contains('chain')) {
      final chainDetail = spec != null
          ? 'Chain size: ${spec.chain.size}, max slack: ${spec.chain.slackMm}mm.'
          : 'Check chain slack per your owner\'s manual.';
      return switch (level) {
        'critical' => 'Lube or adjust chain immediately. $chainDetail A dry or overly slack chain at speed is extremely dangerous.',
        'warning'  => 'Chain lube due soon. $chainDetail Dusty roads and rain accelerate wear.',
        _          => 'Chain is well-lubricated. Re-lube after every rainy ride.',
      };
    }

    // Brake — include pad spec
    if (name.contains('brake')) {
      final brakeDetail = spec != null
          ? 'Front: ${spec.brakes.frontType}. Minimum thickness: ${spec.brakes.frontThicknessMm}mm.'
          : 'Check pad thickness against manufacturer minimum.';
      return switch (level) {
        'critical' => 'Inspect or replace brake pads now. $brakeDetail Worn pads are critical on wet roads and downhill stretches.',
        'warning'  => 'Brake inspection due. $brakeDetail Plan a check before your next long ride.',
        _          => 'Brakes are in good condition. Check for glazing after heavy braking.',
      };
    }

    // Coolant — include volume + type
    if (name.contains('coolant')) {
      final coolantDetail = spec?.coolant != null
          ? '${spec!.coolant!.volumeLiters}L of ${spec.coolant!.type} (${spec.coolant!.color}).'
          : 'Check coolant level and colour.';
      return switch (level) {
        'critical' => 'Flush and replace coolant now. Use $coolantDetail Old coolant loses anti-corrosion properties and risks overheating.',
        'warning'  => 'Coolant flush coming up. You\'ll need $coolantDetail',
        _          => 'Coolant is fresh. Check reservoir level monthly.',
      };
    }

    // Air filter
    if (name.contains('air filter')) {
      final filterDetail = spec != null
          ? '${spec.airFilter.filterType}. Clean every ${spec.airFilter.cleanIntervalKm}km, replace every ${spec.airFilter.replaceIntervalKm}km.'
          : 'Clean or replace as per manufacturer interval.';
      return switch (level) {
        'critical' => 'Service air filter now. $filterDetail A clogged filter hurts power and fuel economy.',
        'warning'  => 'Air filter service coming up. $filterDetail Dusty roads accelerate clogging.',
        _          => 'Air filter is clean. Inspect more frequently on unpaved roads.',
      };
    }

    // Generic fallback
    return switch (level) {
      'critical' => 'Service "$partName" immediately to prevent failure.',
      'warning'  => 'Schedule "$partName" service soon.',
      _          => '"$partName" is within healthy range.',
    };
  }

  static String _specDetail(String partName, VehicleSpec? spec) {
    if (spec == null) return '';
    final name = partName.toLowerCase();
    if (name.contains('oil')) return '${spec.oil.volumeLiters}L · ${spec.oil.type} · ${spec.oil.grade}';
    if (name.contains('spark plug')) return '${spec.sparkPlug.partNumber} · gap ${spec.sparkPlug.gap}';
    if (name.contains('chain')) return 'Size ${spec.chain.size} · slack ≤${spec.chain.slackMm}mm';
    if (name.contains('brake')) return 'F: ${spec.brakes.frontThicknessMm}mm min · R: ${spec.brakes.rearThicknessMm}mm min';
    if (name.contains('coolant') && spec.coolant != null) return '${spec.coolant!.volumeLiters}L · ${spec.coolant!.color}';
    if (name.contains('air filter')) return spec.airFilter.filterType;
    return '';
  }

  static String _headline(String partName, double remainingKm, AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.critical => remainingKm <= 0
          ? '$partName — Overdue!'
          : '$partName — ${remainingKm.toStringAsFixed(0)} km left',
      AlertSeverity.warning => '$partName — ${remainingKm.toStringAsFixed(0)} km remaining',
      AlertSeverity.good    => '$partName — ${remainingKm.toStringAsFixed(0)} km remaining',
    };
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Generates sorted alerts. Accepts optional specModelId to enrich suggestions.
  static List<MaintenanceAlert> generate({
    required List<MaintenancePart> parts,
    required double currentOdo,
    String? specModelId,
  }) {
    final spec = specModelId != null
        ? VehicleSpecDatabase.findById(specModelId)
        : null;

    final alerts = parts.map((part) {
      final remaining = part.getRemainingLifePercentage(currentOdo);
      final remainingKm = (part.interval - (currentOdo - part.lastServiceOdo))
          .clamp(0.0, double.infinity);

      final severity = remaining <= _criticalThreshold
          ? AlertSeverity.critical
          : remaining <= _warningThreshold
              ? AlertSeverity.warning
              : AlertSeverity.good;

      return MaintenanceAlert(
        partName: part.name,
        remainingKm: remainingKm,
        remainingPercent: remaining,
        severity: severity,
        headline: _headline(part.name, remainingKm, severity),
        suggestion: _suggestion(part.name, severity, spec),
        specDetail: _specDetail(part.name, spec),
      );
    }).toList();

    // Sort: critical → warning → good
    alerts.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return alerts;
  }

  static bool hasActiveAlerts(List<MaintenancePart> parts, double currentOdo) =>
      parts.any((p) => p.getRemainingLifePercentage(currentOdo) <= _warningThreshold);
}
