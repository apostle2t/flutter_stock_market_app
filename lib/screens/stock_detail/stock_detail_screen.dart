import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/stock.dart';
import '../../services/live_price_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/change_badge.dart';
import '../../widgets/news_card.dart';
import '../../widgets/sparkline_chart.dart';

/// Detailed view for a single stock: quote, price chart, trade actions,
/// key statistics and related news.
class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({super.key, required this.stock});

  final Stock stock;

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  int _selectedRange = 2; // Defaults to "1M".

  /// The live-ticking version of the stock passed in (price, change and
  /// sparkline update via [LivePriceController]).
  Stock get stock => LivePriceController.instance.liveOf(widget.stock);

  @override
  void initState() {
    super.initState();
    LivePriceController.instance.register(widget.stock);
  }

  void _showTradeSheet(String action) {
    final color = action == 'Buy' ? AppColors.positive : AppColors.negative;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Text('$action order placed for ${stock.symbol}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(stock.name),
        leading: const BackButton(),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.star_border_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          ListenableBuilder(
            listenable: LivePriceController.instance,
            builder: (context, _) => _buildQuoteHeader(),
          ),
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: LivePriceController.instance,
            builder: (context, _) => _buildChartCard(),
          ),
          const SizedBox(height: 20),
          _buildTradeButtons(),
          const SizedBox(height: 28),
          _buildKeyInformation(),
          const SizedBox(height: 28),
          const Text(
            'Related News',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          ...MockData.relatedNews.map((a) => NewsCard(article: a)),
        ],
      ),
    );
  }

  Widget _buildQuoteHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stock.symbol,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          Formatters.currency(stock.price),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            ChangeBadge(
              changePercent: stock.changePercent,
              showArrow: true,
              fontSize: 14,
            ),
            const SizedBox(width: 6),
            const Text(
              'Today',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Performance',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: SparklineChart(
              data: stock.sparkline,
              color: AppColors.forChange(stock.changePercent),
              strokeWidth: 2.5,
              filled: true,
            ),
          ),
          const SizedBox(height: 16),
          _buildRangeSelector(),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Row(
      children: [
        for (var i = 0; i < MockData.chartRanges.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRange = i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedRange == i
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  MockData.chartRanges[i],
                  style: TextStyle(
                    color: _selectedRange == i
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTradeButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showTradeSheet('Buy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.positive,
            ),
            child: const Text('Buy'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showTradeSheet('Sell'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
            ),
            child: const Text('Sell'),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyInformation() {
    final rows = <(String, String)>[
      ('Market Cap', stock.marketCap),
      ('P/E Ratio', stock.peRatio),
      ('Volume', stock.volume),
      ('52W High', stock.high52Week),
      ('52W Low', stock.low52Week),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              'Key Information',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].$1,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    rows[i].$2,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
