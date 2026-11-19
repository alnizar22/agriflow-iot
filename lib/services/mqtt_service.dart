import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/mqtt_config.dart';
import '../models/sensor_data.dart';

enum MqttConnectionState { disconnected, connecting, connected, error }

class MqttService {
  MqttServerClient? _client;
  MqttConfig _config;

  MqttConnectionState _connectionState = MqttConnectionState.disconnected;
  MqttConnectionState get connectionState => _connectionState;

  final _sensorDataController = StreamController<SensorData>.broadcast();
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;

  final _connectionStateController = StreamController<MqttConnectionState>.broadcast();
  Stream<MqttConnectionState> get connectionStateStream => _connectionStateController.stream;

  String _lastError = '';
  String get lastError => _lastError;

  // Buffer state gabungan sensor untuk data mentah multi-topik ESP32
  bool _hasReceivedHardwareData = false;
  bool _hasReceivedSoilData = false;
  double _lastSoilMoisture = 0.0;
  double _lastTemperature = 0.0;
  double _lastHumidity = 0.0;
  bool _lastPumpOn = false;
  int? _lastRawSoilAdc;
  String? _lastPumpStatusText;

  MqttService({MqttConfig? config}) : _config = config ?? MqttConfig();

  void updateConfig(MqttConfig newConfig) {
    _config = newConfig;
    if (_connectionState == MqttConnectionState.connected) {
      disconnect();
    }
  }

  Future<bool> connect() async {
    _updateState(MqttConnectionState.connecting);
    _lastError = '';

    // Pastikan client ID selalu unik per koneksi untuk menghindari tabrakan sesi di broker HiveMQ Cloud Serverless
    final String baseId = _config.clientId.isEmpty ? 'FlutterApp_Nizar' : _config.clientId;
    final activeClientId = '${baseId}_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    _client = MqttServerClient.withPort(
      _config.brokerHost,
      activeClientId,
      _config.port,
    );

    _client!.logging(on: false);
    _client!.keepAlivePeriod = 60;
    _client!.autoReconnect = true;
    _client!.setProtocolV311();
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.pongCallback = _pong;

    // Aktifkan koneksi aman (TLS/SSL) untuk HiveMQ Cloud port 8883
    if (_config.useSecure || _config.port == 8883) {
      _client!.secure = true;
      _client!.securityContext = SecurityContext.defaultContext;
      _client!.onBadCertificate = (Object _) => true;
    }

    final connMess = mqtt.MqttConnectMessage()
        .withClientIdentifier(activeClientId)
        .startClean()
        .authenticateAs(
          _config.username.isNotEmpty ? _config.username : null,
          _config.password.isNotEmpty ? _config.password : null,
        );

    _client!.connectionMessage = connMess;

