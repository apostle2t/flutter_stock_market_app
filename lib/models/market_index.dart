import 'package:flutter/material.dart';

/// A market index summary card (e.g. S&P 500, NASDAQ, Bitcoin).
@immutable
class MarketIndex {
  const MarketIndex({
    required this.name,
    required this.changePercent,
    required this.sparkline,
  });

  /// Builds an index from a Financial Modeling Prep `/quote` element.
  /// [displayName] overrides the API name (e.g. `^GSPC` → `S&P 500`).
  factory MarketIndex.fromQuote(
    Map<String, dynamic> json, {
    String? displayName,
    List<double> sparkline = const [],
  }) {
    final raw = json['changePercentage'] ?? json['changesPercentage'];
    final percent =
        raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    return MarketIndex(
      name: displayName ?? (json['name'] ?? json['symbol'] ?? '').toString(),
      changePercent: percent,
      sparkline: sparkline.isNotEmpty ? sparkline : [percent, percent],
    );
  }

  final String name;
  final double changePercent;
  final List<double> sparkline;

  bool get isPositive => changePercent >= 0;

  /// Returns a copy with the given fields replaced.
  MarketIndex copyWith({double? changePercent, List<double>? sparkline}) =>
      MarketIndex(
        name: name,
        changePercent: changePercent ?? this.changePercent,
        sparkline: sparkline ?? this.sparkline,
      );
}
