import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/haptic_service.dart';

class ConfirmationDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
    Color? iconColor,
    bool isDestructive = false,
  }) async {
    await HapticService.warning();

    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? Colors.white, size: 24),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticService.lightImpact();
              Navigator.pop(context, false);
            },
            child: Text(
              cancelText,
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticService.mediumImpact();
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive
                  ? Colors.redAccent
                  : Colors.deepPurpleAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              confirmText,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showDelete({
    required BuildContext context,
    required String itemName,
  }) {
    return show(
      context: context,
      title: 'Delete $itemName?',
      message: 'This action cannot be undone.',
      confirmText: 'Delete',
      icon: Icons.delete_outline_rounded,
      iconColor: Colors.redAccent,
      isDestructive: true,
    );
  }

  static Future<bool?> showLogout(BuildContext context) {
    return show(
      context: context,
      title: 'Log Out?',
      message: 'You will need to sign in again to access your data.',
      confirmText: 'Log Out',
      icon: Icons.logout_rounded,
      iconColor: Colors.orangeAccent,
    );
  }

  static Future<bool?> showDiscardChanges(BuildContext context) {
    return show(
      context: context,
      title: 'Discard Changes?',
      message: 'Any unsaved changes will be lost.',
      confirmText: 'Discard',
      icon: Icons.warning_rounded,
      iconColor: Colors.orangeAccent,
    );
  }
}
