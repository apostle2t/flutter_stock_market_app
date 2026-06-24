import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/stock.dart';

/// Drives a simulated "live ticker" effect on top of real fetched prices.
///
/// The free FMP tier has no streaming feed (WebSockets are a paid plan) and a
/// tight daily request budget, so polling can't produce a smooth ticker. This
/// controller instead anchors on each symbol's real fetched price and applies
/// a small random walk with gentle mean-reversion every [tickInterval], so the
/// numbers and sparklines move continuously without spending API calls.
///
/// It is a singleton: every [LiveStock] across the app reads the same value
/// for a symbol, so a ticker shows identical numbers on every screen. The
/// internal timer only runs while at least one widget is listening.
class LivePriceController extends ChangeNotifier {
  LivePriceController._();

  /// Shared app-wide instance.
  static final LivePriceController instance = LivePriceController._();

  /// How often prices tick.
  static const Duration tickInterval = Duration(milliseconds: 1200);

  /// Maximum per-tick move, as a fraction of price (±0.2%).
  static const double _maxMove = 0.002;

  /// Pull-back strength toward the real anchor price each tick.
  static const double _reversion = 0.08;

  final Map<String, Stock> _live = {};
  final Map<String, double> _anchorPrice = {};
  final Map<String, double> _prevClose = {};
  final Random _rng = Random();
  Timer? _timer;

  /// Seeds a symbol with its real fetched values the first time it is seen.
  /// Subsequent calls are ignored so the live value keeps ticking across
  /// rebuilds.
  void register(Stock stock) {
    if (_live.containsKey(stock.symbol)) return;
    _live[stock.symbol] = stock;
    _anchorPrice[stock.symbol] = stock.price;
    // Implied previous close — lets us recompute the day-change % from price.
    _prevClose[stock.symbol] =
        stock.price / (1 + stock.changePercent / 100);
  }

  /// The current simulated value for [fallback]'s symbol, or [fallback] itself
  /// if it has not been registered yet.
  Stock liveOf(Stock fallback) => _live[fallback.symbol] ?? fallback;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _timer ??= Timer.periodic(tickInterval, (_) => _tick());
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _tick() {
    if (_live.isEmpty) return;
    for (final symbol in _live.keys.toList()) {
      final stock = _live[symbol]!;
      final anchor = _anchorPrice[symbol] ?? stock.price;
      final prevClose = _prevClose[symbol] ?? stock.price;

      // Random noise plus a small pull back toward the real anchor price, so
      // the walk stays near the true value instead of drifting off.
      final noise = (_rng.nextDouble() - 0.5) * 2 * _maxMove;
      final pull = anchor == 0 ? 0.0 : (anchor - stock.price) / anchor * _reversion;
      final pctMove = noise + pull;

      final newPrice = stock.price * (1 + pctMove);
      final newChange =
          prevClose == 0 ? stock.changePercent : (newPrice / prevClose - 1) * 100;

      // Scroll the sparkline: drop the oldest point, append one scaled by the
      // same move (works whether points are real prices or normalised values).
      final spark = List<double>.from(stock.sparkline);
      if (spark.length >= 2) {
        final last = spark.last;
        spark
          ..removeAt(0)
          ..add(last * (1 + pctMove));
      }

      _live[symbol] = stock.copyWith(
        price: newPrice,
        changePercent: newChange,
        sparkline: spark,
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