    try {
      if (kDebugMode) {
        print('MQTT: Connecting to ${_config.brokerHost}:${_config.port} (TLS: ${_client!.secure})...');
      }
      await _client!.connect(
        _config.username.isNotEmpty ? _config.username : null,
        _config.password.isNotEmpty ? _config.password : null,
      );
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) {
        print('MQTT Exception: $e');
      }
      _client!.disconnect();
      _updateState(MqttConnectionState.error);
      return false;
    }

    if (_client!.connectionStatus?.state == mqtt.MqttConnectionState.connected) {
      _updateState(MqttConnectionState.connected);
      _subscribeToTelemetry();
      _listenToMessages();
      return true;
    } else {
      _lastError = 'Connection failed: ${_client!.connectionStatus?.returnCode}';
      _client!.disconnect();
      _updateState(MqttConnectionState.error);
      return false;
    }
  }

  /// Subscribe ke topik telemetri ESP32 (soil, temp, hum, pompa, manual)
  void _subscribeToTelemetry() {
    if (_client != null && _connectionState == MqttConnectionState.connected) {
      final topicsToSubscribe = <String>{
        'skripsi/nizar/#', // Wildcard: Menangkap seluruh subtopik ESP32 tanpa ada yang terlewat
        'skripsi/nizar/soil',
        'skripsi/nizar/temp',
        'skripsi/nizar/hum',
        'skripsi/nizar/pompa',
        'skripsi/nizar/manual',
        _config.telemetryTopic,
        _config.controlTopic,
      };

      for (final topic in topicsToSubscribe) {
        if (topic.isNotEmpty) {
          if (kDebugMode) {
            print('MQTT: Subscribing to $topic');
          }
          _client!.subscribe(topic, mqtt.MqttQos.atMostOnce);
        }
      }
    }
  }

  /// Menerima pesan dan mengonversi format data sesuai C++ ESP32
  void _listenToMessages() {
    _client?.updates?.listen((List<mqtt.MqttReceivedMessage<mqtt.MqttMessage?>>? messages) {
      if (messages == null || messages.isEmpty) return;

      final recMessage = messages[0].payload as mqtt.MqttPublishMessage;
      final payload = mqtt.MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
      final topic = messages[0].topic;

      if (kDebugMode) {
        print('MQTT Received Payload on topic [$topic]: $payload');
      }

      // 1. Coba decode JSON terlebih dahulu jika data berupa JSON Map
      try {
        final dynamic decoded = json.decode(payload);
        if (decoded is Map<String, dynamic>) {
          final sensorData = SensorData.fromJson(decoded);
          _hasReceivedHardwareData = true;
          _lastSoilMoisture = sensorData.soilMoisture;
          _lastTemperature = sensorData.temperature;
          _lastHumidity = sensorData.humidity;
          _lastPumpOn = sensorData.isPumpOn;
          _lastRawSoilAdc = sensorData.rawSoilAdc;
          _lastPumpStatusText = sensorData.pumpStatusText;
          _sensorDataController.add(sensorData);
          return;
        }
      } catch (_) {
        // Bukan JSON, parsing nilai mentah di bawah
      }

      // 2. Parser data mentah ESP32 sesuai topik individual
      final cleanPayload = payload.trim();
      final numVal = double.tryParse(cleanPayload);
      final lowerTopic = topic.toLowerCase();

      if (lowerTopic.endsWith('soil') || lowerTopic.contains('soil') || lowerTopic == _config.telemetryTopic.toLowerCase()) {
        if (numVal != null) {
          _hasReceivedHardwareData = true;
          _hasReceivedSoilData = true;
          if (numVal > 100.0) {
            // ADC ESP32 12-bit (0 - 4095)
            // Di Arduino: avgSoil = (analogRead(32)+analogRead(33)+analogRead(34))/3
            // Di Arduino: avgSoil > 2500 adalah KERING, avgSoil <= 2500 adalah IDEAL
            _lastRawSoilAdc = numVal.toInt();
            // Pemetaan ADC ke persentase 0-100%:
            // 3600 ADC (kering di udara) -> ~0-10%
            // 2500 ADC (threshold batas kering skripsi) -> ~55%
            // 1200 ADC (basah air) -> ~100%
            double percent = ((3600.0 - numVal) / (3600.0 - 1200.0)) * 100.0;
            _lastSoilMoisture = double.parse(percent.clamp(0.0, 100.0).toStringAsFixed(1));
          } else {
            _lastSoilMoisture = numVal;
          }
        }
      } else if (lowerTopic.endsWith('temp') || lowerTopic.contains('temp') || lowerTopic.contains('suhu')) {
        if (numVal != null) {
          _hasReceivedHardwareData = true;
          _lastTemperature = numVal;
        }
      } else if (lowerTopic.endsWith('hum') || lowerTopic.contains('hum') || lowerTopic.contains('kelembapan_udara')) {
        if (numVal != null) {
          _hasReceivedHardwareData = true;
          _lastHumidity = numVal;
        }
      } else if (lowerTopic.endsWith('pompa') || lowerTopic.contains('pompa')) {
        _hasReceivedHardwareData = true;
        // ESP32 mem-publish status ke skripsi/nizar/pompa:
        // "MENYIRAM (AUTO)", "SIRAM MANUAL (5 DETIK)", "JEDA RESAP", "STANDBY"
        _lastPumpStatusText = cleanPayload;
        final upper = cleanPayload.toUpperCase();
        if (upper.contains('MENYIRAM') || upper.contains('SIRAM') || upper == '1' || upper == 'ON') {
          _lastPumpOn = true;
        } else if (upper.contains('STANDBY') || upper.contains('JEDA') || upper == '0' || upper == 'OFF') {
          _lastPumpOn = false;
        }
      } else if (lowerTopic.endsWith('manual') || lowerTopic.contains('manual')) {
        // Echo kendali manual dari broker
        final upper = cleanPayload.toUpperCase();
        if (upper == 'SIRAM' || upper == '1' || upper == 'ON') {
          _lastPumpOn = true;
          _lastPumpStatusText = 'SIRAM MANUAL (5 DETIK)';
        }
      }

      // Gabungkan telemetri mentah menjadi SensorData utuh
      final mergedData = SensorData(
        soilMoisture: _lastSoilMoisture,
        temperature: _lastTemperature,
        humidity: _lastHumidity,
        isPumpOn: _lastPumpOn,
        rawSoilAdc: _lastRawSoilAdc,
        pumpStatusText: _lastPumpStatusText,
        hasData: _hasReceivedHardwareData,
        hasSoilData: _hasReceivedSoilData,
        timestamp: DateTime.now(),
      );

      _sensorDataController.add(mergedData);
    });
  }

  /// Mengirim sinyal kendali pompa ke ESP32 pada topik skripsi/nizar/manual
  /// Sesuai sintaks C++ Arduino IDE ESP32: if (msg == "SIRAM")
  bool publishPumpControl(bool turnOn) {
    if (_client == null || _connectionState != MqttConnectionState.connected) {
      if (kDebugMode) {
        print('Cannot publish pump command: MQTT client disconnected');
      }
      return false;
    }

    _lastPumpOn = turnOn;
    final builder = mqtt.MqttClientPayloadBuilder();
    // Di C++ ESP32: if (String(topic) == "skripsi/nizar/manual") { if (msg == "SIRAM") { ... } }
    final commandPayload = turnOn ? 'SIRAM' : '0';
    builder.addString(commandPayload);

    try {
      _client!.publishMessage(
        _config.controlTopic.isNotEmpty ? _config.controlTopic : 'skripsi/nizar/manual',
        mqtt.MqttQos.atLeastOnce,
        builder.payload!,
      );
      if (kDebugMode) {
        print('MQTT Published to ${_config.controlTopic}: $commandPayload');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Publish error: $e');
      }
      return false;
    }
  }

  /// Mengirim contoh data telemetri persis seperti yang di-publish oleh ESP32
  /// Untuk memverifikasi penerimaan di HiveMQ Cloud WebClient dan aplikasi
  Future<bool> publishTestEsp32Data({int adc = 2450, double temp = 29.0, double hum = 68.0}) async {
    if (_client == null || _connectionState != MqttConnectionState.connected) {
      return false;
    }

    try {
      final bSoil = mqtt.MqttClientPayloadBuilder()..addString(adc.toString());
      _client!.publishMessage('skripsi/nizar/soil', mqtt.MqttQos.atLeastOnce, bSoil.payload!);

      final bTemp = mqtt.MqttClientPayloadBuilder()..addString(temp.toString());
      _client!.publishMessage('skripsi/nizar/temp', mqtt.MqttQos.atLeastOnce, bTemp.payload!);

      final bHum = mqtt.MqttClientPayloadBuilder()..addString(hum.toString());
      _client!.publishMessage('skripsi/nizar/hum', mqtt.MqttQos.atLeastOnce, bHum.payload!);

      final bPompa = mqtt.MqttClientPayloadBuilder()..addString('STANDBY');
      _client!.publishMessage('skripsi/nizar/pompa', mqtt.MqttQos.atLeastOnce, bPompa.payload!);

      return true;
    } catch (e) {
      if (kDebugMode) print('Test publish error: $e');
      return false;
    }
  }

  void disconnect() {
    if (_client != null) {
      _client!.disconnect();
    }
    _updateState(MqttConnectionState.disconnected);
  }

  void _onConnected() {
    if (kDebugMode) {
      print('MQTT Client Connected to HiveMQ Cloud');
    }
    _updateState(MqttConnectionState.connected);
  }

  void _onDisconnected() {
    if (kDebugMode) {
      print('MQTT Client Disconnected');
    }
    if (_connectionState != MqttConnectionState.error) {
      _updateState(MqttConnectionState.disconnected);
    }
  }

  void _onSubscribed(String topic) {
    if (kDebugMode) {
      print('MQTT Subscribed topic: $topic');
    }
  }

  void _pong() {
    if (kDebugMode) {
      print('MQTT Ping response received from HiveMQ');
    }
  }

  void _updateState(MqttConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  void dispose() {
    disconnect();
    _sensorDataController.close();
    _connectionStateController.close();
  }
}
