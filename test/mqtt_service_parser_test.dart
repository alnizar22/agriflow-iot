import 'package:flutter_test/flutter_test.dart';
import 'package:allimation/models/mqtt_config.dart';
import 'package:allimation/models/sensor_data.dart';

void main() {
  group('MqttConfig Hardware Default Tests', () {
    test('Default config matches flashed ESP32 hardware credentials', () {
      final config = MqttConfig();

      expect(config.brokerHost, 'adaa622b6b644c048748162b0be4ac5f.s1.eu.hivemq.cloud');
      expect(config.port, 8883);
      expect(config.clientId, startsWith('FlutterApp_Nizar'));
      expect(config.username, 'nizar2209');
      expect(config.password, 'saputra2209');
      expect(config.telemetryTopic, 'skripsi/nizar/soil');
      expect(config.controlTopic, 'skripsi/nizar/manual');
      expect(config.statusTopic, 'skripsi/nizar/status');
      expect(config.soilDetailTopic, 'skripsi/nizar/soil_detail');
      expect(config.useSecure, true);
    });

    test('toJson and fromJson preserves credentials and topics', () {
      final config = MqttConfig(clientId: 'TestClient_123');
      final json = config.toJson();

      expect(json['username'], 'nizar2209');
      expect(json['password'], 'saputra2209');
      expect(json['statusTopic'], 'skripsi/nizar/status');
      expect(json['soilDetailTopic'], 'skripsi/nizar/soil_detail');
      expect(json['useSecure'], true);
      expect(json['port'], 8883);

      final restored = MqttConfig.fromJson(json);
      expect(restored.username, 'nizar2209');
      expect(restored.password, 'saputra2209');
      expect(restored.statusTopic, 'skripsi/nizar/status');
      expect(restored.soilDetailTopic, 'skripsi/nizar/soil_detail');
      expect(restored.useSecure, true);
      expect(restored.brokerHost, config.brokerHost);
    });
  });

  group('SensorData 3-Sensor & Post-Semhas Parser Tests', () {
    test('adcToPercent converts ESP32 12-bit ADC properly', () {
      // 3600 ADC -> 0%
      expect(SensorData.adcToPercent(3600), 0.0);
      // 1200 ADC -> 100%
      expect(SensorData.adcToPercent(1200), 100.0);
      // 2400 ADC -> 50%
      expect(SensorData.adcToPercent(2400), 50.0);
    });

    test('fromJson parses soil_detail JSON correctly', () {
      final json = {
        's1': 2400,
        's2': 1800,
        's3': 1200,
        'avg': 1800,
      };

      final data = SensorData.fromJson(json);
      expect(data.soil1Adc, 2400);
      expect(data.soil2Adc, 1800);
      expect(data.soil3Adc, 1200);
      expect(data.rawSoilAdc, 1800);
      expect(data.soil1Percent, 50.0);
      expect(data.soil2Percent, 75.0);
      expect(data.soil3Percent, 100.0);
      expect(data.soilMoisture, 75.0);
      expect(data.hasData, isTrue);
      expect(data.hasSoilData, isTrue);
    });

    test('SensorData.empty() initializes default safe state', () {
      final empty = SensorData.empty();
      expect(empty.hasData, isFalse);
      expect(empty.hasSoilData, isFalse);
      expect(empty.isDeviceOnline, isFalse);
      expect(empty.soil1Adc, isNull);
      expect(empty.soil1Percent, isNull);
      expect(empty.soilMoisture, 0.0);
    });
  });
}
