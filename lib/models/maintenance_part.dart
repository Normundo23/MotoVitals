class MaintenancePart {
  final String name;
  final double interval;
  final double lastServiceOdo;

  MaintenancePart({
    required this.name,
    required this.interval,
    required this.lastServiceOdo,
  });

  factory MaintenancePart.fromJson(Map<String, dynamic> json) {
    return MaintenancePart(
      name: json['name'] as String? ?? 'Unknown Part',
      interval: (json['interval'] as num?)?.toDouble() ?? 1000.0,
      lastServiceOdo: (json['lastServiceOdo'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'interval': interval,
      'lastServiceOdo': lastServiceOdo,
    };
  }

  double getRemainingLifePercentage(double currentOdo) {
    double distanceDriven = currentOdo - lastServiceOdo;
    if (distanceDriven < 0) distanceDriven = 0; // Guard against negative distance
    double remaining = interval - distanceDriven;
    if (remaining < 0) remaining = 0;
    return remaining / interval;
  }
}
