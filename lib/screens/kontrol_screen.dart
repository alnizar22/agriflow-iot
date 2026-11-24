import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/irrigation_provider.dart';
import '../services/mqtt_service.dart';
import '../widgets/developer_profile_dialog.dart';

class KontrolScreen extends StatelessWidget {
  const KontrolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Soft light background (Mockup 2)
      appBar: _buildAppBar(context),
      body: Consumer<IrrigationProvider>(
        builder: (context, provider, child) {
          final data = provider.currentData;
          final isPumpOn = data.isPumpOn;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner Gangguan Sinyal jika offline (Revisi Pasca-Semhas)
                if (!provider.isDeviceOnline && !provider.isSimulationActive)
                  _buildControlSignalBanner(context, provider),

                // Subheader Status Bar (Mockup 2)
                _buildSystemSubheader(provider),

                const SizedBox(height: 16),

                // Card 1: Mode Operasi Segmented Switch Card (Mockup 2)
                _buildModeOperasiCard(context, provider),

                const SizedBox(height: 24),

                // Card 2: Big Green Circular Pump Button (Mockup 2)
                _buildBigCircularPumpButton(context, provider, isPumpOn),

                const SizedBox(height: 16),

                // Status Relai Pill (Mockup 2)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // Soft light blue pill
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF0288D1)),
                        const SizedBox(width: 6),
                        Text(
                          'Status Relai: ${provider.hasData ? (data.pumpStatusText ?? (isPumpOn ? "Aktif / ON" : "Standby / Off")) : "Menunggu prototype..."}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: (provider.hasData && isPumpOn) ? const Color(0xFF047857) : const Color(0xFF0288D1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Card 3: Proteksi Pompa Aktif Info Box (Mockup 2)
                _buildPumpProtectionBox(),

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
                'Kontrol',
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

  Widget _buildControlSignalBanner(BuildContext context, IrrigationProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sinyal Terputus: Kontrol manual dinonaktifkan demi keamanan lahan.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSubheader(IrrigationProvider provider) {
    final hasData = provider.hasData;
    final isOnline = provider.isDeviceOnline;
    final isConnected = provider.connectionState == MqttConnectionState.connected;

    final statusTitle = isOnline
        ? 'SISTEM SIAGA'
        : (hasData ? 'SINYAL TERPUTUS' : 'MENUNGGU HARDWARE');
    final statusDesc = isOnline
        ? 'Hardware pompa terhubung via IoT Gateway'
        : (hasData
            ? 'Data telemetri terhenti (cek daya/sinyal ESP32)'
            : 'Silakan nyalakan daya prototype ESP32');
    final statusColor = isOnline
        ? const Color(0xFF047857)
        : (hasData ? Colors.redAccent : Colors.amber.shade700);
    final signalText = isOnline
        ? '98% Stabil'
        : (isConnected ? 'Broker Siap' : 'Offline');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  statusDesc,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                size: 14,
                color: isOnline ? const Color(0xFF0288D1) : Colors.redAccent,
              ),
              const SizedBox(width: 4),
              Text(
                signalText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isOnline ? const Color(0xFF0288D1) : Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeOperasiCard(BuildContext context, IrrigationProvider provider) {
    final isAutoMode = provider.isAutoMode;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Color(0xFF0288D1), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Mode Operasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAutoMode ? 'Aktif: Otomatis' : 'Aktif: Manual',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Segmented Switch [Otomatis | Manual] (Mockup 2)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => provider.toggleAutoMode(true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isAutoMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isAutoMode
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            size: 18,
                            color: isAutoMode ? const Color(0xFF047857) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Otomatis',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isAutoMode ? FontWeight.bold : FontWeight.w500,
                              color: isAutoMode ? const Color(0xFF047857) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => provider.toggleAutoMode(false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isAutoMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: !isAutoMode
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pan_tool_outlined,
                            size: 18,
                            color: !isAutoMode ? const Color(0xFF047857) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Manual',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: !isAutoMode ? FontWeight.bold : FontWeight.w500,
                              color: !isAutoMode ? const Color(0xFF047857) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isAutoMode
                ? 'Mode Otomatis menyalakan/mematikan pompa berdasarkan sensor kelembapan tanah (<60% ON, >80% OFF).'
                : 'Mode Manual memberikan kendali langsung atas saklar pompa air di lahan bawang merah.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBigCircularPumpButton(BuildContext context, IrrigationProvider provider, bool isPumpOn) {
    final isOnline = provider.isDeviceOnline;

    Color buttonColor;
    if (!isOnline) {
      buttonColor = const Color(0xFF94A3B8); // Abu-abu saat offline
    } else if (isPumpOn) {
      buttonColor = const Color(0xFFDC2626); // Merah saat menyiram
    } else {
      buttonColor = const Color(0xFF047857); // Deep Green siaga
    }

    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: () async {
              if (!isOnline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kontrol manual nonaktif saat sinyal terputus. Pastikan ESP32 online.'),
                    backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              // Check if moisture >= 80% (hanya jika data riil sensor telah masuk)
              if (provider.hasData && !isPumpOn && provider.currentData.soilMoisture >= provider.maxThreshold) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Proteksi Saturation: Kelembapan tanah > 80%, pompa ditolak.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              final turningOn = !isPumpOn;
              final ok = await provider.togglePumpState(turningOn);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      turningOn
                          ? (ok
                              ? "Perintah 'SIRAM' berhasil terpublish ke prototype!"
                              : "Gagal mengirim perintah: Broker sedang offline, mencoba menyambungkan...")
                          : (ok
                              ? "Perintah matikan pompa berhasil terpublish!"
                              : "Gagal mengirim perintah: Broker sedang offline."),
                    ),
                    backgroundColor: ok ? const Color(0xFF047857) : Colors.redAccent,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: buttonColor,
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      !isOnline
                          ? Icons.wifi_off_rounded
                          : (isPumpOn ? Icons.water_drop_rounded : Icons.power_settings_new_rounded),
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPumpOn ? 'Matikan Pompa Air' : 'Nyalakan Pompa Air',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    !isOnline
                        ? 'OFFLINE / TERKUNCI'
                        : (isPumpOn ? 'POMPA AKTIF' : 'SIAP DIGUNAKAN'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isOnline) ...[
          const SizedBox(height: 10),
          const Text(
            'Kontrol manual nonaktif saat sinyal terputus',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPumpProtectionBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Soft Blue tint box (Mockup 2)
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF0288D1),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proteksi Pompa Aktif',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sistem otomatis mematikan pompa setelah 30 menit penyiraman non-stop untuk menjaga kelembaban optimal umbi bawang.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.4,
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
