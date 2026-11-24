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

  // State Pasca-Semhas: 3 Sensor & Deteksi Koneksi
  int? _soil1Adc;
  int? _soil2Adc;
  int? _soil3Adc;
  double? _soil1Percent;
  double? _soil2Percent;
  double? _soil3Percent;
  bool _isDeviceOnline = false;
  bool get isDeviceOnline => _isDeviceOnline;
  String? _disruptionReason;
  String? get disruptionReason => _disruptionReason;
  DateTime? _lastPacketTime;
  DateTime? get lastPacketTime => _lastPacketTime;

  MqttService({MqttConfig? config}) : _config = config ?? MqttConfig();

  void updateConfig(MqttConfig newConfig) {
    _config = newConfig;
    if (_connectionState == MqttConnectionState.connected) {
      disconnect();
    }
  }

  void setDeviceOnlineState(bool online, {String? reason}) {
    _isDeviceOnline = online;
    _disruptionReason = online ? null : reason;
    _emitCurrentData();
  }

  Future<bool> connect() async {
    _updateState(MqttConnectionState.connecting);
    _lastError = '';

    // Client ID dinamis untuk menghindari tabrakan sesi di broker HiveMQ
    final String activeClientId = _config.clientId.isNotEmpty
        ? _config.clientId
        : 'FlutterApp_Nizar_${DateTime.now().millisecondsSinceEpoch % 100000}';

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
      _isDeviceOnline = false;
      _disruptionReason = 'Koneksi internet HP / MQTT Broker terputus';
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
      _isDeviceOnline = false;
      _disruptionReason = 'Koneksi internet HP / MQTT Broker terputus';
      _client!.disconnect();
      _updateState(MqttConnectionState.error);
      return false;
    }
  }

  /// Subscribe ke topik telemetri ESP32 (soil, temp, hum, pompa, manual, status, soil_detail)
  void _subscribeToTelemetry() {
    if (_client != null && _connectionState == MqttConnectionState.connected) {
      final topicsToSubscribe = <String>{
        'skripsi/nizar/#', // Wildcard: Menangkap seluruh subtopik ESP32 tanpa ada yang terlewat
        'skripsi/nizar/status',
        'skripsi/nizar/soil_detail',
        'skripsi/nizar/soil',
        'skripsi/nizar/temp',
        'skripsi/nizar/hum',
        'skripsi/nizar/pompa',
        'skripsi/nizar/manual',
        _config.telemetryTopic,
        _config.controlTopic,
        _config.statusTopic,
        _config.soilDetailTopic,
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

      final cleanPayload = payload.trim();
      final lowerTopic = topic.toLowerCase();

      // 1. Deteksi Topik Status LWT ESP32 (skripsi/nizar/status)
      if (lowerTopic.endsWith('status') || lowerTopic == _config.statusTopic.toLowerCase()) {
        final upper = cleanPayload.toUpperCase();
        if (upper == 'ONLINE') {
          _isDeviceOnline = true;
          _disruptionReason = null;
          _lastPacketTime = DateTime.now();
        } else if (upper == 'OFFLINE') {
          _isDeviceOnline = false;
          _disruptionReason = 'Sinyal perangkat ESP32 terputus (Wi-Fi/kuota alat bermasalah)';
        }
        _emitCurrentData();
        return;
      }

      // 2. Deteksi Topik Detail 3 Sensor (skripsi/nizar/soil_detail)
      if (lowerTopic.endsWith('soil_detail') || lowerTopic == _config.soilDetailTopic.toLowerCase()) {
        try {
          final dynamic decoded = json.decode(cleanPayload);
          if (decoded is Map<String, dynamic>) {
            final s1 = (decoded['s1'] as num?)?.toInt();
            final s2 = (decoded['s2'] as num?)?.toInt();
            final s3 = (decoded['s3'] as num?)?.toInt();
            final avg = (decoded['avg'] as num?)?.toInt();

            if (s1 != null) {
              _soil1Adc = s1;
              _soil1Percent = SensorData.adcToPercent(s1);
            }
            if (s2 != null) {
              _soil2Adc = s2;
              _soil2Percent = SensorData.adcToPercent(s2);
            }
            if (s3 != null) {
              _soil3Adc = s3;
              _soil3Percent = SensorData.adcToPercent(s3);
            }
            if (avg != null) {
              _lastRawSoilAdc = avg;
              _lastSoilMoisture = SensorData.adcToPercent(avg);
            } else if (s1 != null && s2 != null && s3 != null) {
              _lastRawSoilAdc = ((s1 + s2 + s3) / 3).round();
              _lastSoilMoisture = SensorData.adcToPercent(_lastRawSoilAdc!);
            }

            _hasReceivedHardwareData = true;
            _hasReceivedSoilData = true;
            _lastPacketTime = DateTime.now();
            _isDeviceOnline = true;
            _disruptionReason = null;
            _emitCurrentData();
            return;
          }
        } catch (e) {
          if (kDebugMode) print('Error parsing soil_detail JSON: $e');
        }
      }

      // 3. Coba decode JSON umum jika ada
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
          _soil1Adc = sensorData.soil1Adc ?? _soil1Adc;
          _soil2Adc = sensorData.soil2Adc ?? _soil2Adc;
          _soil3Adc = sensorData.soil3Adc ?? _soil3Adc;
          _soil1Percent = sensorData.soil1Percent ?? _soil1Percent;
          _soil2Percent = sensorData.soil2Percent ?? _soil2Percent;
          _soil3Percent = sensorData.soil3Percent ?? _soil3Percent;
          _lastPacketTime = DateTime.now();
          _isDeviceOnline = true;
          _disruptionReason = null;
          _sensorDataController.add(sensorData.copyWith(
            isDeviceOnline: true,
            lastPacketTime: _lastPacketTime,
          ));
          return;
        }
      } catch (_) {
        // Bukan JSON umum, parsing nilai mentah di bawah
      }

      // 4. Parser data mentah ESP32 sesuai topik individual
      final numVal = double.tryParse(cleanPayload);

      if (lowerTopic.endsWith('soil') || lowerTopic.contains('soil') || lowerTopic == _config.telemetryTopic.toLowerCase()) {
        if (numVal != null) {
          _hasReceivedHardwareData = true;
          _hasReceivedSoilData = true;
          _lastPacketTime = DateTime.now();
          _isDeviceOnline = true;
          _disruptionReason = null;

          if (numVal > 100.0) {
            _lastRawSoilAdc = numVal.toInt();
            _lastSoilMoisture = SensorData.adcToPercent(numVal);
          } else {
            _lastSoilMoisture = numVal;
          }
        }
      } else if (lowerTopic.endsWith('temp') || lowerTopic.contains('temp') || lowerTopic.contains('suhu')) {
        if (numVal != null) {
          _hasReceivedHardwareData = true;
          _lastTemperature = numVal;
          _lastPacketTime = DateTime.now();
          _isDeviceOnline = true;
          _disruptionReason = null;
        }
      } else if (lowerTopic.endsWith('hum') || lowerTopic.contains('hum') || lowerTopic.contains('kelembapan_udara')) {
        if (numVal != null) {
          _hasReceivedHardwareData = true;
          _lastHumidity = numVal;
          _lastPacketTime = DateTime.now();
          _isDeviceOnline = true;
          _disruptionReason = null;
        }
      } else if (lowerTopic.endsWith('pompa') || lowerTopic.contains('pompa')) {
        _hasReceivedHardwareData = true;
        _lastPacketTime = DateTime.now();
        _isDeviceOnline = true;
        _disruptionReason = null;
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

      _emitCurrentData();
    });
  }

  void _emitCurrentData() {
    final mergedData = SensorData(
      soilMoisture: _lastSoilMoisture,
      temperature: _lastTemperature,
      humidity: _lastHumidity,
      isPumpOn: _lastPumpOn,
      rawSoilAdc: _lastRawSoilAdc,
      pumpStatusText: _lastPumpStatusText,
      hasData: _hasReceivedHardwareData,
      hasSoilData: _hasReceivedSoilData,
      soil1Adc: _soil1Adc,
      soil2Adc: _soil2Adc,
      soil3Adc: _soil3Adc,
      soil1Percent: _soil1Percent,
      soil2Percent: _soil2Percent,
      soil3Percent: _soil3Percent,
      isDeviceOnline: _isDeviceOnline,
      lastPacketTime: _lastPacketTime,
      timestamp: DateTime.now(),
    );

    _sensorDataController.add(mergedData);
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
  Future<bool> publishTestEsp32Data({
    int adc = 2450,
    double temp = 29.0,
    double hum = 68.0,
    int s1 = 2500,
    int s2 = 2450,
    int s3 = 2400,
  }) async {
    if (_client == null || _connectionState != MqttConnectionState.connected) {
      return false;
    }

    try {
      // 1. Publish status ONLINE
      final bStatus = mqtt.MqttClientPayloadBuilder()..addString('ONLINE');
      _client!.publishMessage('skripsi/nizar/status', mqtt.MqttQos.atLeastOnce, bStatus.payload!);

      // 2. Publish average soil ADC
      final bSoil = mqtt.MqttClientPayloadBuilder()..addString(adc.toString());
      _client!.publishMessage('skripsi/nizar/soil', mqtt.MqttQos.atLeastOnce, bSoil.payload!);

      // 3. Publish soil detail JSON
      final jsonDetail = '{"s1":$s1,"s2":$s2,"s3":$s3,"avg":$adc}';
      final bDetail = mqtt.MqttClientPayloadBuilder()..addString(jsonDetail);
      _client!.publishMessage('skripsi/nizar/soil_detail', mqtt.MqttQos.atLeastOnce, bDetail.payload!);

      // 4. Publish temp & hum
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
    _isDeviceOnline = false;
    _disruptionReason = 'Koneksi internet HP / MQTT Broker terputus';
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
    _isDeviceOnline = false;
    _disruptionReason = 'Koneksi internet HP / MQTT Broker terputus';
    if (_connectionState != MqttConnectionState.error) {
      _updateState(MqttConnectionState.disconnected);
    }
    _emitCurrentData();
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
