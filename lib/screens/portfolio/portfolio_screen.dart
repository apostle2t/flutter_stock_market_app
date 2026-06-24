import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../data/stock_repository.dart';
import '../../models/holding.dart';
import '../../models/stock.dart';
import '../../services/live_price_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/async_data.dart';
import '../../widgets/live_stock.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sparkline_chart.dart';
import '../../widgets/stock_list_tile.dart';
import '../stock_detail/stock_detail_screen.dart';

/// Portfolio tab: total value, performance chart and holdings list.
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  // Each holding's stock quote is refreshed live; position sizes and the
  // portfolio-level totals/chart below stay as configured (see fetchHoldings).
  late final Future<List<Holding>> _holdingsFuture;

  @override
  void initState() {
    super.initState();
    _holdingsFuture = stockRepository.fetchHoldings();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'Portfolio',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          AsyncData<List<Holding>>(
            future: _holdingsFuture,
            loadingHeight: 420,
            builder: (context, holdings) => Column(
              children: [
                // The total recomputes from the live holdings on every tick.
                ListenableBuilder(
                  listenable: LivePriceController.instance,
                  builder: (context, _) => _buildValueCard(holdings),
                ),
                const SizedBox(height: 24),
                _buildPerformanceCard(),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SectionHeader(title: 'Your Holdings'),
                ),
                const SizedBox(height: 4),
                ...holdings.map(
                  (holding) => LiveStock(
                    initial: holding.stock,
                    builder: (context, s) {
                      final liveValue = _liveValue(holding, s);
                      return StockListTile(
                        stock: s,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => StockDetailScreen(stock: s),
                          ),
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.currency(liveValue),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A holding's live market value, scaled by how far its live price has moved
  /// from the fetched (anchor) price.
  double _liveValue(Holding holding, Stock live) {
    final base = holding.stock.price;
    return base == 0 ? holding.marketValue : holding.marketValue * (live.price / base);
  }

  Widget _buildValueCard(List<Holding> holdings) {
    final controller = LivePriceController.instance;

    // Sum the live position values and derive today's change by comparing each
    // holding's live value against its implied previous-close value.
    var total = 0.0;
    var prevCloseTotal = 0.0;
    for (final holding in holdings) {
      controller.register(holding.stock); // idempotent
      final live = controller.liveOf(holding.stock);
      final value = _liveValue(holding, live);
      total += value;
      prevCloseTotal += value / (1 + live.changePercent / 100);
    }
    final changeAmount = total - prevCloseTotal;
    final changePercent =
        prevCloseTotal == 0 ? 0.0 : changeAmount / prevCloseTotal * 100;
    final changeColor = AppColors.forChange(changeAmount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.35),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Portfolio Value',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(total),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                changeAmount >= 0
                    ? Icons.arrow_drop_up
                    : Icons.arrow_drop_down,
                color: changeColor,
                size: 22,
              ),
              Text(
                '${Formatters.signedCurrency(changeAmount)} '
                '(${Formatters.signedPercent(changePercent)}) today',
                style: TextStyle(
                  color: changeColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
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
            'Portfolio Performance',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: SparklineChart(
              data: MockData.portfolioPerformance,
              color: AppColors.positive,
              strokeWidth: 2.5,
              filled: true,
            ),
          ),
        ],
      ),
    );
  }
}
