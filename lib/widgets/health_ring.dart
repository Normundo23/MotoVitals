import 'dart:math';
import 'package:flutter/material.dart';

class HealthRing extends StatelessWidget {
  final double currentOdo;
  final double lastOilChangeOdo;
  final double serviceInterval;

  const HealthRing({
    super.key,
    required this.currentOdo,
    required this.lastOilChangeOdo,
    this.serviceInterval = 1500.0, // Honda Winner X default oil interval
  });

  @override
  Widget build(BuildContext context) {
    final double distanceDriven = max(0, currentOdo - lastOilChangeOdo);
    // remainingHealth: 1.0 = fresh, 0.0 = overdue
    final double remainingHealth = (1.0 - (distanceDriven / serviceInterval)).clamp(0.0, 1.0);
    final double remainingKm = max(0, serviceInterval - distanceDriven);

    // Color: green = healthy, orange = warning, red = critical
    Color progressColor;
    String statusLabel;
    if (remainingHealth > 0.5) {
      progressColor = Colors.greenAccent;
      statusLabel = 'Good';
    } else if (remainingHealth > 0.2) {
      progressColor = Colors.orangeAccent;
      statusLabel = 'Change Soon';
    } else {
      progressColor = Colors.redAccent;
      statusLabel = remainingHealth <= 0 ? 'Overdue!' : 'Critical';
    }

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(10, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(-10, -10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: RingPainter(
          progress: remainingHealth,
          progressColor: progressColor,
          backgroundColor: Colors.white10,
        ),
        child: SizedBox(
          width: 200,
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(remainingHealth * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Oil Health',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: progressColor,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${remainingKm.toStringAsFixed(0)} km left',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  RingPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 16.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background Ring (full circle)
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress Ring (remaining health arc)
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,           // start at top
      2 * pi * progress, // arc = remaining health
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
