import 'package:geolocator/geolocator.dart';
import 'permission_service.dart';

class LocationService {
  // UPDATED: Get current location with timeout and better error handling
  static Future<Position?> getCurrentLocation() async {
    try {
      print('🔄 LocationService: Getting current location...');

      // Use the permission service flow with timeout
      try {
        final position = await PermissionService.handleLocationPermissionFlow()
            .timeout(const Duration(seconds: 20));

        if (position != null) {
          print('✅ LocationService: Got location successfully');
          return position;
        } else {
          print('❌ LocationService: Failed to get location');
          return null;
        }
      } catch (e) {
        // Check if it's a timeout by checking the error message
        if (e.toString().contains('Timeout') ||
            e.toString().contains('timed out')) {
          print('⏰ LocationService: Location request timed out');
          return null;
        }
        rethrow; // Re-throw other errors
      }
    } catch (e) {
      print('❌ LocationService: Error getting location - $e');
      return null;
    }
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

  // Get approximate address from coordinates (placeholder for Google Maps API)
  static Future<String> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      // TODO: Implement reverse geocoding with Google Maps Geocoding API
      // For now, return coordinates as string
      print(
        '📍 LocationService: Getting address for coordinates - lat: $lat, lng: $lng',
      );
      return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
    } catch (e) {
      print('❌ LocationService: Error getting address - $e');
      return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
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
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }
}
