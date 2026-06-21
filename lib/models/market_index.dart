import 'package:flutter/material.dart';

/// A market index summary card (e.g. S&P 500, NASDAQ, Bitcoin).
@immutable
class MarketIndex {
  const MarketIndex({
    required this.name,
    required this.changePercent,
    required this.sparkline,
  });

  final String name;
  final double changePercent;
  final List<double> sparkline;

  bool get isPositive => changePercent >= 0;
}
