import 'package:flutter_test/flutter_test.dart';
import 'package:allimation/models/mqtt_config.dart';

void main() {
  group('MqttConfig Hardware Default Tests', () {
    test('Default config matches flashed ESP32 hardware credentials', () {
      final config = MqttConfig();

      expect(config.brokerHost, 'adaa622b6b644c048748162b0be4ac5f.s1.eu.hivemq.cloud');
      expect(config.port, 8883);
      expect(config.clientId, 'FlutterApp_Nizar');
      expect(config.username, 'nizar2209');
      expect(config.password, 'saputra2209');
      expect(config.telemetryTopic, 'skripsi/nizar/soil');
      expect(config.controlTopic, 'skripsi/nizar/manual');
      expect(config.useSecure, true);
    });

    test('toJson and fromJson preserves credentials and secure flag', () {
      final config = MqttConfig();
      final json = config.toJson();

      expect(json['username'], 'nizar2209');
      expect(json['password'], 'saputra2209');
      expect(json['useSecure'], true);
      expect(json['port'], 8883);

      final restored = MqttConfig.fromJson(json);
      expect(restored.username, 'nizar2209');
      expect(restored.password, 'saputra2209');
      expect(restored.useSecure, true);
      expect(restored.brokerHost, config.brokerHost);
    });
  });
}
