import 'package:flutter/material.dart';

import '../../data/stock_repository.dart';
import '../../models/news_article.dart';
import '../../theme/app_colors.dart';
import '../../widgets/async_data.dart';
import '../../widgets/news_card.dart';

/// News tab: a scrollable feed of market headlines.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final Future<List<NewsArticle>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = stockRepository.fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Market News',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AsyncData<List<NewsArticle>>(
            future: _newsFuture,
            loadingHeight: 240,
            builder: (context, articles) => Column(
              children: [
                for (var i = 0; i < articles.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  NewsCard(article: articles[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
