import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A compact, axis-free line chart used for mini price previews.
///
/// When [filled] is true a soft gradient is painted under the line — used for
/// the larger performance charts.
class SparklineChart extends StatelessWidget {
  const SparklineChart({
    super.key,
    required this.data,
    required this.color,
    this.strokeWidth = 2,
    this.filled = false,
  });

  final List<double> data;
  final Color color;
  final double strokeWidth;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
    ];

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: strokeWidth,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: filled,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
