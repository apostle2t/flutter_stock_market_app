import 'package:flutter/foundation.dart';

/// A single match from the symbol-search endpoint. Lightweight on purpose —
/// the full quote is fetched only once the user taps through to a result.
@immutable
class SearchResult {
  const SearchResult({
    required this.symbol,
    required this.name,
    required this.exchange,
  });

  final String symbol;
  final String name;
  final String exchange;

  /// Builds a result from a Financial Modeling Prep `/search-symbol` element.
  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        symbol: (json['symbol'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        exchange: (json['exchange'] ?? '').toString(),
      );
}
