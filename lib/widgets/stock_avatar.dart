import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rounded square badge showing a stock's leading symbol letter.
///
/// Stands in for company logos so the UI works without bundled image assets.
class StockAvatar extends StatelessWidget {
  const StockAvatar({super.key, required this.symbol, this.size = 44});

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppColors.border),
      ),
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
