import 'package:flutter/material.dart';

import '../services/fmp_client.dart';
import '../theme/app_colors.dart';

/// Rounded square badge for a stock.
///
/// Shows the company logo from FMP's image CDN when one loads (mostly US
/// tickers). Otherwise — while loading, on error, or for symbols with no logo
/// (e.g. most non-US stocks and indices) — it shows a clean coloured "initial"
/// tile, with a deterministic brand colour per symbol so every avatar looks
/// intentional rather than blank.
class StockAvatar extends StatelessWidget {
  const StockAvatar({super.key, required this.symbol, this.size = 44});

  final String symbol;
  final double size;

  /// Palette for the initial tiles; chosen per-symbol so it's stable.
  static const List<Color> _palette = [
    AppColors.primary,
    AppColors.accent,
    Color(0xFF2E9E8F), // teal
    AppColors.gold,
    Color(0xFFD46AA6), // pink
    AppColors.positive,
    Color(0xFF5A7BE0), // blue
  ];

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
        // Real logos are often dark on transparent backgrounds, so a loaded
        // logo sits on a white tile to stay visible against the dark theme.
        loadingBuilder: (context, child, progress) => progress == null
            ? Container(
                color: Colors.white,
                padding: EdgeInsets.all(size * 0.16),
                child: child,
              )
            : _initialTile(),
        errorBuilder: (context, error, stackTrace) => _initialTile(),
      ),
    );
  }

  Widget _initialTile() {
    final color = _palette[symbol.hashCode.abs() % _palette.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.65)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol.characters.first,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
