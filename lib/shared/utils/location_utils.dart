import 'dart:convert';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationUtils {
  static const double fallbackLatitude = 27.7172;
  static const double fallbackLongitude = 85.3240;
  static Position? _cachedPosition;

  static Position? get cachedPosition => _cachedPosition;

  static Future<Position?> prewarmCurrentPosition() async {
    final position = await getCurrentPosition();
    if (position != null) {
      _cachedPosition = position;
    }
    return position;
  }

  static Future<Position?> getCurrentPosition() async {
    if (_cachedPosition != null) {
      return _cachedPosition;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        _cachedPosition ??= lastKnown;
        return lastKnown;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        _cachedPosition ??= lastKnown;
        return lastKnown;
      }

      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      _cachedPosition = current;
      return current;
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      _cachedPosition ??= lastKnown;
      return lastKnown;
    }
  }

  static Future<List<LocationSearchResult>> searchAddresses(
    String query, {
    int limit = 5,
  }) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query,
        'format': 'jsonv2',
        'limit': '$limit',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'ShramDaan/1.0 (community volunteering app)',
      },
    );

    if (response.statusCode != 200) {
      return [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      return [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat == null || lon == null) {
            return null;
          }

          return LocationSearchResult(
            latitude: lat,
            longitude: lon,
            label: item['display_name']?.toString() ?? query,
          );
        })
        .whereType<LocationSearchResult>()
        .toList();
  }

  static Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'jsonv2',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'ShramDaan/1.0 (community volunteering app)',
      },
    );

    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return decoded['display_name']?.toString();
  }

  static double haversineDistanceKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(endLatitude - startLatitude);
    final dLon = _degreesToRadians(endLongitude - startLongitude);
    final startLatRad = _degreesToRadians(startLatitude);
    final endLatRad = _degreesToRadians(endLatitude);

    final a =
        pow(sin(dLat / 2), 2) +
        cos(startLatRad) * cos(endLatRad) * pow(sin(dLon / 2), 2);
    final c = 2 * asin(sqrt(a));
    return earthRadiusKm * c;
  }

  static String formatDistanceKm(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m away';
    }
    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  static String compactAddressLabel(String? rawLabel) {
    if (rawLabel == null || rawLabel.trim().isEmpty) {
      return 'Location unavailable';
    }

    final pieces = rawLabel
        .split(',')
        .map((part) => _cleanAddressSegment(part))
        .where((part) => part.isNotEmpty)
        .toList();

    if (pieces.isEmpty) {
      return 'Location unavailable';
    }

    final banned = <String>{
      'nepal',
      'bagmati province',
      'bagmati',
      'province',
      'ward',
    };

    final unique = <String>[];
    for (final piece in pieces) {
      final lower = piece.toLowerCase();
      if (banned.contains(lower)) continue;
      if (lower.length <= 2) continue;
      if (unique.any((existing) => existing.toLowerCase() == lower)) continue;
      unique.add(piece);
    }

    if (unique.isEmpty) {
      return pieces.first;
    }

    String? district;
    for (final piece in unique.skip(1)) {
      final lower = piece.toLowerCase();
      if (lower.contains('kathmandu')) {
        district = 'Kathmandu';
        break;
      }
    }

    district ??= unique.length > 1 ? unique[1] : null;

    if (district != null &&
        district.isNotEmpty &&
        district.toLowerCase() != unique.first.toLowerCase()) {
      return '${unique.first}, $district';
    }

    return unique.first;
  }

  static String _cleanAddressSegment(String value) {
    return value
        .replaceAll(RegExp(r'\b\d+\b'), '')
        .replaceAll(RegExp(r'-\d+'), '')
        .replaceAll('Metropolitan City', '')
        .replaceAll('Sub-Metropolitan City', '')
        .replaceAll('Municipality', '')
        .replaceAll('Rural Municipality', '')
        .replaceAll('Ward No.', '')
        .replaceAll('Ward', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[-\s]+$'), '')
        .trim();
  }
  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}

class LocationSearchResult {
  final double latitude;
  final double longitude;
  final String label;

  const LocationSearchResult({
    required this.latitude,
    required this.longitude,
    required this.label,
  });
}




