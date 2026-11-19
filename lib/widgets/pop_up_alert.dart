import 'package:flutter/material.dart';

class PopUpAlert extends StatelessWidget {
  final double currentMoisture;
  final VoidCallback onDismiss;
  final VoidCallback? onActivatePump;

  const PopUpAlert({
    super.key,
    required this.currentMoisture,
    required this.onDismiss,
    this.onActivatePump,
  });

  static Future<void> showCriticalMoistureDialog({
    required BuildContext context,
    required double moisture,
    required VoidCallback onDismiss,
    VoidCallback? onActivatePump,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopUpAlert(
          currentMoisture: moisture,
          onDismiss: () {
            Navigator.of(dialogContext).pop();
            onDismiss();
          },
          onActivatePump: onActivatePump != null
              ? () {
                  Navigator.of(dialogContext).pop();
                  onActivatePump();
                }
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon Container (Mockup 3)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2), // Soft red background
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626), // Red Warning Icon
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Red Title "PERINGATAN!"
            const Text(
              'PERINGATAN!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFFB91C1C),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle "Kelembapan Tanah Kritis (< 60%)"
            const Text(
              'Kelembapan Tanah Kritis (< 60%)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),

            // Button 1: "Siram Sekarang" (Dark Green Pill)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onActivatePump ?? onDismiss,
                icon: const Icon(Icons.water_drop_rounded, size: 20, color: Colors.white),
                label: const Text(
                  'Siram Sekarang',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857), // Deep Green Accent
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Button 2: "Tutup" (Soft Blue/Grey Fill)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF), // Soft Blue tint fill
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
