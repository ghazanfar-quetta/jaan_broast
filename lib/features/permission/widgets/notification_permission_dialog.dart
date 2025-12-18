// Update your existing notification_permission_dialog.dart file
import 'package:flutter/material.dart';
import 'package:jaan_broast/core/services/permission_service.dart';
import 'package:jaan_broast/core/services/local_storage_service.dart'; // ADD THIS
import 'package:jaan_broast/core/utils/screen_utils.dart'; // ADD THIS

class NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback onComplete;

  const NotificationPermissionDialog({Key? key, required this.onComplete})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_active,
              size: 60,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'Enable Notifications',
              style: TextStyle(
                fontSize: ScreenUtils.responsiveFontSize(
                  context,
                  mobile: 22,
                  tablet: 24,
                  desktop: 26,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Stay updated with:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ScreenUtils.responsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            _buildFeature(
              context,
              '🎉 Order confirmations & status updates',
            ), // Pass context
            _buildFeature(
              context,
              '🔥 Exclusive offers & promotions',
            ), // Pass context
            _buildFeature(
              context,
              '📍 Delivery updates & restaurant news',
            ), // Pass context
            const SizedBox(height: 16),
            Text(
              'You can change this anytime in Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ScreenUtils.responsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      // Save "Maybe Later" choice
                      await LocalStorageService.setOnboardingNotificationPreference(
                        false,
                      );
                      await LocalStorageService.setHasSetNotificationPreference(
                        true,
                      );
                      print(
                        '🔔 User chose: Maybe Later (Notifications disabled)',
                      );
                      Navigator.pop(context);
                      onComplete();
                    },
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        fontSize: ScreenUtils.responsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Save "Allow" choice
                      await LocalStorageService.setOnboardingNotificationPreference(
                        true,
                      );
                      await LocalStorageService.setHasSetNotificationPreference(
                        true,
                      );

                      // Request actual permission
                      final granted =
                          await PermissionService.requestNotificationPermission();
                      if (granted) {
                        print('✅ User allowed notifications');
                      } else {
                        print('⚠️ User declined notification permission');
                      }

                      Navigator.pop(context);
                      onComplete();
                    },
                    child: Text(
                      'Allow',
                      style: TextStyle(
                        fontSize: ScreenUtils.responsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(BuildContext context, String text) {
    // ADD BuildContext parameter
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: ScreenUtils.responsiveFontSize(
                  context, // Now context is available
                  mobile: 13,
                  tablet: 14,
                  desktop: 15,
                ),
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
