import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';

class TrendChart extends StatelessWidget {
  final List<SensorData> history;
  final double minThreshold; // 60.0%
  final double maxThreshold; // 80.0%

  const TrendChart({
    super.key,
    required this.history,
    this.minThreshold = 60.0,
    this.maxThreshold = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.show_chart_rounded, color: Colors.white38, size: 32),
            SizedBox(height: 8),
            Text(
              'Belum ada data tren',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 2),
            Text(
              'Grafik akan terbentuk saat prototype ESP32 mengirim data',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i].soilMoisture));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.show_chart_rounded,
                        color: Color(0xFF38BDF8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Tren Kelembapan (%)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendDot(const Color(0xFFE53935), 'Min 60%'),
                  const SizedBox(width: 8),
                  _buildLegendDot(const Color(0xFF0288D1), 'Max 80%'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    if (value == minThreshold) {
                      return FlLine(
                        color: const Color(0xFFE53935).withValues(alpha: 0.7),
                        strokeWidth: 1.5,
                        dashArray: [5, 5],
                      );
                    }
                    if (value == maxThreshold) {
                      return FlLine(
                        color: const Color(0xFF0288D1).withValues(alpha: 0.7),
                        strokeWidth: 1.5,
                        dashArray: [5, 5],
                      );
                    }
                    return FlLine(
                      color: Colors.white.withValues(alpha: 0.05),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (spots.length / 4).clamp(1.0, 10.0),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < history.length) {
                          final timeStr = DateFormat('HH:mm:ss').format(history[idx].timestamp);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white38,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 20,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF00E676),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00E676).withValues(alpha: 0.3),
                          const Color(0xFF00E676).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}
