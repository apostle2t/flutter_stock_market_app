import 'package:flutter/material.dart';

/// A billing option on the AetherPro upgrade screen.
@immutable
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.name,
    required this.price,
    required this.period,
    required this.billingNote,
    this.badge,
    this.featured = false,
  });

  final String name;
  final double price;

  /// Display unit for the price, e.g. `month`.
  final String period;
  final String billingNote;

  /// Optional ribbon label such as `Most flexible` or `Save 20%`.
  final String? badge;

  /// Whether this plan should be visually highlighted as the recommended one.
  final bool featured;
}
