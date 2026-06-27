import 'package:flutter/material.dart';

import '../config.dart';
import '../models/holding.dart';
import '../models/market_index.dart';
import '../models/news_article.dart';
import '../models/search_result.dart';
import '../models/stock.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../services/finnhub_client.dart';
import '../services/fmp_client.dart';
import '../services/yahoo_client.dart';
import 'mock_data.dart';
import 'region_markets.dart';

/// Real "Key Information" stats for the detail screen. Fields are null when a
/// value isn't available from the free data sources (so the UI can hide them
/// rather than show blanks).
class KeyStats {
  const KeyStats({
    this.marketCap,
    this.peRatio,
    this.volume,
    this.high52,
    this.low52,
  });

  final String? marketCap;
  final String? peRatio;
  final String? volume;
  final String? high52;
  final String? low52;

  /// Display-ready (label, value) rows, omitting any missing field.
  List<(String, String)> get rows => [
        if (marketCap != null) ('Market Cap', marketCap!),
        if (peRatio != null) ('P/E Ratio', peRatio!),
        if (volume != null) ('Volume', volume!),
        if (high52 != null) ('52W High', high52!),
        if (low52 != null) ('52W Low', low52!),
      ];
}

/// High-level data source for the app. Talks to [FmpClient] when a key is
/// configured and live data is enabled, and transparently falls back to
/// [MockData] on any failure so the UI is never left empty.
///
/// The free FMP tier only allows single-symbol quotes, so quotes/sparklines
/// are fetched one symbol at a time and cached per symbol for the lifetime of
/// the app session to stay within the daily request budget.
class StockRepository {
  StockRepository({
    FmpClient? client,
    FinnhubClient? newsClient,
    YahooClient? regionClient,
  })  : _client = client ?? FmpClient(),
        _newsClient = newsClient ?? FinnhubClient(),
        _regionClient = regionClient ?? YahooClient();

  final FmpClient _client;
  final FinnhubClient _newsClient;
  final YahooClient _regionClient;

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

  /// Live quotes + sparklines for a region's watchlist, fetched from Yahoo
  /// (which — unlike FMP's free tier — covers global symbols). Each entry's
  /// display [RegionStock.symbol]/[RegionStock.name] are kept; only the price
  /// data comes from the network. Falls back to the bundled US stocks if every
  /// lookup fails.
  Future<List<Stock>> fetchRegionStocks(List<RegionStock> entries) async {
    final results = await Future.wait(entries.map((entry) async {
      final quote = await _regionClient.fetchQuote(entry.yahooSymbol);
      if (quote == null) return null;
      return Stock(
        symbol: entry.symbol,
        name: entry.name,
        price: quote.price,
        changePercent: quote.changePercent,
        sparkline: quote.sparkline,
        yahooSymbol: entry.yahooSymbol,
      );
    }));
    final stocks = results.whereType<Stock>().toList();
    return stocks.isEmpty ? _mockStocks(defaultSymbols) : stocks;
  }

  /// Real key statistics for the detail screen.
  ///
  /// Region stocks (those with a [Stock.yahooSymbol]) use Yahoo's chart meta
  /// (volume + 52-week range; market cap / P/E aren't freely available there).
  /// US-style tickers use Finnhub's metrics (P/E + market cap + 52-week range)
  /// plus the volume already on the quote.
  Future<KeyStats> fetchKeyStats(Stock stock) async {
    if (stock.yahooSymbol != null) {
      final meta = await _regionClient.fetchMeta(stock.chartSymbol);
      if (meta == null) return const KeyStats();
      return KeyStats(
        volume: meta.volume == null ? null : Formatters.compact(meta.volume!),
        high52:
            meta.high52 == null ? null : Formatters.money(meta.high52!, meta.currency),
        low52:
            meta.low52 == null ? null : Formatters.money(meta.low52!, meta.currency),
      );
    }

    final json = await _newsClient.getJson(
      'stock/metric',
      query: {'symbol': stock.symbol, 'metric': 'all'},
    );
    final metric = json?['metric'];
    String? pe, marketCap, high52, low52;
    if (metric is Map<String, dynamic>) {
      final peVal = (metric['peTTM'] as num?)?.toDouble();
      pe = peVal?.toStringAsFixed(1);
      // Finnhub reports market cap in millions.
      final mc = (metric['marketCapitalization'] as num?)?.toDouble();
      marketCap = mc == null ? null : Formatters.compactCurrency(mc * 1e6);
      final h = (metric['52WeekHigh'] as num?)?.toDouble();
      final l = (metric['52WeekLow'] as num?)?.toDouble();
      high52 = h == null ? null : Formatters.currency(h);
      low52 = l == null ? null : Formatters.currency(l);
    }
    String? orNull(String s) => s.isEmpty ? null : s;
    return KeyStats(
      marketCap: marketCap ?? orNull(stock.marketCap),
      peRatio: pe,
      volume: orNull(stock.volume),
      high52: high52 ?? orNull(stock.high52Week),
      low52: low52 ?? orNull(stock.low52Week),
    );
  }

  /// Historical close series for [yahooSymbol] over a Yahoo [range]/[interval],
  /// used by the detail chart's time-frame switcher.
  Future<List<double>> fetchChartHistory(
    String yahooSymbol, {
    required String range,
    required String interval,
  }) =>
      _regionClient.fetchHistory(yahooSymbol, range: range, interval: interval);

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
