import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mqtt_config.dart';
import '../models/sensor_data.dart';
import '../services/mqtt_service.dart';

class IrrigationProvider with ChangeNotifier {
  late MqttService _mqttService;
  MqttConfig _config = MqttConfig();

  SensorData _currentData = SensorData.empty();
  final List<SensorData> _history = [];

  // Default threshold values synced with Skripsi thesis logic
  double _minThreshold = 60.0; // < 60% : Pompa Menyala (Kritis)
  double _maxThreshold = 80.0; // > 80% : Pompa Mati (Proteksi Over-Irrigation)

  bool _isAutoMode = true;
  bool _isSimulationActive = false;
  Timer? _simulationTimer;
  Timer? _watchdogTimer;

  StreamSubscription<SensorData>? _dataSubscription;
  StreamSubscription<MqttConnectionState>? _stateSubscription;

  // Stream untuk memicu Dialog Gangguan Sinyal (Hanya 1x per insiden putus koneksi)
  final _disruptionAlertController = StreamController<String>.broadcast();
  Stream<String> get disruptionAlertStream => _disruptionAlertController.stream;
  bool _hasShownDisruptionAlert = false;
  String? _watchdogDisruptionReason;

  // Waktu buka aplikasi untuk deteksi awal
  final DateTime _appStartTime = DateTime.now();

  // Getters
  SensorData get currentData => _currentData;
  List<SensorData> get history => List.unmodifiable(_history);
  MqttConfig get config => _config;
  MqttConnectionState get connectionState => _mqttService.connectionState;
  String get lastError => _mqttService.lastError;

  double get minThreshold => _minThreshold;
  double get maxThreshold => _maxThreshold;
  bool get isAutoMode => _isAutoMode;
  bool get isSimulationActive => _isSimulationActive;
  bool get hasData => _currentData.hasData || _isSimulationActive;

  // Status Perangkat Online (ESP32 mengirim data aktif & status LWT ONLINE)
  bool get isDeviceOnline => _isSimulationActive ? true : _currentData.isDeviceOnline;
  String? get disruptionReason => _currentData.isDeviceOnline
      ? null
      : (_mqttService.disruptionReason ?? _watchdogDisruptionReason);
  DateTime? get lastPacketTime => _currentData.lastPacketTime;

  IrrigationProvider() {
    _mqttService = MqttService(config: _config);
    _initSubscriptions();
    _startWatchdogTimer();
    _loadPreferences().then((_) {
      connectMqtt().then((success) {
        if (!success) {
          Future.delayed(const Duration(seconds: 3), () {
            if (_mqttService.connectionState != MqttConnectionState.connected) {
              connectMqtt();
            }
          });
        }
      });
    });
  }

  void _initSubscriptions() {
    _dataSubscription = _mqttService.sensorDataStream.listen((data) {
      _processIncomingSensorData(data);
    });

    _stateSubscription = _mqttService.connectionStateStream.listen((state) {
      if (state != MqttConnectionState.connected && !_isSimulationActive) {
        _handleBrokerDisconnection();
      }
      notifyListeners();
    });
  }

