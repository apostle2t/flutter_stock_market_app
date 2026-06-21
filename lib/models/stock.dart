import 'package:flutter/material.dart';

/// A tradable equity with quote data and the metadata shown on the detail
/// screen.
@immutable
class Stock {
  const Stock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.sparkline,
    this.marketCap = '',
    this.peRatio = '',
    this.volume = '',
    this.high52Week = '',
    this.low52Week = '',
  });

  final String symbol;
  final String name;
  final double price;

  /// Day change as a percentage, e.g. `1.24` or `-0.83`.
  final double changePercent;

  /// Normalised price points used to render the mini/large line charts.
  final List<double> sparkline;

  // Key information (display-ready strings).
  final String marketCap;
  final String peRatio;
  final String volume;
  final String high52Week;
  final String low52Week;

  bool get isPositive => changePercent >= 0;
}
