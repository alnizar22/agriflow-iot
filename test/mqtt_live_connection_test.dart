import 'package:flutter_test/flutter_test.dart';
import 'package:allimation/services/mqtt_service.dart';
import 'package:allimation/models/mqtt_config.dart';

void main() {
  test('Live MQTT connection to HiveMQ Cloud Serverless', () async {
    final config = MqttConfig();
    expect(config.brokerHost, 'adaa622b6b644c048748162b0be4ac5f.s1.eu.hivemq.cloud');
    expect(config.port, 8883);
    expect(config.username, 'nizar2209');
    expect(config.password, 'saputra2209');
    expect(config.useSecure, true);

    final service = MqttService(config: config);

    final connectSuccess = await service.connect();
    expect(connectSuccess, isTrue, reason: 'Harus berhasil terhubung ke HiveMQ Cloud: ${service.lastError}');
    expect(service.connectionState, MqttConnectionState.connected);

    // Test publish kendali pompa (mengirim 'SIRAM' ke skripsi/nizar/manual)
    final pubResult = service.publishPumpControl(true);
    expect(pubResult, isTrue);

    // Test publish contoh telemetri ESP32
    final testDataResult = await service.publishTestEsp32Data(adc: 2450, temp: 29.0, hum: 68.0);
    expect(testDataResult, isTrue);

    service.disconnect();
    expect(service.connectionState, MqttConnectionState.disconnected);
  }, timeout: const Timeout(Duration(seconds: 20)));
}
