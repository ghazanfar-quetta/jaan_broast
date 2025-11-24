// lib/core/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'permission_service.dart';

class LocationService {
  // Toggle between maps
  static const bool _useOpenStreetMap = false; // false = Google Maps

  // Google API key – KEEP SAFE
  static const String _googleMapsApiKey =
      'AIzaSyAOygc2exp_KyB4qj0fVZndnS_wFY0T5Mo';

  // ------------------------------------------------------------
  //                CURRENT LOCATION (Auto Location)
  // ------------------------------------------------------------

  static Future<Position?> getCurrentLocation() async {
    try {
      return await PermissionService.handleLocationPermissionFlow();
    } catch (e) {
      print('LocationService: Error getting location - $e');
      return null;
    }
  }

  // ------------------------------------------------------------
  //       PUBLIC METHOD: Search addresses (used in ViewModel)
  // ------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> searchAddresses(
    String query,
  ) async {
    if (_useOpenStreetMap) {
      return _searchAddressesOpenStreetMap(query);
    } else {
      return searchAddressesGoogleMaps(query); // FIXED PUBLIC NAME
    }
  }

  // ------------------------------------------------------------
  //       FIXED PUBLIC METHOD: Google Places Search
  // ------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> searchAddressesGoogleMaps(
    String query,
  ) async {
    try {
      print('🔍 Searching Google Places: $query');

      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=$query'
          '&types=address'
          '&components=country:pk'
          '&language=en'
          '&key=$_googleMapsApiKey',
        ),
      );

      final data = json.decode(response.body);

      if (data['status'] != 'OK') {
        print('❌ Google Autocomplete Error: ${data['status']}');
        return [];
      }

      final predictions = data['predictions'] as List;

      List<Map<String, dynamic>> results = [];

      for (var prediction in predictions.take(5)) {
        final placeId = prediction['place_id'];
        final details = await _getGooglePlaceDetails(placeId);

        if (details != null) {
          results.add({
            'display_name': details['display_name'],
            'lat': details['lat'],
            'lon': details['lon'],
            'place_id': placeId,
          });
        }
      }

      return results;
    } catch (e) {
      print('❌ Error in searchAddressesGoogleMaps: $e');
      return [];
    }
  }

  // ------------------------------------------------------------
  //        GET ADDRESS FROM COORDINATES (Google / OSM)
  // ------------------------------------------------------------

  static Future<String> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    return _useOpenStreetMap
        ? _getAddressFromOpenStreetMap(lat, lng)
        : _getAddressFromGoogleMaps(lat, lng);
  }

  // ------------------------------------------------------------
  //                Google Reverse Geocoding
  // ------------------------------------------------------------

  static Future<String> _getAddressFromGoogleMaps(
    double lat,
    double lng,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=$lat,$lng'
          '&language=en'
          '&key=$_googleMapsApiKey',
        ),
      );

      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        return data['results'][0]['formatted_address'];
      }
    } catch (e) {
      print('❌ Google Geocoding Error: $e');
    }

    return 'Lat: $lat, Lng: $lng';
  }

  // ------------------------------------------------------------
  //                Google Place Details
  // ------------------------------------------------------------

  static Future<Map<String, dynamic>?> _getGooglePlaceDetails(
    String placeId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=name,formatted_address,geometry,address_components'
          '&key=$_googleMapsApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];

          return {
            'display_name': result['formatted_address'] ?? '',
            'lat': result['geometry']['location']['lat'],
            'lon': result['geometry']['location']['lng'],
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ Google Place Details Error: $e');
      return null;
    }
  }

  // ------------------------------------------------------------
  //                OpenStreetMap Address Search
  // ------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> _searchAddressesOpenStreetMap(
    String query,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=10&addressdetails=1',
        ),
        headers: {'User-Agent': 'JaanBroastApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        return data.map((item) {
          return {
            'display_name': item['display_name'],
            'lat': double.parse(item['lat']),
            'lon': double.parse(item['lon']),
          };
        }).toList();
      }
    } catch (e) {
      print('❌ OpenStreetMap Search Error: $e');
    }

    return [];
  }

  // ------------------------------------------------------------
  //        OpenStreetMap: Reverse Geocoding
  // ------------------------------------------------------------

  static Future<String> _getAddressFromOpenStreetMap(
    double lat,
    double lng,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1',
        ),
        headers: {'User-Agent': 'JaanBroastApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? "Unknown Location";
      }
    } catch (e) {
      print('❌ OSM Reverse Lookup Error: $e');
    }

    return 'Lat: $lat, Lng: $lng';
  }

  // ------------------------------------------------------------
  //                Utility / Extra Features
  // ------------------------------------------------------------

  static Future<bool> isLocationAvailable() async {
    try {
      return await PermissionService.isLocationServiceEnabled() &&
          await PermissionService.hasProperLocationPermission();
    } catch (e) {
      return false;
    }
  }

  static Future<double> getDistanceBetween(
    double aLat,
    double aLng,
    double bLat,
    double bLng,
  ) async {
    return Geolocator.distanceBetween(aLat, aLng, bLat, bLng);
  }

  static Stream<Position> getLocationUpdates() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
