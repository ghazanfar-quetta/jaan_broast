// lib/core/utils/location_flow_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jaan_broast/core/utils/location_flow_manager.dart';
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
    final locationVM = Provider.of<LocationViewModel>(context, listen: false);
    _flowManager = LocationFlowManager(locationVM);
    _initializeFlow();
  }

  void _initializeFlow() async {
    await _flowManager.startFlow();

    _flowManager.addListener(() {
      final state = _flowManager.currentState;
      if (state == LocationFlowState.locationSuccess) {
        _navigateToSetupScreen(true);
      } else if (state == LocationFlowState.manualEntry) {
        _navigateToSetupScreen(false);
      }
    });
  }

  void _navigateToSetupScreen(bool isAutoLocation) {
    Navigator.pop(context);
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
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            backgroundColor: Theme.of(context).colorScheme.background,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Set Your Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Content
                  _buildContent(flowManager),
                  const SizedBox(height: 24),

                  // Actions
                  ..._buildActions(flowManager),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(LocationFlowManager flowManager) {
    if (flowManager.errorMessage.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    flowManager.errorMessage,
                    style: TextStyle(color: Colors.orange[700], fontSize: 14),
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
    if (flowManager.isLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 16),
          Expanded(child: Text("Processing...")),
        ],
      );
    }

    return const Text(
      "Choose how you want to set your delivery location.\n"
      "Use your current location or enter it manually.",
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 14, height: 1.4),
    );
  }

  List<Widget> _buildActions(LocationFlowManager flowManager) {
    if (flowManager.isLoading) return [];

    return [
      // Current Location Button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _handleCurrentLocation(flowManager),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: const Text(
            "Use Current Location",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      const SizedBox(height: 12),

      // Manual Entry Button
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: flowManager.chooseManualEntry,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: Theme.of(context).primaryColor),
          ),
          child: const Text(
            "Enter Manually",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ];
  }

  void _handleCurrentLocation(LocationFlowManager flowManager) {
    if (flowManager.currentState == LocationFlowState.initial) {
      flowManager.requestPermission();
    } else {
      flowManager.getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _flowManager.dispose();
    super.dispose();
  }
}
