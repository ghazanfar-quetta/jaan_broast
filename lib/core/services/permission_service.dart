// lib/core/services/permission_service.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Request camera and photos permission for profile picture
  static Future<Map<String, bool>> requestMediaPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final photosStatus = await Permission.storage.request();

    return {'camera': cameraStatus.isGranted, 'photos': photosStatus.isGranted};
  }

  // Check if media permissions are granted
  static Future<Map<String, bool>> checkMediaPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final photosStatus = await Permission.storage.status;

    return {'camera': cameraStatus.isGranted, 'photos': photosStatus.isGranted};
  }

  // Request location permission
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  // Check if location permission is granted
  static Future<bool> checkLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  // Request notification permission
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
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
}
