import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Wraps a [Future] with consistent loading / error / data states so screens
/// don't repeat the same `FutureBuilder` boilerplate.
///
/// The repository already falls back to mock data on failure, so [errorBuilder]
/// is rarely hit — it exists as a last resort for unexpected exceptions.
class AsyncData<T> extends StatelessWidget {
  const AsyncData({
    super.key,
    required this.future,
    required this.builder,
    this.loadingHeight = 120,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final double loadingHeight;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: loadingHeight,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            height: loadingHeight,
            child: const Center(
              child: Text(
                "Couldn't load data",
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
          );
        }
        return builder(context, snapshot.data as T);
      },
    );
  }
}
