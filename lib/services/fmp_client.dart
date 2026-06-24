import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Thrown when an FMP request fails (network error, bad status, or the API
/// returning an error payload instead of data).
class FmpException implements Exception {
  FmpException(this.message);
  final String message;
  @override
  String toString() => 'FmpException: $message';
}

/// Thin wrapper over the Financial Modeling Prep REST API.
///
/// Only concerned with transport + JSON decoding; mapping into domain models
/// lives in [StockRepository].
class FmpClient {
  FmpClient({http.Client? httpClient, String? apiKey})
      : _http = httpClient ?? http.Client(),
        _apiKey = apiKey ?? ApiConfig.fmpApiKey;

  static const String _base = 'financialmodelingprep.com';

  final http.Client _http;
  final String _apiKey;

  /// Whether a usable key is configured. When false the repository should fall
  /// back to mock data rather than calling the network.
  bool get hasKey =>
      _apiKey.isNotEmpty && _apiKey != 'YOUR_FMP_API_KEY_HERE';

  /// Public CDN URL for a company logo. Requires no API key and costs nothing
  /// against the request budget. Returns a 404 for symbols without a logo
  /// (e.g. indices), so callers must handle the image failing to load.
  static String logoUrl(String symbol) =>
      'https://$_base/image-stock/$symbol.png';

  /// Performs a GET against `/stable/<path>` and returns the decoded JSON list.
  ///
  /// FMP endpoints we use return either a JSON array or an object; callers that
  /// expect an array get a normalised [List].
  Future<List<dynamic>> getList(
    String path, {
    Map<String, String> query = const {},
  }) async {
    final body = await _get(path, query);
    if (body is List) return body;
    if (body is Map && body['historical'] is List) {
      return body['historical'] as List<dynamic>;
    }
    if (body is Map) {
      // FMP signals errors as {"Error Message": "..."}.
      final error = body['Error Message'] ?? body['error'];
      if (error != null) throw FmpException(error.toString());
    }
    throw FmpException('Unexpected response shape for /$path');
  }

  Future<dynamic> _get(String path, Map<String, String> query) async {
    final uri = Uri.https(_base, '/stable/$path', {
      ...query,
      'apikey': _apiKey,
    });

    final http.Response response;
    try {
      response = await _http
          .get(uri)
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      throw FmpException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw FmpException(
        'HTTP ${response.statusCode} for /$path: ${response.body}',
      );
    }
    return jsonDecode(response.body);
  }

  void close() => _http.close();
}
