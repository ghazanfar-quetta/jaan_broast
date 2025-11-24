// lib/features/location/presentation/view_models/location_view_model.dart
import 'package:flutter/material.dart';
import '../../../../core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationViewModel with ChangeNotifier {
  String _currentLocation = 'Quetta';
  bool _isLoading = false;
  String _error = '';
  double? _latitude;
  double? _longitude;
  bool _isAutoLocation = false;

  String get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String get error => _error;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isAutoLocation => _isAutoLocation;

  // Simplified: Just get the location
  Future<bool> retryAutoLocation() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final position = await LocationService.getCurrentLocation();

      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _currentLocation = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        _isAutoLocation = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Could not get current location';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to get location: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void updateLocationManually(String location, {double? lat, double? lng}) {
    _currentLocation = location;
    _latitude = lat;
    _longitude = lng;
    _isAutoLocation = false;
    _error = '';
    notifyListeners();
  }

  bool get isLocationSet =>
      _currentLocation.isNotEmpty && _currentLocation != 'Quetta';

  Map<String, dynamic> get locationData {
    return {
      'address': _currentLocation,
      'latitude': _latitude,
      'longitude': _longitude,
      'isAutoLocation': _isAutoLocation,
    };
  }
}
