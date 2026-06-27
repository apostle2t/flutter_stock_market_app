import '../models/holding.dart';
import '../models/market_index.dart';
import '../models/news_article.dart';
import '../models/stock.dart';
import '../models/subscription_plan.dart';
import '../theme/app_colors.dart';

/// Static, in-memory data source standing in for a real API.
///
/// Centralising the sample content here keeps the screens declarative and
/// makes it trivial to later swap this for a networked repository.
abstract final class MockData {
  static const List<MarketIndex> marketIndices = [
    MarketIndex(
      name: 'S&P 500',
      changePercent: 1.24,
      sparkline: [3, 3.4, 3.2, 3.8, 4.1, 3.9, 4.6, 4.4, 5.1],
    ),
    MarketIndex(
      name: 'NASDAQ',
      changePercent: 0.86,
      sparkline: [5, 4.6, 4.9, 4.4, 4.8, 5.2, 5.0, 5.6, 5.4],
    ),
    MarketIndex(
      name: 'Bitcoin',
      changePercent: -2.13,
      sparkline: [6, 5.6, 5.8, 5.2, 4.9, 5.1, 4.6, 4.4, 4.1],
    ),
  ];

  static const Stock apple = Stock(
    symbol: 'AAPL',
    name: 'Apple Inc.',
    price: 189.34,
    changePercent: 1.24,
    sparkline: [4.2, 4.4, 4.1, 4.6, 5.0, 4.7, 4.3, 4.8, 5.3, 5.1, 5.6, 5.9],
    marketCap: r'$2.9T',
    peRatio: '31.4',
    volume: '52M',
    high52Week: r'$198.20',
    low52Week: r'$164.10',
  );

