/// Template for API configuration.
///
/// Copy this file to `config.dart` (which is git-ignored) and paste your real
/// Financial Modeling Prep API key. Get a free key at:
/// https://site.financialmodelingprep.com/developer/docs
///
///   cp lib/config.example.dart lib/config.dart
///
abstract final class ApiConfig {
  /// Your Financial Modeling Prep API key.
  static const String fmpApiKey = 'YOUR_FMP_API_KEY_HERE';

  /// When false (or the key is missing) the app serves bundled [MockData]
  /// instead of hitting the network — handy for offline development/demos.
  static const bool useLiveData = true;
}
