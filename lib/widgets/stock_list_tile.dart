import 'package:flutter/material.dart';

import '../models/stock.dart';
import '../theme/app_colors.dart';
import 'stock_avatar.dart';

/// A row showing a stock's identity on the left and caller-provided [trailing]
/// content on the right. Used for trending lists and portfolio holdings.
class StockListTile extends StatelessWidget {
  StockListTile({
    super.key,
    required this.stock,
    required this.trailing,
    this.onTap,
  });

  final Stock stock;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            StockAvatar(symbol: stock.symbol),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.symbol,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stock.name,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