  static const List<Stock> trendingStocks = [
    apple,
    Stock(
      symbol: 'TSLA',
      name: 'Tesla',
      price: 248.92,
      changePercent: 2.45,
      sparkline: [3, 3.3, 3.1, 3.6, 3.4, 3.9, 4.2, 4.0, 4.5],
      marketCap: r'$792B',
      peRatio: '68.2',
      volume: '118M',
      high52Week: r'$278.98',
      low52Week: r'$138.80',
    ),
    Stock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      price: 563.25,
      changePercent: 3.10,
      sparkline: [2.5, 2.8, 3.1, 3.0, 3.6, 3.9, 4.3, 4.6, 5.0],
      marketCap: r'$1.4T',
      peRatio: '65.1',
      volume: '41M',
      high52Week: r'$974.00',
      low52Week: r'$108.13',
    ),
    Stock(
      symbol: 'MSFT',
      name: 'Microsoft',
      price: 438.67,
      changePercent: 0.92,
      sparkline: [4, 4.2, 4.1, 4.5, 4.4, 4.7, 4.6, 4.9, 5.1],
      marketCap: r'$3.1T',
      peRatio: '37.0',
      volume: '22M',
      high52Week: r'$468.35',
      low52Week: r'$362.90',
    ),
    Stock(
      symbol: 'GOOGL',
      name: 'Google',
      price: 153.83,
      changePercent: -0.54,
      sparkline: [5, 4.8, 4.9, 4.6, 4.7, 4.4, 4.5, 4.2, 4.3],
      marketCap: r'$1.9T',
      peRatio: '27.3',
      volume: '28M',
      high52Week: r'$155.20',
      low52Week: r'$120.21',
    ),
  ];

  static const double portfolioValue = 24562.82;
  static const double portfolioChangeAmount = 1234.09;
  static const double portfolioChangePercent = 4.31;

  static const List<double> portfolioPerformance = [
    20, 20.6, 20.2, 21.1, 21.8, 21.4, 22.6, 23.1, 22.8, 23.6, 24.1, 24.56,
  ];

  static const List<Holding> holdings = [
    Holding(stock: apple, marketValue: 12340.00),
    Holding(
      stock: Stock(
        symbol: 'TSLA',
        name: 'Tesla',
        price: 248.92,
        changePercent: 2.45,
        sparkline: [3, 3.3, 3.1, 3.6, 3.4, 3.9, 4.2, 4.0, 4.5],
      ),
      marketValue: 4320.10,
    ),
    Holding(
      stock: Stock(
        symbol: 'NVDA',
        name: 'NVIDIA',
        price: 563.25,
        changePercent: 3.10,
        sparkline: [2.5, 2.8, 3.1, 3.0, 3.6, 3.9, 4.3, 4.6, 5.0],
      ),
      marketValue: 2430.20,
    ),
    Holding(
      stock: Stock(
        symbol: 'MSFT',
        name: 'Microsoft',
        price: 438.67,
        changePercent: 0.92,
        sparkline: [4, 4.2, 4.1, 4.5, 4.4, 4.7, 4.6, 4.9, 5.1],
      ),
      marketValue: 5553.52,
    ),
  ];

  static final List<NewsArticle> news = [
    NewsArticle(
      title: 'Tesla stock volatility rises amid market uncertainty',
      summary:
          'Shares fluctuate as investors weigh mixed signals around production '
          'targets and global demand conditions.',
      source: 'MarketWatch',
      timeAgo: '2h ago',
      accentColor: AppColors.negative,
    ),
    NewsArticle(
      title: 'Apple hits new all-time high',
      summary:
          'The stock rose after strong reports among quarterly results, driven '
          'by higher iPhone demand and continued services growth.',
      source: 'Bloomberg',
      timeAgo: '4h ago',
      accentColor: AppColors.primary,
    ),
    NewsArticle(
      title: 'Microsoft growth accelerates with Azure expansion',
      summary:
          'Azure adoption increases as businesses integrate AI tools and expand '
          'cloud infrastructure across global markets.',
      source: 'Reuters',
      timeAgo: '6h ago',
      accentColor: AppColors.positive,
    ),
    NewsArticle(
      title: 'Nvidia leads tech rally as AI demand surges',
      summary:
          'The company continues its strong momentum, fuelled by growing demand '
          'for its chips and successive data-centre infrastructure buildouts.',
      source: 'CNBC',
      timeAgo: '9h ago',
      accentColor: AppColors.accent,
    ),
    NewsArticle(
      title: 'Alphabet shares rise on strong AI and cloud growth',
      summary:
          'Growth is driven by rising demand for AI services and continued '
          'strength in Google Cloud revenue.',
      source: 'Financial Times',
      timeAgo: '12h ago',
      accentColor: AppColors.gold,
    ),
  ];

  /// News shown in the "Related News" section of a stock detail page.
  static final List<NewsArticle> relatedNews = [
    NewsArticle(
      title: 'Apple shares rise after strong quarterly earnings',
      summary:
          'Investors react positively to strong iPhone sales and services '
          'growth.',
      source: 'Bloomberg',
      timeAgo: '3h ago',
      accentColor: AppColors.primary,
    ),
    NewsArticle(
      title: 'Apple expands AI integration across devices',
      summary:
          'Analysts expect continued growth in Apple services revenue.',
      source: 'Reuters',
      timeAgo: '7h ago',
      accentColor: AppColors.positive,
    ),
    NewsArticle(
      title: 'Apple stock climbs as analysts raise growth expectations',
      summary:
          'Strong device sales and expanding AI features continue to boost '
          'investor confidence.',
      source: 'CNBC',
      timeAgo: '10h ago',
      accentColor: AppColors.accent,
    ),
  ];

  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      name: 'Monthly plan',
      price: 9.99,
      period: 'month',
      billingNote: 'Billed monthly',
      badge: 'Most flexible',
    ),
    SubscriptionPlan(
      name: 'Annual Plan',
      price: 99.99,
      period: 'year',
      billingNote: r'Then just $8.34/month',
      badge: 'Save 20%',
      featured: true,
    ),
  ];

  static const List<String> proFeatures = [
    'Real-time stock alerts',
    'AI-powered predictions',
    'Advanced analytics dashboard',
    'Ad-free experience',
  ];

  /// Time-range options for the price-performance chart.
  static const List<String> chartRanges = ['1D', '1W', '1M', '1Y', 'All'];
}
