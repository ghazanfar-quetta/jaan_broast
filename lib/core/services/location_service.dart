import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'permission_service.dart';

class LocationService {
  // For OpenStreetMap (FREE) - no API key needed
  static const bool _useOpenStreetMap =
      false; // Changed to false to use Google Maps

  // For Google Maps (PAID) - only set this if you have API key
  static const String _googleMapsApiKey =
      'AIzaSyAOygc2exp_KyB4qj0fVZndnS_wFY0T5Mo';

  // Get current location with full permission handling
  static Future<Position?> getCurrentLocation() async {
    try {
      return await PermissionService.handleLocationPermissionFlow();
    } catch (e) {
      print('LocationService: Error getting location - $e');
      return null;
    }
  }
  // Add this method to your LocationService class

  // Search addresses using Google Maps Places API
  static Future<List<Map<String, dynamic>>> searchAddressesGoogleMaps(
    String query,
  ) async {
    try {
      print(
        '🔍 LocationService: Searching addresses in Google Maps for: $query',
      );

      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&types=address&components=country:pk&key=$_googleMapsApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          print('✅ LocationService: Found ${predictions.length} addresses');

          // Get details for each prediction
          final List<Map<String, dynamic>> results = [];

          for (var prediction in predictions.take(5)) {
            final placeId = prediction['place_id'];
            final details = await _getGooglePlaceDetails(placeId);
            if (details != null) {
              results.add({
                ...details,
                'description': prediction['description'],
              });
            }
          }

          return results;
        } else {
          print('❌ LocationService: No addresses found - ${data['status']}');
          return [];
        }
      } else {
        print(
          '❌ LocationService: Failed to search addresses - ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('❌ LocationService: Error searching addresses in Google Maps - $e');
      return [];
    }
  }

