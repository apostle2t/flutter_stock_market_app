import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/market_index.dart';
import '../../models/stock.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/change_badge.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sparkline_chart.dart';
import '../../widgets/stock_list_tile.dart';
import '../stock_detail/stock_detail_screen.dart';

/// Dashboard tab: greeting, search, market indices and trending stocks.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openStock(BuildContext context, Stock stock) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => StockDetailScreen(stock: stock)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 24),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: MockData.marketIndices.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) =>
                  _MarketIndexCard(index: MockData.marketIndices[index]),
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Trending Stocks', actionLabel: 'See all'),
          const SizedBox(height: 4),
          ...MockData.trendingStocks.map(
            (stock) => StockListTile(
              stock: stock,
              onTap: () => _openStock(context, stock),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(stock.price),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ChangeBadge(changePercent: stock.changePercent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: 'Search stocks, companies...',
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiary),
      ),
    );
  }
}

class _MarketIndexCard extends StatelessWidget {
  const _MarketIndexCard({required this.index});

  final MarketIndex index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index.name,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ChangeBadge(changePercent: index.changePercent, showArrow: true),
          const SizedBox(height: 8),
          Expanded(
            child: SparklineChart(
              data: index.sparkline,
              color: AppColors.forChange(index.changePercent),
            ),
          ),
        ],
      ),
    );
  }
}
