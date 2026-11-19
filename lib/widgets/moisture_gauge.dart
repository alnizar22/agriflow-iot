import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/sensor_data.dart';

class MoistureGauge extends StatelessWidget {
  final double soilMoisture;
  final MoistureStatus status;
  final bool hasData;

  const MoistureGauge({
    super.key,
    required this.soilMoisture,
    required this.status,
    this.hasData = true,
  });

  Color _getStatusColor() {
    if (!hasData) return const Color(0xFF94A3B8);
    switch (status) {
      case MoistureStatus.dry:
        return const Color(0xFFDC2626); // Merah Kering (< 60%)
      case MoistureStatus.optimal:
        return const Color(0xFF047857); // Deep Green Optimal (60-80%)
      case MoistureStatus.wet:
        return const Color(0xFF0288D1); // Biru Basah (> 80%)
    }
  }

  String _getStatusText() {
    if (!hasData) return 'MENUNGGU ALAT';
    switch (status) {
      case MoistureStatus.dry:
        return 'KERING';
      case MoistureStatus.optimal:
        return 'OPTIMAL';
      case MoistureStatus.wet:
        return 'BASAH';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final clampedMoisture = hasData ? soilMoisture.clamp(0.0, 100.0) : 0.0;
    final percentVal = hasData ? clampedMoisture / 100.0 : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular Progress Gauge (Mockup 1)
          CircularPercentIndicator(
            radius: 110.0,
            lineWidth: 18.0,
            animation: true,
            animateFromLastPercent: true,
            animationDuration: 800,
            percent: percentVal,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      hasData ? soilMoisture.toInt().toString() : '--',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        color: hasData ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Kelembapan Tanah',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Status Pill Badge (Mockup 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: const Color(0xFFEFF6FF),
            progressColor: statusColor,
          ),

          const SizedBox(height: 24),

          // Bottom Verification Banner (Mockup 1)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Soft slate background
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasData ? Icons.check_circle_outline_rounded : Icons.sensors_rounded,
                    color: hasData ? const Color(0xFF047857) : const Color(0xFF0288D1),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Rentang Ideal Bawang (60% - 75%)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Text(
                  hasData ? 'Terverifikasi' : 'Nyalakan Prototype',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasData ? const Color(0xFF64748B) : const Color(0xFF0288D1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
