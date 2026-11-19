import 'dart:convert';

class SensorData {
  final double soilMoisture; // Kelembapan Tanah (%)
  final double temperature;  // Suhu Udara (°C)
  final double humidity;     // Kelembapan Udara (%)
  final bool isPumpOn;       // Status Pompa Air (ON/OFF)
  final bool isAutoMode;     // Mode Otomatisasi Irigasi (True = Auto, False = Manual)
  final DateTime timestamp;  // Waktu penerimaan data
  final int? rawSoilAdc;     // Nilai ADC Asli ESP32 (0 - 4095)
  final String? pumpStatusText; // Status riil dari topik skripsi/nizar/pompa ESP32
  final bool hasData;        // True jika data riil dari hardware/simulasi sudah diterima
  final bool hasSoilData;    // True jika pembacaan sensor tanah spesifik sudah diterima

  SensorData({
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.isPumpOn,
    this.isAutoMode = true,
    this.rawSoilAdc,
    this.pumpStatusText,
    this.hasData = true,
    this.hasSoilData = true,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Factory untuk mengurai payload JSON dari HiveMQ broker
  factory SensorData.fromJson(Map<String, dynamic> json) {
    final hasSoil = json.containsKey('kelembapan') ||
        json.containsKey('soilMoisture') ||
        json.containsKey('soil_moisture') ||
        json.containsKey('kelembapan_tanah') ||
        json.containsKey('rawSoilAdc') ||
        json.containsKey('raw_adc');

    return SensorData(
      soilMoisture: (json['kelembapan'] ?? json['soilMoisture'] ?? json['soil_moisture'] ?? json['kelembapan_tanah'] ?? 0.0).toDouble(),
      temperature: (json['temperature'] ?? json['temp'] ?? json['suhu'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? json['kelembapan_udara'] ?? 0.0).toDouble(),
      isPumpOn: json['isPumpOn'] ?? json['pump_status'] ?? json['pompa'] ?? false,
      isAutoMode: json['isAutoMode'] ?? json['auto_mode'] ?? true,
      rawSoilAdc: json['rawSoilAdc'] ?? json['raw_adc'] ?? json['soil_adc'],
      pumpStatusText: json['pumpStatusText'] ?? json['pump_text'],
      hasData: true,
      hasSoilData: hasSoil,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Evaluasi status kelembapan tanah sesuai spesifikasi skripsi:
  /// < 60% : Kering (Memerlukan irigasi / Pop-up Peringatan Kritis)
  /// 60% - 80% : Optimal (Kondisi ideal tanah bawang)
  /// > 80% : Basah / Jenuh
  MoistureStatus get moistureStatus {
    if (soilMoisture < 60.0) {
      return MoistureStatus.dry;
    } else if (soilMoisture <= 80.0) {
      return MoistureStatus.optimal;
    } else {
      return MoistureStatus.wet;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'kelembapan': soilMoisture,
      'soilMoisture': soilMoisture,
      'temperature': temperature,
      'humidity': humidity,
      'isPumpOn': isPumpOn,
      'isAutoMode': isAutoMode,
      'rawSoilAdc': rawSoilAdc,
      'pumpStatusText': pumpStatusText,
      'hasData': hasData,
      'hasSoilData': hasSoilData,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String toRawJson() => json.encode(toJson());

  SensorData copyWith({
    double? soilMoisture,
    double? temperature,
    double? humidity,
    bool? isPumpOn,
    bool? isAutoMode,
    int? rawSoilAdc,
    String? pumpStatusText,
    bool? hasData,
    bool? hasSoilData,
    DateTime? timestamp,
  }) {
    return SensorData(
      soilMoisture: soilMoisture ?? this.soilMoisture,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      isPumpOn: isPumpOn ?? this.isPumpOn,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      rawSoilAdc: rawSoilAdc ?? this.rawSoilAdc,
      pumpStatusText: pumpStatusText ?? this.pumpStatusText,
      hasData: hasData ?? this.hasData,
      hasSoilData: hasSoilData ?? this.hasSoilData,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Kondisi awal saat aplikasi baru dibuka dan hardware prototype belum dinyalakan
  static SensorData empty() {
    return SensorData(
      soilMoisture: 0.0,
      temperature: 0.0,
      humidity: 0.0,
      isPumpOn: false,
      isAutoMode: true,
      rawSoilAdc: null,
      pumpStatusText: null,
      hasData: false,
      hasSoilData: false,
      timestamp: DateTime.now(),
    );
  }

  static SensorData defaultInitial() => empty();
}

enum MoistureStatus { dry, optimal, wet }
