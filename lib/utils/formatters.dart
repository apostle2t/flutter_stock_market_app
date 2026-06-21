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
}
