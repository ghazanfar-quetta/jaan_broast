import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'location_flow_manager.dart';
import '../../features/location/presentation/views/location_setup_screen.dart';
import 'package:jaan_broast/features/location/presentation/view_models/location_view_model.dart';

class LocationFlowDialog extends StatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onManualEntry;

  const LocationFlowDialog({Key? key, this.onComplete, this.onManualEntry})
    : super(key: key);

  static Future<void> show({
    required BuildContext context,
    VoidCallback? onComplete,
    VoidCallback? onManualEntry,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationFlowDialog(
        onComplete: onComplete,
        onManualEntry: onManualEntry,
      ),
    );
  }

  @override
  State<LocationFlowDialog> createState() => _LocationFlowDialogState();
}

class _LocationFlowDialogState extends State<LocationFlowDialog> {
  late LocationFlowManager _flowManager;

  @override
  void initState() {
    super.initState();
    final locationViewModel = Provider.of<LocationViewModel>(
      context,
      listen: false,
    );
    _flowManager = LocationFlowManager(locationViewModel);
    _initializeFlow();
  }

  void _initializeFlow() async {
    await _flowManager.startFlow();

    // Listen for completion states
    _flowManager.addListener(() {
      if (_flowManager.currentState == LocationFlowState.locationSuccess) {
        _navigateToSetupScreen(true);
      } else if (_flowManager.currentState == LocationFlowState.manualEntry) {
        _navigateToSetupScreen(false);
      }
    });
  }

  void _navigateToSetupScreen(bool isAutoLocation) {
    Navigator.pop(context); // Close dialog
    widget.onComplete?.call();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LocationSetupScreen(isAutoLocation: isAutoLocation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _flowManager,
      child: Consumer<LocationFlowManager>(
        builder: (context, flowManager, child) {
          return AlertDialog(
            title: _buildTitle(flowManager),
            content: _buildContent(flowManager),
            actions: _buildActions(flowManager),
          );
        },
      ),
    );
  }

  Widget _buildTitle(LocationFlowManager flowManager) {
    switch (flowManager.currentState) {
      case LocationFlowState.initial:
      case LocationFlowState.requestingPermission:
      case LocationFlowState.permissionDenied:
        return const Text('📍 Location Access');
      case LocationFlowState.permissionGranted:
      case LocationFlowState.gettingLocation:
      case LocationFlowState.locationError:
        return const Text('📍 Set Your Location');
      case LocationFlowState.locationSuccess:
      case LocationFlowState.manualEntry:
        return const Text('📍 Location Set');
    }
  }

  Widget _buildContent(LocationFlowManager flowManager) {
    // Show error if exists
    if (flowManager.errorMessage.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    flowManager.errorMessage,
                    style: TextStyle(color: Colors.red[700], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildStateContent(flowManager),
        ],
      );
    }

    return _buildStateContent(flowManager);
  }

  Widget _buildStateContent(LocationFlowManager flowManager) {
    switch (flowManager.currentState) {
      case LocationFlowState.initial:
        return const Text(
          'We need location access to deliver your orders to the right address. '
          'This helps us show you nearby restaurants and accurate delivery times.',
        );

      case LocationFlowState.requestingPermission:
        return const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('Requesting location permission...')),
          ],
        );

      case LocationFlowState.permissionGranted:
        return const Text('How would you like to set your delivery location?');

      case LocationFlowState.permissionDenied:
        return const Text(
          'Location permission is required for the current location feature. '
          'You can enable it in settings or enter your address manually.',
        );

      case LocationFlowState.gettingLocation:
        return const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('Getting your current location...')),
          ],
        );

      case LocationFlowState.locationError:
        return const Text(
          'We couldn\'t access your current location. '
          'Please try again or enter your address manually.',
        );

      case LocationFlowState.locationSuccess:
        return const Text('Location set successfully!');

      case LocationFlowState.manualEntry:
        return const Text('You can enter your address manually.');
    }
  }

  List<Widget> _buildActions(LocationFlowManager flowManager) {
    switch (flowManager.currentState) {
      case LocationFlowState.initial:
        return [
          TextButton(
            onPressed: () => flowManager.chooseManualEntry(),
            child: const Text('Enter Manually'),
          ),
          ElevatedButton(
            onPressed: () => flowManager.requestPermission(),
            child: const Text('Allow Location'),
          ),
        ];

      case LocationFlowState.requestingPermission:
        return [];

      case LocationFlowState.permissionGranted:
        return [
          TextButton(
            onPressed: () => flowManager.chooseManualEntry(),
            child: const Text('Enter Manually'),
          ),
          ElevatedButton(
            onPressed: () => flowManager.getCurrentLocation(),
            child: const Text('Use Current Location'),
          ),
        ];

      case LocationFlowState.permissionDenied:
        return [
          TextButton(
            onPressed: () => flowManager.chooseManualEntry(),
            child: const Text('Enter Manually'),
          ),
          TextButton(
            onPressed: () => flowManager.openSettings(),
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => flowManager.retry(),
            child: const Text('Try Again'),
          ),
        ];

      case LocationFlowState.gettingLocation:
        return [];

      case LocationFlowState.locationError:
        return [
          TextButton(
            onPressed: () => flowManager.chooseManualEntry(),
            child: const Text('Enter Manually'),
          ),
          ElevatedButton(
            onPressed: () => flowManager.retry(),
            child: const Text('Try Again'),
          ),
        ];

      case LocationFlowState.locationSuccess:
      case LocationFlowState.manualEntry:
        return [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ];
    }
  }

  @override
  void dispose() {
    _flowManager.dispose();
    super.dispose();
  }
}
