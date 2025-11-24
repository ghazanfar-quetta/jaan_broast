import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/permission_service.dart';
import '../../features/location/presentation/view_models/location_view_model.dart';

enum LocationFlowState {
  initial,
  requestingPermission,
  permissionGranted,
  permissionDenied,
  gettingLocation,
  locationSuccess,
  locationError,
  manualEntry,
}

class LocationFlowManager with ChangeNotifier {
  LocationFlowState _currentState = LocationFlowState.initial;
  String _errorMessage = '';
  final LocationViewModel _locationViewModel;

  LocationFlowState get currentState => _currentState;
  String get errorMessage => _errorMessage;
  bool get isLoading =>
      _currentState == LocationFlowState.requestingPermission ||
      _currentState == LocationFlowState.gettingLocation;

  LocationFlowManager(this._locationViewModel);

  // Start the location flow
  Future<void> startFlow() async {
    await _checkInitialPermission();
  }

  // Check if we already have permission
  Future<void> _checkInitialPermission() async {
    try {
      final hasPermission = await PermissionService.checkLocationPermission();
      if (hasPermission) {
        _setState(LocationFlowState.permissionGranted);
      } else {
        _setState(LocationFlowState.initial);
      }
    } catch (e) {
      _setError('Failed to check location permission: $e');
    }
  }

  // Request location permission
  Future<void> requestPermission() async {
    _setState(LocationFlowState.requestingPermission);

    try {
      final granted = await PermissionService.requestLocationPermission();

      if (granted) {
        _setState(LocationFlowState.permissionGranted);
      } else {
        _setState(LocationFlowState.permissionDenied);
        _setError(
          'Location permission is required for current location feature.',
        );
      }
    } catch (e) {
      _setError('Failed to request location permission: $e');
    }
  }

  // Get current location
  Future<void> getCurrentLocation() async {
    _setState(LocationFlowState.gettingLocation);

    try {
      final success = await _locationViewModel.retryAutoLocation();

      if (success) {
        _setState(LocationFlowState.locationSuccess);
      } else {
        _setState(LocationFlowState.locationError);
        _setError(
          'Failed to get current location: ${_locationViewModel.error}',
        );
      }
    } catch (e) {
      _setState(LocationFlowState.locationError);
      _setError('Error getting location: $e');
    }
  }

  // Choose manual entry
  void chooseManualEntry() {
    _setState(LocationFlowState.manualEntry);
  }

  // Retry from error state
  Future<void> retry() async {
    _clearError();
    await startFlow();
  }

  // Open app settings
  void openSettings() {
    PermissionService.openAppSettings();
  }

  // Reset the flow
  void reset() {
    _clearError();
    _setState(LocationFlowState.initial);
  }

  void _setState(LocationFlowState state) {
    _currentState = state;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
