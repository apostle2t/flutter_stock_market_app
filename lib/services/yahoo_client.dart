import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A quote + sparkline parsed from Yahoo's chart endpoint.
@immutable
class YahooQuote {
  const YahooQuote({
    required this.price,
    required this.changePercent,
    required this.sparkline,
  });

  final double price;
  final double changePercent;
  final List<double> sparkline;
}

/// Key statistics pulled from Yahoo's chart `meta` (available for any symbol).
@immutable
class YahooMeta {
  const YahooMeta({
    this.currency,
    this.volume,
    this.high52,
    this.low52,
    this.dayHigh,
    this.dayLow,
  });

  final String? currency;
  final double? volume;
  final double? high52;
  final double? low52;
  final double? dayHigh;
  final double? dayLow;
}

/// Thin client over Yahoo Finance's public (unofficial) chart endpoint.
///
/// Unlike FMP's free tier, this covers global symbols — German `SAP.DE`,
/// Tokyo `7203.T`, indices like `^GDAXI`, etc. — with no API key, which is why
/// it backs the region-personalised Local feed. Note: this endpoint is
/// undocumented and could change; every call fails soft (returns null).
class YahooClient {
  YahooClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static const String _host = 'query1.finance.yahoo.com';

  final http.Client _http;

  /// Fetches the latest price, day-change % and a ~1-month daily sparkline for
  /// [symbol] (a Yahoo symbol, e.g. `SAP.DE`). Returns null on any failure.
  Future<YahooQuote?> fetchQuote(String symbol) async {
    final chart = await _fetchChart(symbol, range: '1mo', interval: '1d');
    if (chart == null) return null;

    final (closes, metaPrice) = chart;
    if (metaPrice == null && closes.isEmpty) return null;
    final price = metaPrice ?? closes.last;

    // Day change from the last two daily closes (most recent full-day move).
    var changePercent = 0.0;
    if (closes.length >= 2 && closes[closes.length - 2] != 0) {
      final prev = closes[closes.length - 2];
      changePercent = (price - prev) / prev * 100;
    }

    return YahooQuote(
      price: price,
      changePercent: changePercent,
      sparkline: closes.isEmpty ? [price, price] : closes,
    );
  }

  /// Fetches the closing-price series for [symbol] over a Yahoo [range]
  /// (e.g. `6mo`, `1y`) at the given [interval] (e.g. `1d`, `1wk`). Used to
  /// redraw the detail chart when the user switches time-frame. Empty on error.
  Future<List<double>> fetchHistory(
    String symbol, {
    required String range,
    required String interval,
  }) async {
    final chart = await _fetchChart(symbol, range: range, interval: interval);
    return chart?.$1 ?? const [];
  }

  /// Fetches key statistics (52-week range, volume, currency, day range) from
  /// the chart `meta`. Works for any symbol; returns null on failure.
  Future<YahooMeta?> fetchMeta(String symbol) async {
    try {
      final uri = Uri.https(_host, '/v8/finance/chart/$symbol', {
        'interval': '1d',
        'range': '1d',
      });
      final response = await _http.get(
        uri,
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = json['chart']?['result'];
      if (results is! List || results.isEmpty) return null;
      final meta = (results.first as Map<String, dynamic>)['meta']
          as Map<String, dynamic>?;
      if (meta == null) return null;

      double? d(String key) => (meta[key] as num?)?.toDouble();
      return YahooMeta(
        currency: meta['currency']?.toString(),
        volume: d('regularMarketVolume'),
        high52: d('fiftyTwoWeekHigh'),
        low52: d('fiftyTwoWeekLow'),
        dayHigh: d('regularMarketDayHigh'),
        dayLow: d('regularMarketDayLow'),
      );
    } catch (e) {
      debugPrint('YahooClient.fetchMeta($symbol) failed: $e');
      return null;
    }
  }

  /// Shared request + parse. Returns the non-null close series and the meta
  /// `regularMarketPrice` (if present).
  Future<(List<double>, double?)?> _fetchChart(
    String symbol, {
    required String range,
    required String interval,
  }) async {
    try {
      final uri = Uri.https(_host, '/v8/finance/chart/$symbol', {
        'interval': interval,
        'range': range,
      });
      final response = await _http.get(
        uri,
        // A browser-like UA avoids the endpoint rejecting the request.
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = json['chart']?['result'];
      if (results is! List || results.isEmpty) return null;
      final result = results.first as Map<String, dynamic>;

      final meta = result['meta'] as Map<String, dynamic>?;
      final quote = result['indicators']?['quote'];
      final rawCloses = (quote is List && quote.isNotEmpty)
          ? (quote.first as Map<String, dynamic>)['close']
          : null;

      final closes = <double>[
        for (final c in (rawCloses is List ? rawCloses : const []))
          if (c is num) c.toDouble(),
      ];
      final metaPrice = (meta?['regularMarketPrice'] as num?)?.toDouble();
      return (closes, metaPrice);
    } catch (e) {
      debugPrint('YahooClient._fetchChart($symbol, $range) failed: $e');
      return null;
    }
  }

  void close() => _http.close();
}
