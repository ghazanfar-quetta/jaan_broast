// lib/core/services/permission_service.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'local_storage_service.dart';

class PermissionService {
  // Request camera and photos permission for profile picture
  // Request camera and photos permission for profile picture
  static Future<Map<String, bool>> requestMediaPermissions() async {
    try {
      // Simple approach - request both camera and storage
      final cameraStatus = await Permission.camera.request();
      final storageStatus = await Permission.storage.request();

      return {
        'camera': cameraStatus.isGranted,
        'photos': storageStatus.isGranted,
      };
    } catch (e) {
      print('Error requesting media permissions: $e');
      // Fallback to basic permissions
      final cameraStatus = await Permission.camera.status;
      final storageStatus = await Permission.storage.status;

      return {
        'camera': cameraStatus.isGranted,
        'photos': storageStatus.isGranted,
      };
    }
  }

  // Check if media permissions are granted
  static Future<Map<String, bool>> checkMediaPermissions() async {
    try {
      // For Android 13+ (API 33+)
      if (await Permission.mediaLibrary.isRestricted) {
        final photosStatus = await Permission.mediaLibrary.status;
        final cameraStatus = await Permission.camera.status;

        return {
          'camera': cameraStatus.isGranted,
          'photos': photosStatus.isGranted,
        };
      } else {
        // For older Android versions
        final photosStatus = await Permission.storage.status;
        final cameraStatus = await Permission.camera.status;

        return {
          'camera': cameraStatus.isGranted,
          'photos': photosStatus.isGranted,
        };
      }
    } catch (e) {
      print('Error checking media permissions: $e');
      // Fallback to basic permissions
      final photosStatus = await Permission.storage.status;
      final cameraStatus = await Permission.camera.status;

      return {
        'camera': cameraStatus.isGranted,
        'photos': photosStatus.isGranted,
      };
    }
  }

  // Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      print('📍 PermissionService: Requesting location permission...');
      final status = await Permission.locationWhenInUse.request();
      print('📍 PermissionService: Permission status - $status');
      return status.isGranted;
    } catch (e) {
      print('❌ PermissionService: Error requesting location permission - $e');
      return false;
    }
  }

  // Check if location permission is granted
  static Future<bool> checkLocationPermission() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      print('📍 PermissionService: Current permission status - $status');
      return status.isGranted;
    } catch (e) {
      print('❌ PermissionService: Error checking location permission - $e');
      return false;
    }
  }

  // Request notification permission
  // Update this method in PermissionService class
  static Future<bool> requestNotificationPermission() async {
    try {
      // Mark that we've asked
      await LocalStorageService.setNotificationPermissionAsked(true);

      final status = await Permission.notification.request();

      // Save the result
      await LocalStorageService.setNotificationPermissionStatus(
        status.isGranted,
      );

      return status.isGranted;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  // Check if notification permission is granted
  static Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Open app settings for manual permission enabling
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get detailed location permission status
  static Future<LocationPermission> getDetailedLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission with detailed status
  static Future<LocationPermission> requestDetailedLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  // Get current position with high accuracy
  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  // Combined method to handle complete location permission flow
  static Future<Position?> handleLocationPermissionFlow() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check permission status
      LocationPermission permission = await getDetailedLocationPermission();

      if (permission == LocationPermission.denied) {
        permission = await requestDetailedLocationPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      // Get the current position
      return await getCurrentPosition();
    } catch (e) {
      print('Error in location permission flow: $e');
      return null;
    }
  }

  // Check if we have proper location permission (using geolocator)
  static Future<bool> hasProperLocationPermission() async {
    final permission = await getDetailedLocationPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // Add this method to your existing PermissionService class in permission_service.dart
  // Update the shouldAskNotificationPermission method in PermissionService
  static Future<bool> shouldAskNotificationPermission() async {
    try {
      final askedBefore =
          await LocalStorageService.getNotificationPermissionAsked();
      final currentStatus = await Permission.notification.status;

      print(
        '🔔 Should ask permission? Asked: $askedBefore, Status: $currentStatus',
      );

      // ALWAYS ask on first launch, regardless of current status
      // This ensures the user sees our permission request UX
      if (!askedBefore) {
        print('🔔 First launch - showing permission dialog');
        return true;
      }

      // If we've asked before, only ask again if permission was denied
      return currentStatus.isDenied;
    } catch (e) {
      print('Error checking if should ask notification permission: $e');
      return false;
    }
  }

  // Add to PermissionService class
  static Future<bool> shouldShowAsEnabledInSettings() async {
    try {
      // First check if user explicitly allowed/denied through our dialog
      final userAllowed =
          await LocalStorageService.getUserAllowedNotification();
      final askedBefore =
          await LocalStorageService.getNotificationPermissionAsked();

      if (askedBefore) {
        // User made a choice - respect it
        return userAllowed;
      }

      // If not asked yet, check system permission
      final systemPermission = await Permission.notification.status;
      return systemPermission.isGranted;
    } catch (e) {
      print('Error checking settings notification status: $e');
      return false;
    }
  }
}
