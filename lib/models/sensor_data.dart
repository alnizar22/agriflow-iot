import 'dart:convert';

class SensorData {
  final double soilMoisture; // Kelembapan Tanah Rata-rata (%)
  final double temperature;  // Suhu Udara (°C)
  final double humidity;     // Kelembapan Udara (%)
  final bool isPumpOn;       // Status Pompa Air (ON/OFF)
  final bool isAutoMode;     // Mode Otomatisasi Irigasi (True = Auto, False = Manual)
  final DateTime timestamp;  // Waktu penerimaan data
  final int? rawSoilAdc;     // Nilai ADC Rata-rata ESP32 (0 - 4095)
  final String? pumpStatusText; // Status riil dari topik skripsi/nizar/pompa ESP32
  final bool hasData;        // True jika data riil dari hardware/simulasi sudah diterima
  final bool hasSoilData;    // True jika pembacaan sensor tanah spesifik sudah diterima

  // --- Properti Revisi Pasca-Semhas (Detail 3 Sensor & Status Koneksi) ---
  final int? soil1Adc;
  final int? soil2Adc;
  final int? soil3Adc;
  final double? soil1Percent;
  final double? soil2Percent;
  final double? soil3Percent;
  final bool isDeviceOnline; // True jika status LWT ONLINE & data masih aktif diterima
  final DateTime? lastPacketTime; // Waktu terakhir payload sensor diterima (watchdog)

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
    this.soil1Adc,
    this.soil2Adc,
    this.soil3Adc,
    this.soil1Percent,
    this.soil2Percent,
    this.soil3Percent,
    this.isDeviceOnline = false,
    this.lastPacketTime,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Rumus kalibrasi ADC ESP32 12-bit (3600 ADC kering -> 0%, 1200 ADC basah -> 100%)
  static double adcToPercent(num adc) {
    final percent = ((3600.0 - adc) / (3600.0 - 1200.0)) * 100.0;
    return double.parse(percent.clamp(0.0, 100.0).toStringAsFixed(1));
  }

  /// Factory untuk mengurai payload JSON dari HiveMQ broker (termasuk soil_detail)
  factory SensorData.fromJson(Map<String, dynamic> json) {
    final hasSoil = json.containsKey('kelembapan') ||
        json.containsKey('soilMoisture') ||
        json.containsKey('soil_moisture') ||
        json.containsKey('kelembapan_tanah') ||
        json.containsKey('rawSoilAdc') ||
        json.containsKey('raw_adc') ||
        json.containsKey('avg') ||
        json.containsKey('s1');

    final int? s1 = json['s1'] ?? json['soil1Adc'] ?? json['soil1_adc'];
    final int? s2 = json['s2'] ?? json['soil2Adc'] ?? json['soil2_adc'];
    final int? s3 = json['s3'] ?? json['soil3Adc'] ?? json['soil3_adc'];

    final double? s1P = json['soil1Percent'] != null
        ? (json['soil1Percent'] as num).toDouble()
        : (s1 != null ? adcToPercent(s1) : null);
    final double? s2P = json['soil2Percent'] != null
        ? (json['soil2Percent'] as num).toDouble()
        : (s2 != null ? adcToPercent(s2) : null);
    final double? s3P = json['soil3Percent'] != null
        ? (json['soil3Percent'] as num).toDouble()
        : (s3 != null ? adcToPercent(s3) : null);

    final int? avgAdc = json['avg'] ?? json['rawSoilAdc'] ?? json['raw_adc'] ?? json['soil_adc'];

    double calculatedMoisture = (json['kelembapan'] ?? json['soilMoisture'] ?? json['soil_moisture'] ?? json['kelembapan_tanah'] ?? 0.0).toDouble();
    if (calculatedMoisture == 0.0 && avgAdc != null) {
      calculatedMoisture = adcToPercent(avgAdc);
    }

    return SensorData(
      soilMoisture: calculatedMoisture,
      temperature: (json['temperature'] ?? json['temp'] ?? json['suhu'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? json['kelembapan_udara'] ?? 0.0).toDouble(),
      isPumpOn: json['isPumpOn'] ?? json['pump_status'] ?? json['pompa'] ?? false,
      isAutoMode: json['isAutoMode'] ?? json['auto_mode'] ?? true,
      rawSoilAdc: avgAdc,
      pumpStatusText: json['pumpStatusText'] ?? json['pump_text'],
      hasData: true,
      hasSoilData: hasSoil,
      soil1Adc: s1,
      soil2Adc: s2,
      soil3Adc: s3,
      soil1Percent: s1P,
      soil2Percent: s2P,
      soil3Percent: s3P,
      isDeviceOnline: json['isDeviceOnline'] ?? true,
      lastPacketTime: json['lastPacketTime'] != null
          ? DateTime.tryParse(json['lastPacketTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
      'soil1Adc': soil1Adc,
      'soil2Adc': soil2Adc,
      'soil3Adc': soil3Adc,
      'soil1Percent': soil1Percent,
      'soil2Percent': soil2Percent,
      'soil3Percent': soil3Percent,
      'isDeviceOnline': isDeviceOnline,
      'lastPacketTime': lastPacketTime?.toIso8601String(),
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
    int? soil1Adc,
    int? soil2Adc,
    int? soil3Adc,
    double? soil1Percent,
    double? soil2Percent,
    double? soil3Percent,
    bool? isDeviceOnline,
    DateTime? lastPacketTime,
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
      soil1Adc: soil1Adc ?? this.soil1Adc,
      soil2Adc: soil2Adc ?? this.soil2Adc,
      soil3Adc: soil3Adc ?? this.soil3Adc,
      soil1Percent: soil1Percent ?? this.soil1Percent,
      soil2Percent: soil2Percent ?? this.soil2Percent,
      soil3Percent: soil3Percent ?? this.soil3Percent,
      isDeviceOnline: isDeviceOnline ?? this.isDeviceOnline,
      lastPacketTime: lastPacketTime ?? this.lastPacketTime,
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
      soil1Adc: null,
      soil2Adc: null,
      soil3Adc: null,
      soil1Percent: null,
      soil2Percent: null,
      soil3Percent: null,
      isDeviceOnline: false,
      lastPacketTime: null,
      timestamp: DateTime.now(),
    );
  }

  static SensorData defaultInitial() => empty();
}

enum MoistureStatus { dry, optimal, wet }
