import 'package:flutter/material.dart';

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

  final String title;
  final String summary;
  final String source;
  final String timeAgo;

  /// Accent colour used for the placeholder thumbnail (no network assets).
  final Color accentColor;
}
