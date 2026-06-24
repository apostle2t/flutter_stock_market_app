import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// A market news headline shown in the News feed and on stock detail pages.
@immutable
class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.summary,
    required this.source,
    required this.timeAgo,
    required this.accentColor,
  });

  /// Builds an article from a Financial Modeling Prep `/stock_news` element.
  ///
  /// The API carries no brand colour, so the caller supplies one ([accentColor])
  /// — typically cycled through the palette so the feed stays varied.
  factory NewsArticle.fromJson(
    Map<String, dynamic> json, {
    required Color accentColor,
  }) {
    final published = DateTime.tryParse((json['publishedDate'] ?? '').toString());
    return NewsArticle(
      title: (json['title'] ?? '').toString(),
      summary: (json['text'] ?? '').toString(),
      source: (json['site'] ?? '').toString(),
      timeAgo: published == null ? '' : Formatters.timeAgo(published),
      accentColor: accentColor,
    );
  }

  final String title;
  final String summary;
  final String source;
  final String timeAgo;

  /// Accent colour used for the placeholder thumbnail (no network assets).
  final Color accentColor;
}
