import 'package:flutter/material.dart';

import '../services/fmp_client.dart';
import '../theme/app_colors.dart';

/// Rounded square badge for a stock.
///
/// Loads the company logo from FMP's public image CDN, falling back to a chip
/// showing the symbol's leading letter while it loads or if no logo exists
/// (e.g. indices, or when offline).
class StockAvatar extends StatelessWidget {
  const StockAvatar({super.key, required this.symbol, this.size = 44});

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Image.network(
        FmpClient.logoUrl(symbol),
        fit: BoxFit.contain,
        // Logos are often dark on transparent backgrounds, so they sit on a
        // white tile to stay visible against the dark theme.
        loadingBuilder: (context, child, progress) => progress == null
            ? Container(
                color: Colors.white,
                padding: EdgeInsets.all(size * 0.16),
                child: child,
              )
            : _letter(),
        errorBuilder: (context, error, stackTrace) => _letter(),
      ),
    );
  }

  Widget _letter() {
    return Container(
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: Text(
        symbol.characters.first,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
