import 'package:flutter_test/flutter_test.dart';
import 'package:allimation/models/sensor_data.dart';

void main() {
  test('SensorData moisture status logic test', () {
    final dryData = SensorData(soilMoisture: 45.0, temperature: 28.0, humidity: 70.0, isPumpOn: true);
    expect(dryData.moistureStatus, MoistureStatus.dry);

    final optimalData = SensorData(soilMoisture: 70.0, temperature: 28.0, humidity: 70.0, isPumpOn: false);
    expect(optimalData.moistureStatus, MoistureStatus.optimal);

    final wetData = SensorData(soilMoisture: 85.0, temperature: 28.0, humidity: 70.0, isPumpOn: false);
    expect(wetData.moistureStatus, MoistureStatus.wet);
  });
}
