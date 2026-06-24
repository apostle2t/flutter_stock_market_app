import 'package:flutter/material.dart';

import '../models/stock.dart';
import '../services/live_price_controller.dart';

/// Rebuilds [builder] with a live-ticking copy of [initial] on every tick of
/// [LivePriceController].
///
/// Wrap an individual card/row so only that subtree repaints when prices
/// update, rather than the whole screen. The first [initial] seen for a symbol
/// seeds the simulation's anchor (its real fetched price).
class LiveStock extends StatefulWidget {
  const LiveStock({super.key, required this.initial, required this.builder});

  final Stock initial;
  final Widget Function(BuildContext context, Stock stock) builder;

  @override
  State<LiveStock> createState() => _LiveStockState();
}

class _LiveStockState extends State<LiveStock> {
  final LivePriceController _controller = LivePriceController.instance;

  @override
  void initState() {
    super.initState();
    _controller.register(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) =>
          widget.builder(context, _controller.liveOf(widget.initial)),
    );
  }
}
