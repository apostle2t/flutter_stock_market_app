import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../data/stock_repository.dart';
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
  /// Selectable chart time-frames mapped to Yahoo range/interval params.
  static const List<({String label, String range, String interval})> _ranges = [
    (label: '1D', range: '1d', interval: '5m'),
    (label: '1W', range: '5d', interval: '30m'),
    (label: '1M', range: '1mo', interval: '1d'),
    (label: '6M', range: '6mo', interval: '1d'),
    (label: '1Y', range: '1y', interval: '1d'),
    (label: '5Y', range: '5y', interval: '1wk'),
  ];

  int _selectedRange = 2; // Defaults to "1M".
  late List<double> _chartData;
  bool _chartLoading = false;
  late final Future<KeyStats> _keyStatsFuture;

  /// The live-ticking version of the stock passed in (price and change update
  /// via [LivePriceController]).
  Stock get stock => LivePriceController.instance.liveOf(widget.stock);

  /// Chart colour from the selected range's own trend (first vs last close).
  Color get _trendColor {
    if (_chartData.length < 2) return AppColors.positive;
    return _chartData.last >= _chartData.first
        ? AppColors.positive
        : AppColors.negative;
  }

  @override
  void initState() {
    super.initState();
    LivePriceController.instance.register(widget.stock);
    // The default 1M view reuses the sparkline already loaded with the stock,
    // so no extra fetch is needed until the user switches time-frame.
    _chartData = widget.stock.sparkline;
    _keyStatsFuture = stockRepository.fetchKeyStats(widget.stock);
  }

  Future<void> _selectRange(int index) async {
    setState(() {
      _selectedRange = index;
      _chartLoading = true;
    });
    final range = _ranges[index];
    final data = await stockRepository.fetchChartHistory(
      widget.stock.chartSymbol,
      range: range.range,
      interval: range.interval,
    );
    if (!mounted || index != _selectedRange) return; // superseded
    setState(() {
      _chartLoading = false;
      if (data.isNotEmpty) _chartData = data;
    });
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
          _buildChartCard(),
          const SizedBox(height: 20),
          _buildTradeButtons(),
          const SizedBox(height: 28),
          _buildKeyInformation(),
          const SizedBox(height: 28),
          Text(
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
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          Formatters.currency(stock.price),
          style: TextStyle(
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
            Text(
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
          Text(
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
            child: _chartLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : SparklineChart(
                    data: _chartData,
                    color: _trendColor,
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
        for (var i = 0; i < _ranges.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: _chartLoading ? null : () => _selectRange(i),
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
                  _ranges[i].label,
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
          Padding(
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
          FutureBuilder<KeyStats>(
            future: _keyStatsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }
              final rows = snapshot.data?.rows ?? const [];
              if (rows.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No additional information available.',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rows[i].$1,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            rows[i].$2,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
