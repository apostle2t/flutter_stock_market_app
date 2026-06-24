import 'package:intl/intl.dart';

/// Shared number/currency formatting helpers.
abstract final class Formatters {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 2,
  );

  /// `$24,562.82`
  static String currency(double value) => _currency.format(value);

  /// `+1.24%` / `-0.54%`
  static String signedPercent(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  /// `+$1,234.09` / `-$120.00`
  static String signedCurrency(double value) {
    final sign = value >= 0 ? '+' : '-';
    return '$sign${_currency.format(value.abs())}';
  }

  /// Abbreviated large number with a `$` prefix: `$2.9T`, `$792B`, `$52M`.
  /// Used for market-cap style figures returned as raw numbers by the API.
  static String compactCurrency(num value) => '\$${_compact(value)}';

  /// Abbreviated number without a currency symbol: `52M`, `1.2K`.
  static String compact(num value) => _compact(value);

  static String _compact(num value) {
    final abs = value.abs();
    if (abs >= 1e12) return '${(value / 1e12).toStringAsFixed(1)}T';
    if (abs >= 1e9) return '${(value / 1e9).toStringAsFixed(1)}B';
    if (abs >= 1e6) return '${(value / 1e6).toStringAsFixed(1)}M';
    if (abs >= 1e3) return '${(value / 1e3).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  /// Converts an ISO timestamp (e.g. `2026-06-24 14:30:00`) into a coarse
  /// "time ago" label like `2h ago` / `3d ago`, relative to [now].
  static String timeAgo(DateTime time, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
