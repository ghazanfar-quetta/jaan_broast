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
          return AlertDialog(
            title: _buildTitle(flowManager),
            content: _buildContent(flowManager),
            actions: _buildActions(flowManager),
          );
        },
      ),
    );
  }

  // ----------- UI BUILDERS --------------

  Widget _buildTitle(LocationFlowManager flowManager) {
    return const Text('📍 Set Your Location');
  }

  Widget _buildContent(LocationFlowManager flowManager) {
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
    if (flowManager.currentState == LocationFlowState.requestingPermission ||
        flowManager.currentState == LocationFlowState.gettingLocation) {
      return const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
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
    );
  }

  List<Widget> _buildActions(LocationFlowManager flowManager) {
    if (flowManager.isLoading) return [];

    return [
      TextButton(
        onPressed: flowManager.chooseManualEntry,
        child: const Text("Enter Manually"),
      ),

      ElevatedButton(
        onPressed: () => flowManager.requestPermissionAndFetchLocation(),
        child: const Text("Use Current Location"),
      ),
    ];
  }

  @override
  void dispose() {
    _flowManager.dispose();
    super.dispose();
  }
}
