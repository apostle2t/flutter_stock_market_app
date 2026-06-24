import 'package:flutter/material.dart';

import '../config.dart';
import '../models/holding.dart';
import '../models/market_index.dart';
import '../models/news_article.dart';
import '../models/stock.dart';
import '../theme/app_colors.dart';
import '../services/fmp_client.dart';
import 'mock_data.dart';

/// High-level data source for the app. Talks to [FmpClient] when a key is
/// configured and live data is enabled, and transparently falls back to
/// [MockData] on any failure so the UI is never left empty.
///
/// The free FMP tier only allows single-symbol quotes, so quotes/sparklines
/// are fetched one symbol at a time and cached per symbol for the lifetime of
/// the app session to stay within the daily request budget.
class StockRepository {
  StockRepository({FmpClient? client}) : _client = client ?? FmpClient();

  final FmpClient _client;

  /// Per-symbol fetch cache (deduplicates the same ticker across screens and
  /// across concurrent calls). Cleared by [refresh].
  final Map<String, Future<Stock>> _stockCache = {};

  /// Default watchlist used by the Home / Local tabs.
  static const List<String> defaultSymbols = [
    'AAPL',
    'MSFT',
    'NVDA',
    'TSLA',
    'GOOGL',
  ];

  /// Index symbols and the friendly names shown on the cards.
  static const Map<String, String> _indexNames = {
    '^GSPC': 'S&P 500',
    '^IXIC': 'NASDAQ',
    'BTCUSD': 'Bitcoin',
  };

  /// Palette cycled through news cards (the API carries no brand colour).
  static const List<Color> _newsAccents = [
    AppColors.primary,
    AppColors.accent,
    AppColors.positive,
    AppColors.gold,
    AppColors.negative,
  ];

  bool get _live => ApiConfig.useLiveData && _client.hasKey;

  /// Drops cached quotes so the next fetch hits the network again.
  void refresh() => _stockCache.clear();

  /// Quotes + sparklines for [symbols] (defaults to [defaultSymbols]).
  Future<List<Stock>> fetchStocks([List<String>? symbols]) {
    final syms = symbols ?? defaultSymbols;
    if (!_live) return Future.value(_mockStocks(syms));
    return Future.wait(syms.map(_stockFor));
  }

  /// Returns a single symbol's [Stock], using the session cache when present.
  Future<Stock> _stockFor(String symbol) =>
      _stockCache[symbol] ??= _fetchStock(symbol);

  Future<Stock> _fetchStock(String symbol) async {
    try {
      final quotes = await _client.getList('quote', query: {'symbol': symbol});
      final quote = quotes
          .whereType<Map<String, dynamic>>()
          .cast<Map<String, dynamic>?>()
          .firstWhere((q) => q != null, orElse: () => null);
      if (quote == null) return _mockStock(symbol);
      final sparkline = await _sparkline(symbol);
      return Stock.fromQuote(quote, sparkline: sparkline);
    } catch (e) {
      debugPrint('fetchStock($symbol) failed, using mock data: $e');
      return _mockStock(symbol);
    }
  }

  /// Recent market news for [symbols].
  ///
  /// The news endpoint is paid-only on the free tier; on failure this returns
  /// bundled headlines so the feed is never empty.
  Future<List<NewsArticle>> fetchNews([List<String>? symbols]) async {
    if (!_live) return MockData.news;
    final syms = symbols ?? defaultSymbols;
    try {
      final rows = await _client.getList(
        'news/stock',
        query: {'symbols': syms.join(','), 'limit': '20'},
      );
      final articles = <NewsArticle>[];
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row is Map<String, dynamic>) {
          articles.add(NewsArticle.fromJson(
            row,
            accentColor: _newsAccents[i % _newsAccents.length],
          ));
        }
      }
      return articles.isEmpty ? MockData.news : articles;
    } catch (e) {
      debugPrint('fetchNews failed, using mock data: $e');
      return MockData.news;
    }
  }

  /// The user's holdings with each position's stock quote refreshed live.
  ///
  /// Position sizes (market value) are a portfolio concept the market API has
  /// no knowledge of, so those stay as configured in [MockData.holdings];
  /// only the underlying price / % change is updated from the network.
  Future<List<Holding>> fetchHoldings() async {
    final symbols = MockData.holdings.map((h) => h.stock.symbol).toList();
    final stocks = await fetchStocks(symbols);
    final bySymbol = {for (final s in stocks) s.symbol: s};
    return [
      for (final holding in MockData.holdings)
        Holding(
          stock: bySymbol[holding.stock.symbol] ?? holding.stock,
          marketValue: holding.marketValue,
        ),
    ];
  }

  /// Market index summary cards (S&P 500, NASDAQ, Bitcoin).
  Future<List<MarketIndex>> fetchIndices() async {
    if (!_live) return MockData.marketIndices;
    try {
      final results = await Future.wait(
        _indexNames.entries.map(_fetchIndex),
      );
      final indices = results.whereType<MarketIndex>().toList();
      return indices.isEmpty ? MockData.marketIndices : indices;
    } catch (e) {
      debugPrint('fetchIndices failed, using mock data: $e');
      return MockData.marketIndices;
    }
  }

  Future<MarketIndex?> _fetchIndex(MapEntry<String, String> entry) async {
    try {
      final quotes =
          await _client.getList('quote', query: {'symbol': entry.key});
      final quote = quotes.whereType<Map<String, dynamic>>().toList();
      if (quote.isEmpty) return null;
      final sparkline = await _sparkline(entry.key);
      return MarketIndex.fromQuote(
        quote.first,
        displayName: entry.value,
        sparkline: sparkline,
      );
    } catch (e) {
      debugPrint('fetchIndex(${entry.key}) failed: $e');
      return null;
    }
  }

  /// Fetches ~30 closing prices for [symbol] as a normalised sparkline.
  /// Returns an empty list on failure (the model substitutes a flat line).
  Future<List<double>> _sparkline(String symbol) async {
    try {
      final rows = await _client.getList(
        'historical-price-eod/light',
        query: {'symbol': symbol},
      );
      final prices = <double>[
        for (final row in rows.whereType<Map<String, dynamic>>().take(30))
          if (row['price'] is num) (row['price'] as num).toDouble(),
      ];
      // FMP returns newest-first; charts want oldest-to-newest.
      return prices.reversed.toList();
    } catch (_) {
      return const [];
    }
  }

  List<Stock> _mockStocks(List<String> symbols) {
    return [for (final symbol in symbols) _mockStock(symbol)];
  }

  Stock _mockStock(String symbol) {
    return MockData.trendingStocks.firstWhere(
      (s) => s.symbol == symbol,
      orElse: () => MockData.trendingStocks.first,
    );
  }
}

/// Shared app-wide instance for simple use in `FutureBuilder`s.
final StockRepository stockRepository = StockRepository();
