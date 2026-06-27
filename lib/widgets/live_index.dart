import 'package:flutter/material.dart';

import '../models/market_index.dart';
import '../services/live_price_controller.dart';

/// Rebuilds [builder] with a live-ticking copy of [initial] on every tick of
/// [LivePriceController]. The index-card analogue of `LiveStock`.
class LiveIndex extends StatefulWidget {
  LiveIndex({super.key, required this.initial, required this.builder});

  final MarketIndex initial;
  final Widget Function(BuildContext context, MarketIndex index) builder;

  @override
  State<LiveIndex> createState() => _LiveIndexState();
}

class _LiveIndexState extends State<LiveIndex> {
  final LivePriceController _controller = LivePriceController.instance;

  @override
  void initState() {
    super.initState();
    _controller.registerIndex(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) =>
          widget.builder(context, _controller.liveIndexOf(widget.initial)),
    );
  }
}
