import 'dart:math';

import 'package:flutter/material.dart';

import '../services/live_price_controller.dart';
import 'sparkline_chart.dart';

/// A [SparklineChart] whose series scrolls and random-walks on every tick of
/// [LivePriceController], producing a continuously moving line.
///
/// Used for portfolio-level charts that aren't tied to a single stock quote
/// (e.g. the Portfolio Performance card). [drift] applies a gentle directional
/// bias each tick — a small positive value reads as an upward trend.
class LiveSparklineChart extends StatefulWidget {
  LiveSparklineChart({
    super.key,
    required this.initialData,
    required this.color,
    this.strokeWidth = 2,
    this.filled = false,
    this.volatility = 0.012,
    this.drift = 0.001,
  });

  final List<double> initialData;
  final Color color;
  final double strokeWidth;
  final bool filled;

  /// Maximum random move per tick, as a fraction of the last value.
  final double volatility;

  /// Constant directional bias added each tick (positive trends up).
  final double drift;

  @override
  State<LiveSparklineChart> createState() => _LiveSparklineChartState();
}

class _LiveSparklineChartState extends State<LiveSparklineChart> {
  final LivePriceController _controller = LivePriceController.instance;
  final Random _rng = Random();
  late List<double> _data;

  @override
  void initState() {
    super.initState();
    _data = List<double>.of(widget.initialData);
    _controller.addListener(_tick);
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    if (!mounted || _data.length < 2) return;
    final move = (_rng.nextDouble() - 0.5) * 2 * widget.volatility + widget.drift;
    final next = _data.last * (1 + move);
    setState(() {
      _data = [..._data.skip(1), next];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SparklineChart(
      data: _data,
      color: widget.color,
      strokeWidth: widget.strokeWidth,
      filled: widget.filled,
    );
  }
}
