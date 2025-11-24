import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/local_storage_service.dart';
import '../../features/auth/presentation/view_models/auth_view_model.dart';
import 'location_flow_dialog.dart';

class LocationNavigationHelper {
  static Future<void> handlePostLoginNavigation(
    BuildContext context,
    User user,
  ) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // Check if this is first login
    final needsLocationInit = await authViewModel.needsLocationInitialization(
      user,
    );

    if (needsLocationInit) {
      // Show location flow dialog
      await LocationFlowDialog.show(
        context: context,
        onComplete: () {
          // Mark first login as completed
          authViewModel.completeFirstLogin();
        },
      );
    } else {
      // Returning user - go directly to home
      _navigateToHome(context);
    }
  }

  static void _navigateToHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/home');
  }
}