  // Get complete address from coordinates - MAIN METHOD TO USE
  static Future<String> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    if (_useOpenStreetMap) {
      return _getAddressFromOpenStreetMap(lat, lng);
    } else {
      return _getAddressFromGoogleMaps(lat, lng);
    }
  }

  // Get address using Google Maps (PAID) - IMPROVED VERSION
  static Future<String> _getAddressFromGoogleMaps(
    double lat,
    double lng,
  ) async {
    try {
      print(
        '📍 LocationService: Getting address from Google Maps - lat: $lat, lng: $lng',
      );

      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_googleMapsApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Find the most specific and readable address
          String bestAddress = _findBestGoogleAddress(data['results']);

          print('✅ LocationService: Got complete address - $bestAddress');
          return bestAddress;
        } else {
          print('❌ LocationService: No address found - ${data['status']}');
          return _getFallbackAddress(lat, lng);
        }
      } else {
        print(
          '❌ LocationService: Failed to get address - ${response.statusCode}',
        );
        return _getFallbackAddress(lat, lng);
      }
    } catch (e) {
      print('❌ LocationService: Error getting address from Google Maps - $e');
      return _getFallbackAddress(lat, lng);
    }
  }

  // Find the best address from Google Maps results
  static String _findBestGoogleAddress(List<dynamic> results) {
    // Priority order for address types - UPDATED for better local street detection
    const preferredTypes = [
      //'premise', // Specific building/place
      //'subpremise', // Part of building
      //'street_address', // Precise street address
      //'route', // Road/street
      //'neighborhood', // Neighborhood area
      //'sublocality', // Sublocality level
      //'sublocality_level_1',
      //'locality', // City/town
      //'administrative_area_level_2', // District
      //'administrative_area_level_1', // State
    ];

    // Try to find addresses that contain local street names first
    for (var result in results) {
      final types = List<String>.from(result['types'] ?? []);
      final address = result['formatted_address']?.toString() ?? '';

      // Skip if it's just a major road without specific location
      if (_isGenericMajorRoadAddress(address)) {
        continue;
      }

      // Prefer addresses with house numbers or specific landmarks
      if (types.contains('street_address') ||
          types.contains('premise') ||
          _containsHouseNumber(result)) {
        return _cleanGoogleAddress(address);
      }
    }

    // Fallback: try all results in preferred order
    for (var type in preferredTypes) {
      for (var result in results) {
        final types = List<String>.from(result['types'] ?? []);
        if (types.contains(type)) {
          final address = result['formatted_address']?.toString() ?? '';
          if (address.isNotEmpty && !_isGenericMajorRoadAddress(address)) {
            return _cleanGoogleAddress(address);
          }
        }
      }
    }

    // Last resort: use first result
    final firstAddress = results[0]['formatted_address']?.toString() ?? '';
    return _cleanGoogleAddress(firstAddress);
  }

  // Check if address is just a generic major road without specific location
  static bool _isGenericMajorRoadAddress(String address) {
    final majorRoadPatterns = [
      'Airport Road',
      'Main Road',
      'Highway',
      'Motorway',
      'Expressway',
    ];

    final lowerAddress = address.toLowerCase();

    // If it contains major road names but no house numbers or local landmarks
    for (final pattern in majorRoadPatterns) {
      if (lowerAddress.contains(pattern.toLowerCase())) {
        // Check if it lacks specific location indicators
        final hasSpecificLocation =
            RegExp(r'\d+').hasMatch(address) || // House numbers
            address.toLowerCase().contains('near') ||
            address.toLowerCase().contains('opposite') ||
            address.toLowerCase().contains('beside') ||
            address.toLowerCase().contains('street') ||
            address.toLowerCase().contains('st') ||
            address.toLowerCase().contains('lane');

        return !hasSpecificLocation;
      }
    }

    return false;
  }

  // Check if the result contains house number information
  static bool _containsHouseNumber(Map<String, dynamic> result) {
    final addressComponents = result['address_components'] as List?;
    if (addressComponents != null) {
      for (var component in addressComponents) {
        final types = List<String>.from(component['types'] ?? []);
        if (types.contains('street_number')) {
          return true;
        }
      }
    }
    return false;
  }

  // Enhanced address cleaning
  static String _cleanGoogleAddress(String address) {
    String cleaned = address;

    // Remove redundant country names
    cleaned = cleaned.replaceAll(', Pakistan, Pakistan', ', Pakistan');
    cleaned = cleaned.replaceAll(', ,', ',');

    // Try to improve address by removing overly generic road names when possible
    if (_isGenericMajorRoadAddress(cleaned)) {
      // You could add logic here to try alternative address sources
      // or modify the address to be more accurate
    }

    // Trim any trailing commas
    cleaned = cleaned.replaceAll(RegExp(r',\s*$'), '');

    return cleaned.trim();
  }

  // Search addresses using Google Maps (PAID) - IMPROVED VERSION
  static Future<List<Map<String, dynamic>>> _searchAddressesGoogleMaps(
    String query,
  ) async {
    try {
      print(
        '🔍 LocationService: Searching addresses in Google Maps for: $query',
      );

      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&types=address&key=$_googleMapsApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          print('✅ LocationService: Found ${predictions.length} addresses');

          // Get details for each prediction
          final List<Map<String, dynamic>> results = [];

          for (var prediction in predictions.take(5)) {
            final placeId = prediction['place_id'];
            final details = await _getGooglePlaceDetails(placeId);
            if (details != null) {
              results.add(details);
            }
          }

          return results;
        } else {
          print('❌ LocationService: No addresses found - ${data['status']}');
          return [];
        }
      } else {
        print(
          '❌ LocationService: Failed to search addresses - ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('❌ LocationService: Error searching addresses in Google Maps - $e');
      return [];
    }
  }

  // Get detailed place information from Google Maps - IMPROVED VERSION
  static Future<Map<String, dynamic>?> _getGooglePlaceDetails(
    String placeId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_address,geometry,vicinity,address_components&key=$_googleMapsApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];

          // Build a comprehensive address display
          String displayAddress = result['formatted_address'] ?? '';
          String shortAddress = _extractShortAddress(result);

          return {
            'display_name': displayAddress,
            'short_name': shortAddress,
            'lat': result['geometry']['location']['lat'],
            'lon': result['geometry']['location']['lng'],
            'place_id': placeId,
            'vicinity': result['vicinity'] ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ LocationService: Error getting Google place details - $e');
      return null;
    }
  }

  // Extract a shorter, more readable address
  static String _extractShortAddress(Map<String, dynamic> result) {
    final addressComponents = result['address_components'] as List?;
    final formattedAddress = result['formatted_address']?.toString() ?? '';

    if (addressComponents == null) {
      return formattedAddress;
    }

    // Try to build a concise address
    final List<String> parts = [];

    for (var component in addressComponents) {
      final types = List<String>.from(component['types'] ?? []);
      final name = component['long_name']?.toString() ?? '';

      if (types.contains('street_number') ||
          types.contains('route') ||
          types.contains('neighborhood') ||
          types.contains('sublocality') ||
          types.contains('locality')) {
        if (name.isNotEmpty && !parts.contains(name)) {
          parts.add(name);
        }
      }
    }

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return formattedAddress;
  }

  // Get address using OpenStreetMap Nominatim (FREE) - IMPROVED VERSION
  static Future<String> _getAddressFromOpenStreetMap(
    double lat,
    double lng,
  ) async {
    try {
      print(
        '📍 LocationService: Getting address from OpenStreetMap - lat: $lat, lng: $lng',
      );

      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1&accept-language=en&zoom=18&namedetails=1',
        ),
        headers: {'User-Agent': 'JaanBroastApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = _parseEnhancedOpenStreetMapAddress(data);
        print('✅ LocationService: Got address - $address');

        if (_isAddressTooGeneric(address)) {
          return await _getAlternativeAddress(lat, lng);
        }

        return address;
      } else {
        print(
          '❌ LocationService: Failed to get address - ${response.statusCode}',
        );
        return _getFallbackAddress(lat, lng);
      }
    } catch (e) {
      print('❌ LocationService: Error getting address from OpenStreetMap - $e');
      return _getFallbackAddress(lat, lng);
    }
  }

  // Enhanced address parsing for OpenStreetMap
  static String _parseEnhancedOpenStreetMapAddress(Map<String, dynamic> data) {
    if (data['address'] == null) {
      return data['display_name'] ?? 'Unknown Address';
    }

    final address = data['address'] as Map<String, dynamic>;

    // Build address from most specific to most general
    final List<String> parts = [];

    // Street-level address
    final String? houseNumber = address['house_number']?.toString();
    final String? road = address['road']?.toString();

    if (houseNumber != null && road != null) {
      parts.add('$houseNumber $road');
    } else if (road != null) {
      parts.add(road);
    }

    // Local area
    final String? neighbourhood = address['neighbourhood']?.toString();
    final String? suburb = address['suburb']?.toString();
    if (neighbourhood != null) {
      parts.add(neighbourhood);
    } else if (suburb != null) {
      parts.add(suburb);
    }

    // City/Town
    final String? city = address['city']?.toString();
    final String? town = address['town']?.toString();
    final String? village = address['village']?.toString();
    if (city != null) {
      parts.add(city);
    } else if (town != null) {
      parts.add(town);
    } else if (village != null) {
      parts.add(village);
    }

    // State and Country
    final String? state = address['state']?.toString();
    final String? country = address['country']?.toString();
    if (state != null) {
      parts.add(state);
    }
    if (country != null) {
      parts.add(country);
    }

    // If we have a decent address, return it
    if (parts.length >= 2) {
      return parts.join(', ');
    }

    // Fallback to full display name
    return data['display_name']?.toString() ?? 'Unknown Address';
  }

  // Search addresses - MAIN SEARCH METHOD
  static Future<List<Map<String, dynamic>>> searchAddresses(
    String query,
  ) async {
    if (_useOpenStreetMap) {
      return _searchAddressesOpenStreetMap(query);
    } else {
      return _searchAddressesGoogleMaps(query);
    }
  }

  // OpenStreetMap search implementation
  static Future<List<Map<String, dynamic>>> _searchAddressesOpenStreetMap(
    String query,
  ) async {
    try {
      print(
        '🔍 LocationService: Searching addresses in OpenStreetMap for: $query',
      );

      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$query&addressdetails=1&limit=10&accept-language=en',
        ),
        headers: {'User-Agent': 'JaanBroastApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ LocationService: Found ${data.length} addresses');

        return data.map((item) {
          return {
            'display_name': item['display_name'],
            'lat': double.parse(item['lat']),
            'lon': double.parse(item['lon']),
            'address': item['address'],
          };
        }).toList();
      } else {
        print(
          '❌ LocationService: Failed to search addresses - ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print(
        '❌ LocationService: Error searching addresses in OpenStreetMap - $e',
      );
      return [];
    }
  }

  // Helper methods (keep your existing implementations)
  static bool _isAddressTooGeneric(String address) {
    final genericPatterns = [
      'Quetta City Tehsil',
      'Quetta District',
      'Balochistan',
      '87300',
    ];

    int matchCount = 0;
    for (final pattern in genericPatterns) {
      if (address.contains(pattern)) {
        matchCount++;
      }
    }

    return matchCount >= 2 &&
        !address.toLowerCase().contains('road') &&
        !address.toLowerCase().contains('street') &&
        !address.toLowerCase().contains('house') &&
        !address.toLowerCase().contains('building');
  }

  static Future<String> _getAlternativeAddress(double lat, double lng) async {
    try {
      print('🔄 LocationService: Trying alternative address lookup...');

      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1&accept-language=en&zoom=18&addressdetails=1&extratags=1',
        ),
        headers: {'User-Agent': 'JaanBroastApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = _parseEnhancedOpenStreetMapAddress(data);

        if (_isAddressTooGeneric(address)) {
          return await _getFallbackDetailedAddress(lat, lng);
        }

        return address;
      }
    } catch (e) {
      print('❌ LocationService: Alternative address lookup failed - $e');
    }

    return _getFallbackAddress(lat, lng);
  }

  static Future<String> _getFallbackDetailedAddress(
    double lat,
    double lng,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=&lat=$lat&lon=$lng&radius=100&limit=5&accept-language=en',
        ),
        headers: {'User-Agent': 'JaanBroastApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final closest = data.first;
          return closest['display_name']?.toString() ??
              _getFallbackAddress(lat, lng);
        }
      }
    } catch (e) {
      print('❌ LocationService: Fallback detailed address failed - $e');
    }

    return _getFallbackAddress(lat, lng);
  }

  // Fallback address if API fails
  static String _getFallbackAddress(double lat, double lng) {
    return 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
  }

  // Check if location services are available and permission granted
  static Future<bool> isLocationAvailable() async {
    try {
      final serviceEnabled = await PermissionService.isLocationServiceEnabled();
      final hasPermission =
          await PermissionService.hasProperLocationPermission();
      return serviceEnabled && hasPermission;
    } catch (e) {
      print('LocationService: Error checking location availability - $e');
      return false;
    }
  }

  // Get distance between two coordinates in meters
  static Future<double> getDistanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    return await Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Check if user is within delivery range (example: 10km)
  static Future<bool> isWithinDeliveryRange(
    double userLat,
    double userLng,
    double restaurantLat,
    double restaurantLng, {
    double maxDistanceKm = 10.0,
  }) async {
    final distanceInMeters = await getDistanceBetween(
      userLat,
      userLng,
      restaurantLat,
      restaurantLng,
    );
    final distanceInKm = distanceInMeters / 1000;
    return distanceInKm <= maxDistanceKm;
  }

  // Get continuous location updates (for real-time tracking)
  static Stream<Position> getLocationUpdates() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}
