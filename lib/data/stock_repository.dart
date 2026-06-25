import 'package:flutter/material.dart';

import '../config.dart';
import '../models/holding.dart';
import '../models/market_index.dart';
import '../models/news_article.dart';
import '../models/search_result.dart';
import '../models/stock.dart';
import '../theme/app_colors.dart';
import '../services/finnhub_client.dart';
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
  StockRepository({FmpClient? client, FinnhubClient? newsClient})
      : _client = client ?? FmpClient(),
        _newsClient = newsClient ?? FinnhubClient();

  final FmpClient _client;
  final FinnhubClient _newsClient;

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

  /// Recent general market news (from Finnhub — FMP's news is paid-only),
  /// capped at [limit] items.
  ///
  /// Only articles with a real photo are kept (Finnhub's generic source-logo
  /// placeholders are skipped) so every card shows an image. Falls back to
  /// bundled headlines when no Finnhub key is set or on failure, so the feed is
  /// never empty.
  Future<List<NewsArticle>> fetchNews({int limit = 7}) async {
    if (!ApiConfig.useLiveData || !_newsClient.hasKey) {
      return MockData.news.take(limit).toList();
    }
    try {
      final rows =
          await _newsClient.getList('news', query: {'category': 'general'});
      final articles = <NewsArticle>[];
      for (final row in rows.whereType<Map<String, dynamic>>()) {
        if ((row['headline'] ?? '').toString().isEmpty) continue;
        final article = NewsArticle.fromFinnhub(
          row,
          accentColor: _newsAccents[articles.length % _newsAccents.length],
        );
        if (article.imageUrl == null) continue; // keep only real photos
        articles.add(article);
        if (articles.length >= limit) break;
      }
      return articles.isEmpty ? MockData.news.take(limit).toList() : articles;
    } catch (e) {
      debugPrint('fetchNews failed, using mock data: $e');
      return MockData.news.take(limit).toList();
    }
  }

  /// Searches symbols/company names matching [query].
  ///
  /// Falls back to filtering the bundled stocks when offline or on error.
  Future<List<SearchResult>> searchSymbols(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    if (!_live) return _mockSearch(q);
    try {
      final rows = await _client.getList(
        'search-symbol',
        query: {'query': q, 'limit': '25'},
      );
      final results = rows
          .whereType<Map<String, dynamic>>()
          .map(SearchResult.fromJson)
          .where((r) => r.symbol.isNotEmpty)
          .toList();
      return results.isEmpty ? _mockSearch(q) : results;
    } catch (e) {
      debugPrint('searchSymbols failed, using mock data: $e');
      return _mockSearch(q);
    }
  }

  List<SearchResult> _mockSearch(String query) {
    final lower = query.toLowerCase();
    return MockData.trendingStocks
        .where((s) =>
            s.symbol.toLowerCase().contains(lower) ||
            s.name.toLowerCase().contains(lower))
        .map((s) =>
            SearchResult(symbol: s.symbol, name: s.name, exchange: ''))
        .toList();
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