  /// Timer periodik 5 detik untuk mendeteksi timeout data (>15 detik tidak ada paket baru)
  void _startWatchdogTimer() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isSimulationActive) return;

      final isMqttConnected = _mqttService.connectionState == MqttConnectionState.connected;

      if (!isMqttConnected) {
        // Cek jika app sudah buka > 10 detik dan gagal connect broker
        final elapsedSinceStart = DateTime.now().difference(_appStartTime).inSeconds;
        if (elapsedSinceStart > 10) {
          _handleBrokerDisconnection();
        }
        return;
      }

      // Jika terhubung ke broker, periksa waktu paket sensor terakhir
      if (_currentData.hasData && _currentData.lastPacketTime != null) {
        final elapsed = DateTime.now().difference(_currentData.lastPacketTime!).inSeconds;
        if (elapsed > 15) {
          // ESP32 berhenti mengirim data > 15 detik
          if (_currentData.isDeviceOnline) {
            _watchdogDisruptionReason =
                'Perangkat irigasi di lahan tidak mengirim data. Periksa sinyal Wi-Fi/hotspot atau kuota internet pada alat. (Penyiraman otomatis lokal pada alat tetap berjalan).';
            _mqttService.setDeviceOnlineState(false, reason: _watchdogDisruptionReason);
            _currentData = _currentData.copyWith(isDeviceOnline: false);
            _triggerDisruptionAlert(_watchdogDisruptionReason!);
            notifyListeners();
          }
        }
      } else {
        // Belum menerima data sama sekali sejak buka aplikasi > 12 detik
        final elapsedSinceStart = DateTime.now().difference(_appStartTime).inSeconds;
        if (elapsedSinceStart > 12 && !_hasShownDisruptionAlert) {
          _watchdogDisruptionReason =
              'Perangkat irigasi di lahan belum terhubung. Periksa daya alat prototype ESP32 dan jaringan Wi-Fi.';
          _triggerDisruptionAlert(_watchdogDisruptionReason!);
        }
      }
    });
  }

  void _handleBrokerDisconnection() {
    final reason = 'Koneksi internet smartphone terputus dari server MQTT. Periksa jaringan seluler atau Wi-Fi Anda.';
    _watchdogDisruptionReason = reason;
    if (_currentData.isDeviceOnline) {
      _currentData = _currentData.copyWith(isDeviceOnline: false);
    }
    _triggerDisruptionAlert(reason);
    notifyListeners();
  }

  void _triggerDisruptionAlert(String reason) {
    if (!_hasShownDisruptionAlert && !_isSimulationActive) {
      _hasShownDisruptionAlert = true;
      _disruptionAlertController.add(reason);
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _minThreshold = prefs.getDouble('minThreshold') ?? 60.0;
      _maxThreshold = prefs.getDouble('maxThreshold') ?? 80.0;
      _isAutoMode = prefs.getBool('isAutoMode') ?? true;

      final configJsonStr = prefs.getString('mqttConfig');
      if (configJsonStr != null) {
        final Map<String, dynamic> decoded = json.decode(configJsonStr);
        if (decoded['brokerHost'] !=
                'adaa622b6b644c048748162b0be4ac5f.s1.eu.hivemq.cloud' ||
            decoded['username'] == null ||
            decoded['username'] == '' ||
            decoded['port'] != 8883) {
          _config = MqttConfig();
          await savePreferences();
        } else {
          _config = MqttConfig.fromJson(decoded);
        }
        _mqttService.updateConfig(_config);
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading preferences: $e');
      }
    }
  }

  Future<void> savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('minThreshold', _minThreshold);
      await prefs.setDouble('maxThreshold', _maxThreshold);
      await prefs.setBool('isAutoMode', _isAutoMode);
      await prefs.setString('mqttConfig', json.encode(_config.toJson()));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving preferences: $e');
      }
    }
  }

  /// Memproses data sensor masuk dan mengevaluasi aturan irigasi otomatis skripsi
  void _processIncomingSensorData(SensorData newData) {
    bool pumpState = newData.isPumpOn;

    // Jika data online kembali, reset flag alert agar bisa memicu alert baru jika putus di masa mendatang
    if (newData.isDeviceOnline) {
      _hasShownDisruptionAlert = false;
      _watchdogDisruptionReason = null;
    } else if (newData.hasData && !newData.isDeviceOnline) {
      _triggerDisruptionAlert(_mqttService.disruptionReason ??
          'Perangkat irigasi di lahan tidak mengirim data. Periksa sinyal Wi-Fi/hotspot atau kuota internet pada alat. (Penyiraman otomatis lokal pada alat tetap berjalan).');
    }

    // Evaluasi Aturan Irigasi Otomatis (Skripsi Logic) HANYA jika data riil telah diterima
    if (newData.hasData) {
      if (_isAutoMode) {
        if (newData.soilMoisture < _minThreshold) {
          pumpState = true;
        } else if (newData.soilMoisture >= _maxThreshold) {
          pumpState = false;
        }
      } else {
        // Proteksi Tambahan: Bahkan dalam mode manual, jika kelembapan melampaui > 80%,
        // paksa matikan pompa untuk mencegah pembusukan akar umbi bawang (Proteksi Over-Irrigation)
        if (newData.soilMoisture >= _maxThreshold && pumpState) {
          pumpState = false;
          if (_mqttService.connectionState == MqttConnectionState.connected) {
            _mqttService.publishPumpControl(false);
          }
        }
      }
    }

    _currentData = newData.copyWith(
      isPumpOn: pumpState,
      isAutoMode: _isAutoMode,
    );

    if (newData.hasData) {
      _addHistoryPoint(_currentData);
    }
    notifyListeners();
  }

  void _addHistoryPoint(SensorData data) {
    _history.add(data);
    // Pertahankan maksimum 30 titik data riwayat untuk grafik tren
    if (_history.length > 30) {
      _history.removeAt(0);
    }
  }

  /// Connect to HiveMQ Broker
  Future<bool> connectMqtt() async {
    if (_isSimulationActive) {
      stopSimulation();
    }
    final ok = await _mqttService.connect();
    if (ok) {
      _hasShownDisruptionAlert = false;
      _watchdogDisruptionReason = null;
    }
    return ok;
  }

  /// Disconnect from HiveMQ Broker
  void disconnectMqtt() {
    _mqttService.disconnect();
    notifyListeners();
  }

  /// Mengirim contoh data telemetri ESP32 untuk verifikasi live connection
  Future<bool> sendTestEsp32Telemetry({
    int adc = 2450,
    double temp = 29.0,
    double hum = 68.0,
    int s1 = 2500,
    int s2 = 2450,
    int s3 = 2400,
  }) async {
    return await _mqttService.publishTestEsp32Data(
      adc: adc,
      temp: temp,
      hum: hum,
      s1: s1,
      s2: s2,
      s3: s3,
    );
  }

  /// Toggle manual saklar pompa air (ON / OFF)
  Future<bool> togglePumpState(bool turnOn) async {
    // Pengaman: Jika perangkat offline, tolak kontrol manual
    if (!isDeviceOnline && !_isSimulationActive) {
      if (kDebugMode) {
        print('Pengaman: Kontrol manual ditolak karena perangkat offline / sinyal terputus.');
      }
      return false;
    }

    // Proteksi: Jika kelembapan tanah sudah >= 80%, kunci pompa ke OFF
    if (turnOn && _currentData.soilMoisture >= _maxThreshold) {
      if (kDebugMode) {
        print('Proteksi Aktif: Kelembapan tanah >= 80%, saklar ditolak.');
      }
      return false;
    }

    _isAutoMode = false;
    _currentData = _currentData.copyWith(isPumpOn: turnOn, isAutoMode: false);
    notifyListeners();

    bool published = false;
    if (_mqttService.connectionState != MqttConnectionState.connected) {
      final ok = await _mqttService.connect();
      if (ok) {
        published = _mqttService.publishPumpControl(turnOn);
      }
    } else {
      published = _mqttService.publishPumpControl(turnOn);
    }

    savePreferences();
    return published;
  }

  /// Toggle Mode Otomatis vs Manual
  void toggleAutoMode(bool autoMode) {
    _isAutoMode = autoMode;
    _currentData = _currentData.copyWith(isAutoMode: autoMode);

    if (autoMode) {
      if (_currentData.soilMoisture < _minThreshold) {
        _currentData = _currentData.copyWith(isPumpOn: true);
        if (_mqttService.connectionState == MqttConnectionState.connected) {
          _mqttService.publishPumpControl(true);
        }
      } else if (_currentData.soilMoisture >= _maxThreshold) {
        _currentData = _currentData.copyWith(isPumpOn: false);
        if (_mqttService.connectionState == MqttConnectionState.connected) {
          _mqttService.publishPumpControl(false);
        }
      }
    }

    notifyListeners();
    savePreferences();
  }

  /// Update ambang batas kelembapan (min 60%, max 80%)
  void setThresholds(double minVal, double maxVal) {
    _minThreshold = minVal;
    _maxThreshold = maxVal;
    notifyListeners();
    savePreferences();
  }

  /// Update konfigurasi broker MQTT HiveMQ dan segera sambungkan ulang
  void updateMqttConfig(MqttConfig newConfig) {
    _config = newConfig;
    _mqttService.updateConfig(_config);
    notifyListeners();
    savePreferences();
    connectMqtt();
  }

  /// Reset semua konfigurasi broker dan threshold ke pengaturan bawaan skripsi
  void resetToDefault() {
    _config = MqttConfig();
    _minThreshold = 60.0;
    _maxThreshold = 80.0;
    _isAutoMode = true;
    _mqttService.updateConfig(_config);
    notifyListeners();
    savePreferences();
    connectMqtt();
  }

  void resetToDefaultConfig() => resetToDefault();

  /// Toggle Mode Simulasi untuk demonstrasi seminar tanpa hardware fisik
  void toggleSimulationMode() {
    if (_isSimulationActive) {
      stopSimulation();
    } else {
      startSimulation();
    }
  }

  void toggleSimulation() => toggleSimulationMode();

  void startSimulation() {
    if (_mqttService.connectionState == MqttConnectionState.connected) {
      _mqttService.disconnect();
    }
    _isSimulationActive = true;

    final initialMoisture = _currentData.hasData ? _currentData.soilMoisture : 65.0;
    final initialPump = _currentData.isPumpOn;

    // Nilai simulasi 3 sensor tanah
    final s1Adc = 2400;
    final s2Adc = 2200;
    final s3Adc = 2000;

    _currentData = SensorData(
      soilMoisture: initialMoisture,
      temperature: 28.5,
      humidity: 72.0,
      isPumpOn: initialPump,
      isAutoMode: _isAutoMode,
      hasData: true,
      hasSoilData: true,
      soil1Adc: s1Adc,
      soil2Adc: s2Adc,
      soil3Adc: s3Adc,
      soil1Percent: SensorData.adcToPercent(s1Adc),
      soil2Percent: SensorData.adcToPercent(s2Adc),
      soil3Percent: SensorData.adcToPercent(s3Adc),
      isDeviceOnline: true,
      lastPacketTime: DateTime.now(),
      pumpStatusText: initialPump ? 'MENYIRAM (SIMULASI)' : 'STANDBY',
    );
    _addHistoryPoint(_currentData);
    notifyListeners();

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      double currentMoisture = _currentData.soilMoisture;
      bool currentPump = _currentData.isPumpOn;

      // Jika pompa hidup, kelembapan naik. Jika pompa mati, kelembapan turun perlahan.
      if (currentPump) {
        currentMoisture += 3.5;
        if (currentMoisture > 88.0) currentMoisture = 88.0;
      } else {
        currentMoisture -= 1.8;
        if (currentMoisture < 35.0) currentMoisture = 35.0;
      }

      double temp = 28.0 + (DateTime.now().second % 5) * 0.4;
      double hum = 70.0 + (DateTime.now().second % 7) * 0.8;

      // Variasikan sedikit 3 titik sensor
      int simS1 = (3600 - (currentMoisture / 100.0 * 2400) + 60).round().clamp(1200, 3600);
      int simS2 = (3600 - (currentMoisture / 100.0 * 2400)).round().clamp(1200, 3600);
      int simS3 = (3600 - (currentMoisture / 100.0 * 2400) - 60).round().clamp(1200, 3600);

      final simulatedData = SensorData(
        soilMoisture: double.parse(currentMoisture.toStringAsFixed(1)),
        temperature: double.parse(temp.toStringAsFixed(1)),
        humidity: double.parse(hum.toStringAsFixed(1)),
        isPumpOn: currentPump,
        isAutoMode: _isAutoMode,
        hasData: true,
        hasSoilData: true,
        soil1Adc: simS1,
        soil2Adc: simS2,
        soil3Adc: simS3,
        soil1Percent: SensorData.adcToPercent(simS1),
        soil2Percent: SensorData.adcToPercent(simS2),
        soil3Percent: SensorData.adcToPercent(simS3),
        isDeviceOnline: true,
        lastPacketTime: DateTime.now(),
        pumpStatusText: currentPump ? 'MENYIRAM (SIMULASI)' : 'STANDBY',
      );

      _processIncomingSensorData(simulatedData);
    });
  }

  void stopSimulation() {
    _isSimulationActive = false;
    _simulationTimer?.cancel();
    _currentData = SensorData.empty();
    notifyListeners();
    connectMqtt();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _stateSubscription?.cancel();
    _simulationTimer?.cancel();
    _watchdogTimer?.cancel();
    _disruptionAlertController.close();
    _mqttService.dispose();
    super.dispose();
  }
}
