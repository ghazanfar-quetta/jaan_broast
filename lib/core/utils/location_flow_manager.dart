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
  bool _hasCompletedFlow = false; // NEW: Track if flow completed

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
      // Use the improved method that ensures saving
      final success = await _locationViewModel.getCurrentLocationOnce();

      if (success) {
        // IMPORTANT: Add a small delay to ensure location is saved
        await Future.delayed(Duration(milliseconds: 500));

        // Verify location was actually saved
        final isLocationSet = _locationViewModel.isLocationSet;
        print('📍 FlowManager: Location set? $isLocationSet');

        if (isLocationSet) {
          _setState(LocationFlowState.locationSuccess);
          _hasCompletedFlow = true;
        } else {
          _setError("Location fetched but not saved properly");
          _setState(LocationFlowState.locationError);
        }
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
    _hasCompletedFlow = true;
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

  /// Check if flow has been completed
  bool get hasCompletedFlow => _hasCompletedFlow;
}
