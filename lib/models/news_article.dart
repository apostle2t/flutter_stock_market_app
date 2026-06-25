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
    this.imageUrl,
    this.url,
  });

  /// Builds an article from a Finnhub `/news` (or `/company-news`) element.
  ///
  /// The API carries no brand colour, so the caller supplies one ([accentColor])
  /// — typically cycled through the palette so the feed stays varied.
  factory NewsArticle.fromFinnhub(
    Map<String, dynamic> json, {
    required Color accentColor,
  }) {
    // Finnhub gives a Unix timestamp (seconds) in `datetime`.
    final seconds = (json['datetime'] is num)
        ? (json['datetime'] as num).toInt()
        : 0;
    final published = seconds > 0
        ? DateTime.fromMillisecondsSinceEpoch(seconds * 1000)
        : null;
    final image = (json['image'] ?? '').toString();
    // Finnhub substitutes a generic source-logo image (e.g. reuters_logo.jpeg)
    // when an article has no real photo — treat those as "no image".
    final isGenericLogo = image.contains('/finnhub/logo/');
    return NewsArticle(
      title: (json['headline'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      timeAgo: published == null ? '' : Formatters.timeAgo(published),
      accentColor: accentColor,
      imageUrl: (image.isEmpty || isGenericLogo) ? null : image,
      url: (json['url'] ?? '').toString().isEmpty
          ? null
          : json['url'].toString(),
    );
  }

  final String title;
  final String summary;
  final String source;
  final String timeAgo;

  /// Accent colour used for the placeholder thumbnail when [imageUrl] is null.
  final Color accentColor;

  /// Optional headline image URL (Finnhub provides these).
  final String? imageUrl;

  /// Optional link to the full article (opened when the card is tapped).
  final String? url;
}
