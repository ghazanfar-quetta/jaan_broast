// lib/core/utils/location_flow_manager.dart

import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../../features/location/presentation/view_models/location_view_model.dart';

enum LocationFlowState {
  initial,
  requestingPermission,
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

  /// Start flow — always show initial prompt
  Future<void> startFlow() async {
    _setState(LocationFlowState.initial);
  }

  /// User tapped: "Use Current Location"
  Future<void> requestPermission() async {
    _setState(LocationFlowState.requestingPermission);

    try {
      final granted = await PermissionService.requestLocationPermission();

      if (!granted) {
        // Stay on same dialog with a message (no new screen)
        _setError("Location permission is required to use current location");
        _setState(LocationFlowState.initial);
        return;
      }

      // Immediately fetch location
      await getCurrentLocation();
    } catch (e) {
      _setError("Failed to request location permission: $e");
      _setState(LocationFlowState.initial);
    }
  }

  /// Fetch current location immediately after permission
  Future<void> getCurrentLocation() async {
    _setState(LocationFlowState.gettingLocation);

    try {
      final success = await _locationViewModel.retryAutoLocation();

      if (success) {
        _setState(LocationFlowState.locationSuccess);
      } else {
        _setError("Failed to get current location");
        _setState(LocationFlowState.locationError);
      }
    } catch (e) {
      _setError("Error getting location: $e");
      _setState(LocationFlowState.locationError);
    }
  }

  /// User chooses manual entry
  void chooseManualEntry() {
    _setState(LocationFlowState.manualEntry);
  }

  /// Retry from error
  Future<void> retry() async {
    _clearError();
    await startFlow();
  }

  /// State updates
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

  /// Requests permission if needed, then fetches current location
  Future<void> requestPermissionAndFetchLocation() async {
    try {
      // Check if we already have permission
      final hasPermission = await PermissionService.checkLocationPermission();

      if (!hasPermission) {
        final granted = await PermissionService.requestLocationPermission();
        if (!granted) {
          _setError(
            'Location permission is required for current location feature.',
          );
          return;
        }
      }

      // Now get the location
      await getCurrentLocation();
    } catch (e) {
      _setError('Failed to get location: $e');
    }
  }
}
