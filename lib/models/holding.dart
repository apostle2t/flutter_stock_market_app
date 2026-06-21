import 'package:flutter/material.dart';

import 'stock.dart';

/// A position the user holds in their portfolio.
@immutable
class Holding {
  const Holding({required this.stock, required this.marketValue});

  final Stock stock;

  /// Current market value of the position in USD.
  final double marketValue;
}
