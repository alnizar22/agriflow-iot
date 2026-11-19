import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/irrigation_provider.dart';
import '../services/mqtt_service.dart';
import '../widgets/developer_profile_dialog.dart';
import '../widgets/moisture_gauge.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Soft slate background (Mockup 1)
      appBar: _buildAppBar(context),
      body: Consumer<IrrigationProvider>(
        builder: (context, provider, child) {
          final data = provider.currentData;

          return RefreshIndicator(
            onRefresh: () async {
              if (!provider.isSimulationActive) {
                await provider.connectMqtt();
              }
            },
            color: const Color(0xFF047857),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner Mode Simulasi jika aktif
                  if (provider.isSimulationActive)
                    _buildSimulationBanner(context, provider),

                  // Card 1: Irigasi Bawang Merah Status Card (Mockup 1)
                  _buildMainStatusCard(context, provider),

                  // Prompt Nyalakan Prototype jika data belum masuk dan bukan mode simulasi
                  if (!provider.hasData && !provider.isSimulationActive)
                    _buildPrototypeOfflinePrompt(context, provider),

                  const SizedBox(height: 16),

                  // Card 2: Moisture Gauge Card (Mockup 1)
                  MoistureGauge(
                    soilMoisture: data.soilMoisture,
                    status: data.moistureStatus,
                    hasData: provider.hasData,
                  ),

                  const SizedBox(height: 16),

                  // Card 3: Grid 3 Mini Status Cards (Mockup 1)
                  Row(
                    children: [
                      // Mini Card 1: Suhu Udara
                      Expanded(
                        child: _buildMiniStatusCard(
                          icon: Icons.thermostat_rounded,
                          iconColor: const Color(0xFF0288D1),
                          title: 'Suhu Udara',
                          value: provider.hasData ? '${data.temperature.toInt()}°C' : '--',
                          subtitle: provider.hasData ? 'Normal' : 'Menunggu Alat',
                          valueColor: provider.hasData ? null : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Mini Card 2: Kelembapan Udara
                      Expanded(
                        child: _buildMiniStatusCard(
                          icon: Icons.water_drop_outlined,
                          iconColor: const Color(0xFF0288D1),
                          title: 'Kelembapan..',
                          value: provider.hasData ? '${data.humidity.toInt()}%' : '--',
                          subtitle: provider.hasData ? 'Cukup' : 'Menunggu Alat',
                          valueColor: provider.hasData ? null : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Mini Card 3: Status Pompa
                      Expanded(
                        child: _buildMiniStatusCard(
                          icon: Icons.power_settings_new_rounded,
                          iconColor: const Color(0xFF0288D1),
                          title: 'Status Pompa',
                          value: provider.hasData ? (data.isPumpOn ? 'ON' : 'OFF') : '--',
                          subtitle: provider.hasData
                              ? (data.pumpStatusText ?? (data.isPumpOn ? 'Menyala' : 'Siaga'))
                              : 'Menunggu Alat',
                          valueColor: provider.hasData
                              ? (data.isPumpOn ? const Color(0xFF047857) : const Color(0xFF475569))
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Card 4: Pembaruan Telemetri Bar (Mockup 1)
                  _buildTelemetrySyncBar(provider),

                  const SizedBox(height: 16),

                  // Footer Quick Simulation Toggle Button
                  _buildSimulationToggleCard(provider),

                  const SizedBox(height: 20),
                ],
              ),
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
                'Beranda',
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

  Widget _buildMainStatusCard(BuildContext context, IrrigationProvider provider) {
    final isConnected = provider.connectionState == MqttConnectionState.connected;
    final isConnecting = provider.connectionState == MqttConnectionState.connecting;
    final isOnline = provider.isSimulationActive || isConnected;

    String statusText;
    Color statusColor;

    if (provider.isSimulationActive) {
      statusText = 'Status: Mode Simulasi Aktif';
      statusColor = Colors.orange;
    } else if (isConnected) {
      statusText = 'Status: Online (HiveMQ Cloud)';
      statusColor = const Color(0xFF047857);
    } else if (isConnecting) {
      statusText = 'Status: Menghubungkan ke Broker...';
      statusColor = Colors.amber.shade700;
    } else {
      statusText = 'Status: Offline (Tap to Reconnect)';
      statusColor = Colors.redAccent;
    }

    return InkWell(
      onTap: () async {
        if (!isOnline && !isConnecting) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menghubungkan ke HiveMQ Cloud Serverless...'),
              duration: Duration(seconds: 1),
            ),
          );
          final ok = await provider.connectMqtt();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ok
                    ? 'Berhasil terhubung ke HiveMQ Cloud Serverless!'
                    : 'Gagal terhubung: Pastikan internet aktif atau cek konfigurasi broker.'),
                backgroundColor: ok ? const Color(0xFF047857) : Colors.redAccent,
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Irigasi Bawang Merah',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isConnected
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFEFF6FF), // Soft light blue pill (Mockup 1)
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConnected ? Icons.cloud_done_rounded : Icons.sensors_rounded,
                color: isConnected ? const Color(0xFF047857) : const Color(0xFF0288D1),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatusCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrototypeOfflinePrompt(BuildContext context, IrrigationProvider provider) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Warm amber background
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFDE68A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.power_settings_new_rounded,
              color: Color(0xFFB45309),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prototype Belum Dinyalakan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Aplikasi terhubung ke broker. Silakan nyalakan alat prototype ESP32 untuk menerima data telemetri.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFB45309),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetrySyncBar(IrrigationProvider provider) {
    final hasData = provider.hasData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasData ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasData ? Icons.sync_rounded : Icons.sensors_off_rounded,
              color: hasData ? const Color(0xFF0288D1) : const Color(0xFF64748B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasData ? 'Pembaruan Telemetri' : 'Status Telemetri Prototype',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasData
                      ? 'Sinkronisasi otomatis setiap 30 detik'
                      : 'Menunggu sinyal data pertama dari ESP32...',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Text(
            hasData ? 'Baru saja' : 'Belum Aktif',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: hasData ? const Color(0xFF047857) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationBanner(BuildContext context, IrrigationProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_rounded, color: Colors.purple, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Mode Simulasi Real-Time Aktif (Pengujian Bab 4)',
              style: TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.bold),
            ),
          ),
          InkWell(
            onTap: () => provider.stopSimulation(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'STOP',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationToggleCard(IrrigationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Pengujian Mode Simulasi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text(
                'Uji alur streaming data tanpa ESP32',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => provider.toggleSimulation(),
            icon: Icon(provider.isSimulationActive ? Icons.stop : Icons.play_arrow, size: 16),
            label: Text(provider.isSimulationActive ? 'Stop' : 'Simulasi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.isSimulationActive ? Colors.purple : const Color(0xFF047857),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
