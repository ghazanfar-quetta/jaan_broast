import 'package:flutter/material.dart';
import 'app_constants.dart';

class ButtonStyles {
  static ButtonStyle primaryButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
        vertical: AppConstants.paddingMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      elevation: 2,
      textStyle: const TextStyle(
        fontSize: AppConstants.bodyTextSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static ButtonStyle secondaryButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
        vertical: AppConstants.paddingMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(color: Theme.of(context).primaryColor),
      ),
      elevation: 0,
      textStyle: const TextStyle(
        fontSize: AppConstants.bodyTextSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static ButtonStyle textButton(BuildContext context) {
    return TextButton.styleFrom(
      foregroundColor: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      textStyle: const TextStyle(
        fontSize: AppConstants.bodyTextSize,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
