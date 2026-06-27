
import 'package:flutter/material.dart';

import '../../data/region_markets.dart';
import '../../data/stock_repository.dart';
import '../../models/news_article.dart';
import '../../models/stock.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/async_data.dart';
import '../../widgets/change_badge.dart';
import '../../widgets/live_stock.dart';
import '../../widgets/news_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sparkline_chart.dart';
import '../../widgets/stock_list_tile.dart';
import '../stock_detail/stock_detail_screen.dart';

class LocalScreen extends StatefulWidget {
  const LocalScreen({super.key});

  @override
  State<LocalScreen> createState() => _LocalScreenState();
}

class _LocalScreenState extends State<LocalScreen> {
  // Fetched once; reused by every section so we don't hit the API twice.
  late final Future<LocationResult?> _locationFuture;
  late final Future<List<Stock>> _stocksFuture;
  late final Future<List<NewsArticle>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _locationFuture = LocationService().getCurrentLocation();
    // The region watchlist depends on the detected location, so chain it.
    _stocksFuture = _locationFuture.then(
      (location) =>
          stockRepository.fetchRegionStocks(regionFor(location?.countryCode).stocks),
    );
    _newsFuture = stockRepository.fetchNews();
  }

  void _openStock(BuildContext context, Stock stock) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => StockDetailScreen(stock: stock)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The page scrolls as a single column, mirroring the other tabs
    // (see HomeScreen) rather than living inside the AppBar.
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildInsightBanner(),
          const SizedBox(height: 28),
          _trendingInRegion(context),
          const SizedBox(height: 28),
          _localStocks(context),
          const SizedBox(height: 28),
          _trendingNews(),
        ],
      ),
    );
  }


  /// Things we need to build


// A header with the location title and a statemenet (Top gaineers)
  Widget _buildHeader(){
  /**
   * Things needed: Parent -> we are returning a column
   * - Location Icon and title (e.g. "Netherlands") in a row
   * - Some metadata about the state of the local markert (e.g. "Martket open etc")
   * - More metadata about the market (e.g. "Top gainers: ASML, Adyen, etc")
   */
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      // small overline label sitting above the location title
      const Text(
        'LOCAL',
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 8),
      // The location title + status come from the device's real location
      // (resolved to an area name), falling back to a default while loading or
      // if location is unavailable.
      FutureBuilder<LocationResult?>(
        future: _locationFuture,
        builder: (context, snapshot) {
          final loading =
              snapshot.connectionState == ConnectionState.waiting;
          final location = snapshot.data;

          final city = (location != null && location.city.isNotEmpty)
              ? location.city
              : 'New York';
          final countryCode =
              (location != null && location.countryCode.isNotEmpty)
                  ? location.countryCode
                  : 'US';
          final status = _statusLine(location);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // we need a row for the location icon and title
              Row(children: [
                const Icon(Icons.location_on,
                    color: AppColors.primary, size: 28),
                const SizedBox(width: 8),
                Text(
                  loading ? 'Locating…' : city,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                // a subtle outlined pill marking the market's country
                if (!loading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      countryCode,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),
              // we need a row widget for the market status
              Row(children: [
                const Icon(Icons.circle, color: AppColors.positive, size: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ]),
            ],
          );
        },
      ),
      ],
    );
  }

  /// A status line describing the detected market area, with a US/default
  /// fallback that matches the original design.
  String _statusLine(LocationResult? location) {
    // Show the exchanges for the detected region (e.g. XETRA · Frankfurt).
    return '${regionFor(location?.countryCode).exchangeLabel}  ·  Market open';
  }

  /// A live summary of how the region is trading, based on the fetched stocks:
  /// the overall trend plus the day's leading mover.
  String _insightMessage(List<Stock>? stocks) {
    if (stocks == null || stocks.isEmpty) {
      return 'Tracking your local market…';
    }
    final leader =
        stocks.reduce((a, b) => b.changePercent > a.changePercent ? b : a);
    final avg = stocks.map((s) => s.changePercent).reduce((a, b) => a + b) /
        stocks.length;
    final trend = avg >= 0 ? 'higher' : 'lower';
    return 'Your region is trading $trend today — ${leader.symbol} '
        'leads at ${Formatters.signedPercent(leader.changePercent)}.';
  }

  // A glowing insight banner summarising how the region is trading today.
  Widget _buildInsightBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.22),
            AppColors.primary.withValues(alpha: 0.06),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FutureBuilder<List<Stock>>(
              future: _stocksFuture,
              builder: (context, snapshot) => Text(
                _insightMessage(snapshot.data),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Trending in Region section. It should be a list which is rendered
// as a horizontal list of cards.
  Widget _trendingInRegion (BuildContext context){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Trending in your region',
          actionLabel: 'See all',
        ),
        const SizedBox(height: 12),
        AsyncData<List<Stock>>(
          future: _stocksFuture,
          loadingHeight: 168,
          builder: (context, stocks) => SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stocks.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) => LiveStock(
                initial: stocks[index],
                builder: (context, s) => _RegionCard(
                  stock: s,
                  onTap: () => _openStock(context, s),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // A dedicated stocks section for the local market.
  // It should be a list which is rendered as horizontal cards in column.
  Widget _localStocks(BuildContext context){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Stocks'),
        const SizedBox(height: 4),
        AsyncData<List<Stock>>(
          future: _stocksFuture,
          builder: (context, stocks) => Column(
            children: [
              ...stocks.map(
                (stock) => LiveStock(
                  initial: stock,
                  builder: (context, s) => Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: StockListTile(
                      stock: s,
                      onTap: () => _openStock(context, s),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 36,
                            child: SparklineChart(
                              data: s.sparkline,
                              color: AppColors.forChange(s.changePercent),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
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
                              ChangeBadge(
                                changePercent: s.changePercent,
                                showArrow: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Trending news section.
  // It should be a list which is rendered as horizontal cards in column.
  Widget _trendingNews(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Trending news'),
        const SizedBox(height: 4),
        AsyncData<List<NewsArticle>>(
          future: _newsFuture,
          builder: (context, articles) => Column(
            children: [
              ...articles.map(
                (article) => Column(
                  children: [
                    NewsCard(article: article),
                    const Divider(height: 1),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A compact card used in the "Trending in your region" horizontal carousel:
/// symbol + change on top, company name, a mini sparkline and the price.
class _RegionCard extends StatelessWidget {
  const _RegionCard({required this.stock, this.onTap});

  final Stock stock;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forChange(stock.changePercent);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  stock.symbol,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                ChangeBadge(changePercent: stock.changePercent, showArrow: true),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              stock.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 32, child: SparklineChart(data: stock.sparkline, color: color)),
            const SizedBox(height: 12),
            Text(
              Formatters.currency(stock.price),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
