import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// The resolved location for the Local screen header.
@immutable
class LocationResult {
  const LocationResult({
    required this.city,
    required this.region,
    required this.country,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final String region; // state / principal subdivision
  final String country;
  final String countryCode; // e.g. "US", "GB"
  final double latitude;
  final double longitude;
}

/// Resolves the device's current city/country.
///
/// `geolocator` only yields coordinates, so reverse-geocoding (coords -> place
/// name) is done with BigDataCloud's free, key-less reverse-geocode endpoint
/// over plain HTTP. Every step fails soft (returns null) so callers can fall
/// back to a default — location is best-effort, never blocking.
class LocationService {
  LocationService({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<LocationResult?> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('Location services disabled');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Location permission not granted: $permission');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return _reverseGeocode(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('getCurrentLocation failed: $e');
      return null;
    }
  }

  /// Turns coordinates into a place name via BigDataCloud (free, no API key).
  Future<LocationResult?> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.https(
        'api.bigdatacloud.net',
        '/data/reverse-geocode-client',
        {
          'latitude': '$lat',
          'longitude': '$lng',
          'localityLanguage': 'en',
        },
      );
      final response =
          await _http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final city = (json['city'] ?? json['locality'] ?? '').toString();
      final region = (json['principalSubdivision'] ?? '').toString();
      return LocationResult(
        city: city.isNotEmpty ? city : region,
        region: region,
        country: (json['countryName'] ?? '').toString(),
        countryCode: (json['countryCode'] ?? '').toString(),
        latitude: lat,
        longitude: lng,
      );
    } catch (e) {
      debugPrint('reverseGeocode failed: $e');
      return null;
    }
  }
}
