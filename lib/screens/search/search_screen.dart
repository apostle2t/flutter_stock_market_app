import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/stock_repository.dart';
import '../../models/search_result.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stock_avatar.dart';
import '../stock_detail/stock_detail_screen.dart';

/// Full-screen stock search: queries the API as the user types (debounced) and
/// opens the detail page for a tapped result.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  /// Optional query to pre-fill and search immediately on open.
  final String? initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<SearchResult> _results = const [];
  bool _loading = false;
  bool _opening = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery;
    if (initial != null && initial.isNotEmpty) {
      _controller.text = initial;
      _search(initial);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    setState(() => _query = query);
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final results = await stockRepository.searchSymbols(query);
    if (!mounted || query != _query) return; // a newer query superseded this one
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<void> _open(SearchResult result) async {
    if (_opening) return;
    setState(() => _opening = true);
    final stocks = await stockRepository.fetchStocks([result.symbol]);
    if (!mounted) return;
    setState(() => _opening = false);

    final stock = stocks.isNotEmpty ? stocks.first : null;
    if (stock == null || stock.symbol != result.symbol) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text("Couldn't load ${result.symbol}")),
        );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => StockDetailScreen(stock: stock)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search stocks, companies...',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textTertiary),
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                    },
                  ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_opening)
            ColoredBox(
              color: Colors.black45,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_query.isEmpty) {
      return _hint('Search for a stock by symbol or company name');
    }
    if (_results.isEmpty) {
      return _hint('No matches for "$_query"');
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
      itemBuilder: (context, index) => _buildResultTile(_results[index]),
    );
  }

  Widget _buildResultTile(SearchResult result) {
    return InkWell(
      onTap: () => _open(result),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            StockAvatar(symbol: result.symbol),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.symbol,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (result.exchange.isNotEmpty)
              Text(
                result.exchange,
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hint(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
        ),
      ),
    );
  }
}
