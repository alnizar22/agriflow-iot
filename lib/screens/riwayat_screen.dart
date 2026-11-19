import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/irrigation_provider.dart';
import '../widgets/developer_profile_dialog.dart';
import '../widgets/trend_chart.dart';

class RiwayatScreen extends StatelessWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: Consumer<IrrigationProvider>(
        builder: (context, provider, child) {
          final history = provider.history;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title
                const Text(
                  'Riwayat & Tren Telemetri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pemantauan fluktuasi kelembapan tanah lahan bawang secara real-time',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),

                const SizedBox(height: 16),

                // Real-Time Trend Line Chart
                TrendChart(
                  history: history,
                  minThreshold: provider.minThreshold,
                  maxThreshold: provider.maxThreshold,
                ),

                const SizedBox(height: 20),

                // Ringkasan Log Telemetri Terakhir
                const Text(
                  'Catatan Telemetri Terakhir',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                if (history.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8), size: 24),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada data riwayat tersimpan',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Nyalakan prototype ESP32 untuk mulai mencatat telemetri',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length > 10 ? 10 : history.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      // Order newest first
                      final item = history[history.length - 1 - index];
                      final timeStr =
                          DateFormat('HH:mm:ss').format(item.timestamp);
                      final isDry = item.soilMoisture < provider.minThreshold;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isDry
                                            ? Colors.red
                                            : const Color(0xFF047857))
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isDry
                                        ? Icons.warning_amber_rounded
                                        : Icons.grass_rounded,
                                    color: isDry
                                        ? Colors.red
                                        : const Color(0xFF047857),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kelembapan: ${item.soilMoisture.toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Suhu: ${item.temperature}°C | Udara: ${item.humidity}%',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.isPumpOn ? 'Pompa ON' : 'Pompa OFF',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: item.isPumpOn
                                        ? const Color(0xFF047857)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF047857).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/agriflow_logo.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.eco_rounded,
                  color: Color(0xFF047857),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'IRIGASI IOT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF047857),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Riwayat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Informasi Pengembang',
          icon: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF047857), // Deep Green Accent
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33047857),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () {
            DeveloperProfileDialog.show(context);
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
