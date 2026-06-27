import 'package:flutter/material.dart';

import '../utils/formatters.dart';

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
    this.yahooSymbol,
  });

  /// Builds a [Stock] from a Financial Modeling Prep `/quote` element.
  ///
  /// [sparkline] is fetched separately (from the historical endpoint); when it
  /// is empty a flat two-point line keeps charts from throwing.
  factory Stock.fromQuote(
    Map<String, dynamic> json, {
    List<double> sparkline = const [],
  }) {
    final price = _toDouble(json['price']);
    return Stock(
      symbol: (json['symbol'] ?? '').toString(),
      name: (json['name'] ?? json['symbol'] ?? '').toString(),
      price: price,
      changePercent:
          _toDouble(json['changePercentage'] ?? json['changesPercentage']),
      sparkline: sparkline.isNotEmpty ? sparkline : [price, price],
      marketCap: json['marketCap'] == null
          ? ''
          : Formatters.compactCurrency(_toDouble(json['marketCap'])),
      peRatio: json['pe'] == null ? '' : _toDouble(json['pe']).toStringAsFixed(1),
      volume: json['volume'] == null
          ? ''
          : Formatters.compact(_toDouble(json['volume'])),
      high52Week: json['yearHigh'] == null
          ? ''
          : Formatters.currency(_toDouble(json['yearHigh'])),
      low52Week: json['yearLow'] == null
          ? ''
          : Formatters.currency(_toDouble(json['yearLow'])),
    );
  }

  /// Returns a copy with the given fields replaced.
  Stock copyWith({
    double? price,
    double? changePercent,
    List<double>? sparkline,
  }) =>
      Stock(
        symbol: symbol,
        name: name,
        price: price ?? this.price,
        changePercent: changePercent ?? this.changePercent,
        sparkline: sparkline ?? this.sparkline,
        marketCap: marketCap,
        peRatio: peRatio,
        volume: volume,
        high52Week: high52Week,
        low52Week: low52Week,
        yahooSymbol: yahooSymbol,
      );

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  final String symbol;
  final String name;
  final double price;

  /// Day change as a percentage, e.g. `1.24` or `-0.83`.
  final double changePercent;

  /// Normalised price points used to render the mini/large line charts.
  final List<double> sparkline;

  /// Yahoo symbol used to fetch historical chart data (e.g. `SAP.DE`). Null for
  /// US tickers, where [symbol] already works on Yahoo.
  final String? yahooSymbol;

  /// The symbol to query Yahoo's chart endpoint with.
  String get chartSymbol => yahooSymbol ?? symbol;

  // Key information (display-ready strings).
  final String marketCap;
  final String peRatio;
  final String volume;
  final String high52Week;
  final String low52Week;

  bool get isPositive => changePercent >= 0;
}
