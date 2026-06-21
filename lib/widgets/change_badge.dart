import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Coloured percentage-change label, optionally with a trend arrow.
class ChangeBadge extends StatelessWidget {
  const ChangeBadge({
    super.key,
    required this.changePercent,
    this.showArrow = false,
    this.fontSize = 13,
  });

  final double changePercent;
  final bool showArrow;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forChange(changePercent);
    final positive = changePercent >= 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showArrow) ...[
          Icon(
            positive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: color,
            size: fontSize + 6,
          ),
        ],
        Text(
          Formatters.signedPercent(changePercent),
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
