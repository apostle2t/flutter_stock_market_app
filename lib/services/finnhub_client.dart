import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Thrown when a Finnhub request fails.
class FinnhubException implements Exception {
  FinnhubException(this.message);
  final String message;
  @override
  String toString() => 'FinnhubException: $message';
}

/// Thin wrapper over the Finnhub REST API, used for market news (FMP's news
/// endpoint is paid-only).
class FinnhubClient {
  FinnhubClient({http.Client? httpClient, String? apiKey})
      : _http = httpClient ?? http.Client(),
        _apiKey = apiKey ?? ApiConfig.finnhubApiKey;

  static const String _base = 'finnhub.io';

  final http.Client _http;
  final String _apiKey;

  /// Whether a usable key is configured.
  bool get hasKey =>
      _apiKey.isNotEmpty && _apiKey != 'YOUR_FINNHUB_API_KEY_HERE';

  /// GET `/api/v1/<path>` and return the decoded JSON list.
  Future<List<dynamic>> getList(
    String path, {
    Map<String, String> query = const {},
  }) async {
    final uri = Uri.https(_base, '/api/v1/$path', {
      ...query,
      'token': _apiKey,
    });

    final http.Response response;
    try {
      response = await _http.get(uri).timeout(const Duration(seconds: 12));
    } catch (e) {
      throw FinnhubException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw FinnhubException('HTTP ${response.statusCode} for /$path');
    }

    final body = jsonDecode(response.body);
    if (body is List) return body;
    throw FinnhubException('Unexpected response shape for /$path');
  }

  /// GET `/api/v1/<path>` and return the decoded JSON object (for endpoints
  /// like `/stock/metric` that return a map rather than a list). Null on error.
  Future<Map<String, dynamic>?> getJson(
    String path, {
    Map<String, String> query = const {},
  }) async {
    final uri = Uri.https(_base, '/api/v1/$path', {...query, 'token': _apiKey});
    try {
      final response =
          await _http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      return body is Map<String, dynamic> ? body : null;
    } catch (e) {
      return null;
    }
  }

  void close() => _http.close();
}
