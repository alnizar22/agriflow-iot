import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mqtt_config.dart';
import '../providers/irrigation_provider.dart';
import '../services/mqtt_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _clientIdController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _telemetryTopicController;
  late TextEditingController _controlTopicController;

  bool _obscurePassword = true;

  late double _minThreshold;
  late double _maxThreshold;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<IrrigationProvider>(context, listen: false);
    final config = provider.config;

    _hostController = TextEditingController(text: config.brokerHost);
    _portController = TextEditingController(text: config.port.toString());
    _clientIdController = TextEditingController(text: config.clientId);
    _usernameController = TextEditingController(text: config.username);
    _passwordController = TextEditingController(text: config.password);
    _telemetryTopicController = TextEditingController(text: config.telemetryTopic);
    _controlTopicController = TextEditingController(text: config.controlTopic);

    _minThreshold = provider.minThreshold;
    _maxThreshold = provider.maxThreshold;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _clientIdController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _telemetryTopicController.dispose();
    _controlTopicController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final provider = Provider.of<IrrigationProvider>(context, listen: false);
    final portVal = int.tryParse(_portController.text.trim()) ?? 8883;

    final newConfig = MqttConfig(
      brokerHost: _hostController.text.trim(),
      port: portVal,
      clientId: _clientIdController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      telemetryTopic: _telemetryTopicController.text.trim(),
      controlTopic: _controlTopicController.text.trim(),
      useSecure: portVal == 8883 || portVal == 8884,
    );

    provider.updateMqttConfig(newConfig);
    provider.setThresholds(_minThreshold, _maxThreshold);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Konfigurasi berhasil disimpan & terhubung ke hardware!'),
        backgroundColor: Color(0xFF00E676),
      ),
    );

    Navigator.pop(context);
  }

  void _resetDefault() {
    final defaultConfig = MqttConfig();
    setState(() {
      _hostController.text = defaultConfig.brokerHost;
      _portController.text = defaultConfig.port.toString();
      _clientIdController.text = defaultConfig.clientId;
      _usernameController.text = defaultConfig.username;
      _passwordController.text = defaultConfig.password;
      _telemetryTopicController.text = defaultConfig.telemetryTopic;
      _controlTopicController.text = defaultConfig.controlTopic;
      _minThreshold = 60.0;
      _maxThreshold = 80.0;
    });

    final provider = Provider.of<IrrigationProvider>(context, listen: false);
    provider.resetToDefaultConfig();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Berhasil di-reset ke konfigurasi HiveMQ Cloud Serverless bawaan!'),
        backgroundColor: Color(0xFF00E676),
      ),
    );
  }

  void _sendTestTelemetry() async {
    final provider = Provider.of<IrrigationProvider>(context, listen: false);
    final ok = await provider.sendTestEsp32Telemetry(adc: 2450, temp: 29.5, hum: 68.0);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Contoh data telemetri berhasil terpublish ke prototype!'
            : 'Gagal mengirim: Pastikan aplikasi sudah terhubung ke broker.'),
        backgroundColor: ok ? const Color(0xFF00E676) : Colors.redAccent,
      ),
    );
  }

  void _sendTestSiramCommand() async {
    final provider = Provider.of<IrrigationProvider>(context, listen: false);
    final ok = await provider.togglePumpState(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? "Perintah 'SIRAM' berhasil terpublish ke prototype!"
              : "Gagal mengirim perintah: Broker belum terhubung (cek status koneksi).",
        ),
        backgroundColor: ok ? const Color(0xFF00E676) : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Pengaturan Broker & Irigasi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Koneksi Broker Real-Time
            Consumer<IrrigationProvider>(
              builder: (context, provider, child) {
                final isConnected = provider.connectionState == MqttConnectionState.connected;
                final isConnecting = provider.connectionState == MqttConnectionState.connecting;
                final isError = provider.connectionState == MqttConnectionState.error;

                Color statusColor = isConnected
                    ? const Color(0xFF00E676)
                    : isConnecting
                        ? Colors.amber
                        : Colors.redAccent;
                String statusText = isConnected
                    ? 'Terhubung ke HiveMQ Cloud Serverless'
                    : isConnecting
                        ? 'Menghubungkan ke Broker...'
                        : 'Terputus (Offline)';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        color: statusColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (provider.lastError.isNotEmpty && isError)
                              Text(
                                provider.lastError,
                                style: const TextStyle(color: Colors.white60, fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (!isConnected && !isConnecting)
                        TextButton(
                          onPressed: () => provider.connectMqtt(),
                          style: TextButton.styleFrom(
                            foregroundColor: statusColor,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          child: const Text('Hubungkan', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                );
              },
            ),

            // Section MQTT HiveMQ Broker
            _buildSectionHeader('Konfigurasi MQTT HiveMQ Broker (Hardware)', Icons.dns_rounded),
            const SizedBox(height: 12),

            _buildInputField(
              'Broker Host',
              _hostController,
              'adaa622b6b644c048748162b0be4ac5f.s1.eu.hivemq.cloud',
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildInputField(
                    'Port',
                    _portController,
                    '8883',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildInputField(
                    'Client ID',
                    _clientIdController,
                    'FlutterApp_Nizar',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Form Username & Password (Kredensial Autentikasi)
            _buildInputField(
              'MQTT Username',
              _usernameController,
              'nizar2209',
            ),
            const SizedBox(height: 12),

            _buildInputField(
              'MQTT Password',
              _passwordController,
              'saputra2209',
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),

            _buildInputField(
              'Topik Telemetry (Sensor Input)',
              _telemetryTopicController,
              'skripsi/nizar/soil',
            ),
            const SizedBox(height: 12),

            _buildInputField(
              'Topik Kontrol Pompa (Output)',
              _controlTopicController,
              'skripsi/nizar/manual',
            ),

            const SizedBox(height: 28),

            // Section Threshold Irigasi Otomatis (Skripsi Logic: <60% & >80%)
            _buildSectionHeader('Batas Threshold Irigasi Otomatis (Skripsi)', Icons.tune_rounded),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Batas Kritis Kering (< 60%)',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_minThreshold.toInt()}%',
                        style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Apabila kelembapan tanah turun di bawah angka ini, ESP32 akan menyalakan pompa air secara otomatis.',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                  Slider(
                    value: _minThreshold,
                    min: 30.0,
                    max: 75.0,
                    divisions: 45,
                    activeColor: const Color(0xFFE53935),
                    inactiveColor: Colors.white12,
                    onChanged: (val) {
                      setState(() {
                        if (val < _maxThreshold) _minThreshold = val;
                      });
                    },
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Batas Jenuh Basah (> 80%)',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_maxThreshold.toInt()}%',
                        style: const TextStyle(color: Color(0xFF0288D1), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Apabila kelembapan tanah mencapai/melebihi angka ini, ESP32 akan mematikan pompa air.',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                  Slider(
                    value: _maxThreshold,
                    min: 65.0,
                    max: 95.0,
                    divisions: 30,
                    activeColor: const Color(0xFF0288D1),
                    inactiveColor: Colors.white12,
                    onChanged: (val) {
                      setState(() {
                        if (val > _minThreshold) _maxThreshold = val;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Button Simpan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'SIMPAN KONFIGURASI',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Button Reset Default
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _resetDefault,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text(
                  'RESET DEFAULT BROKER HIVEMQ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Section Uji Komunikasi Hardware ESP32 & HiveMQ
            _buildSectionHeader('Uji Komunikasi ESP32 & Broker HiveMQ', Icons.send_rounded),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Uji Sinyal & Perintah Pompa:',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _sendTestSiramCommand,
                          icon: const Icon(Icons.water_drop_rounded, size: 18),
                          label: const Text(
                            "KIRIM 'SIRAM'",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0288D1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _sendTestTelemetry,
                          icon: const Icon(Icons.sensors_rounded, size: 18),
                          label: const Text(
                            'TEST SENSOR',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00E676),
                            side: const BorderSide(color: Color(0xFF00E676)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Petunjuk HiveMQ Web Client:\nAgar pesan tampil di tab 'Test your connection' HiveMQ, klik 'Topic Subscriptions' lalu subscribe ke topik 'skripsi/nizar/#' agar web console mendengarkan data dari ESP32 & Aplikasi.",
                            style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00E676), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF1E293B).withValues(alpha: 0.7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF00E676)),
            ),
          ),
        ),
      ],
    );
  }
}
