import 'package:flutter/material.dart';

import '../../data/stock_repository.dart';
import '../../models/market_index.dart';
import '../../models/stock.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/async_data.dart';
import '../../widgets/change_badge.dart';
import '../../widgets/live_index.dart';
import '../../widgets/live_stock.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sparkline_chart.dart';
import '../../widgets/stock_list_tile.dart';
import '../search/search_screen.dart';
import '../stock_detail/stock_detail_screen.dart';

/// Dashboard tab: greeting, search, market indices and trending stocks.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<List<MarketIndex>> _indicesFuture;
  late final Future<List<Stock>> _stocksFuture;

  @override
  void initState() {
    super.initState();
    _indicesFuture = stockRepository.fetchIndices();
    _stocksFuture = stockRepository.fetchStocks();
  }

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
          _buildSearchBar(context),
          const SizedBox(height: 24),
          AsyncData<List<MarketIndex>>(
            future: _indicesFuture,
            loadingHeight: 118,
            builder: (context, indices) => SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: indices.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) => LiveIndex(
                  initial: indices[index],
                  builder: (context, idx) => _MarketIndexCard(index: idx),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Trending Stocks', actionLabel: 'See all'),
          const SizedBox(height: 4),
          AsyncData<List<Stock>>(
            future: _stocksFuture,
            builder: (context, stocks) => Column(
              children: [
                ...stocks.map(
                  (stock) => LiveStock(
                    initial: stock,
                    builder: (context, s) => StockListTile(
                      stock: s,
                      onTap: () => _openStock(context, s),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.currency(s.price),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ChangeBadge(changePercent: s.changePercent),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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

  Widget _buildSearchBar(BuildContext context) {
    // The field is display-only here; tapping it opens the dedicated search
    // screen where the actual typing/querying happens.
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
      ),
      child: AbsorbPointer(
        child: TextField(
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Search stocks, companies...',
            prefixIcon:
                Icon(Icons.search_rounded, color: AppColors.textTertiary),
          ),
        ),
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
