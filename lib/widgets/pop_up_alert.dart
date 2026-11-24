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

  /// Dialog Peringatan Gangguan Sinyal / Koneksi Terputus (Revisi Pasca-Semhas)
  static Future<void> showSignalDisruptionDialog({
    required BuildContext context,
    required String message,
    required VoidCallback onReconnect,
    VoidCallback? onDismiss,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 16,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7), // Warm amber tint
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.wifi_off_rounded,
                      color: Color(0xFFD97706), // Amber
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Gangguan Sinyal / Koneksi Terputus',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF475569),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      onReconnect();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                    label: const Text(
                      'Coba Hubungkan Ulang',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      if (onDismiss != null) onDismiss();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
