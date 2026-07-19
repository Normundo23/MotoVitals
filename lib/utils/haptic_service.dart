import 'package:vibration/vibration.dart';

class HapticService {
  static Future<void> lightImpact() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50, amplitude: 64);
    }
  }

  static Future<void> mediumImpact() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100, amplitude: 128);
    }
  }

  static Future<void> heavyImpact() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 150, amplitude: 255);
    }
  }

  static Future<void> success() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50, amplitude: 128);
      await Future.delayed(const Duration(milliseconds: 100));
      Vibration.vibrate(duration: 50, amplitude: 128);
    }
  }

  static Future<void> error() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100, amplitude: 255);
      await Future.delayed(const Duration(milliseconds: 100));
      Vibration.vibrate(duration: 100, amplitude: 255);
    }
  }

  static Future<void> warning() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50, amplitude: 128);
      await Future.delayed(const Duration(milliseconds: 50));
      Vibration.vibrate(duration: 50, amplitude: 128);
      await Future.delayed(const Duration(milliseconds: 50));
      Vibration.vibrate(duration: 50, amplitude: 128);
    }
  }

  static Future<void> selection() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 25, amplitude: 64);
    }
  }
}
