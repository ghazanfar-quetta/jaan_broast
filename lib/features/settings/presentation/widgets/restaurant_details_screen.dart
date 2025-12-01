import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/screen_utils.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class RestaurantDetailsScreen extends StatelessWidget {
  const RestaurantDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Restaurant Details', showBackButton: true),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ScreenUtils.responsiveValue(
            context,
            mobile: AppConstants.paddingLarge,
            tablet: AppConstants.paddingLarge * 1.5,
            desktop: AppConstants.paddingLarge * 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.topCenter,
              children: [
                // Restaurant Image Placeholder
                Container(
                  margin: EdgeInsets.only(
                    top: 60,
                  ), // Space for overlapping logo
                  child: _buildRestaurantImage(context),
                ),

                // Circular Logo (50% overlap)
                Positioned(
                  top: 10, // Half above, half below
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orangeAccent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.asset(
                        'assets/images/onboarding/logo.png', // Update with your logo path
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if logo fails to load
                          return Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 40,
                              color: Theme.of(context).primaryColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.paddingSmall),

            // Decorative Divider
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    thickness: 1,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.paddingSmall),

            // Delivery Info Row
            _buildDeliveryInfoRow(context),

            SizedBox(height: AppConstants.paddingSmall),

            // Decorative Divider
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 20,
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    thickness: 1,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.paddingSmall),

            // Location Image Placeholder
            _buildLocationImage(context),

            SizedBox(height: AppConstants.paddingSmall),

            // Location Details
            _buildLocationDetails(context),

            SizedBox(height: AppConstants.paddingSmall),

            // Decorative Divider
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingSmall,
                  ),
                  child: Icon(
                    Icons.contact_phone,
                    size: 20,
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    thickness: 1,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.paddingSmall),

            // Contact Options Title
            Text(
              'Contact Options',
              style: TextStyle(
                fontSize: AppConstants.headingSizeSmall,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),

            SizedBox(height: AppConstants.paddingSmall),

            // WhatsApp Contact Card
            _buildContactCard(
              context: context,
              icon: FontAwesomeIcons.whatsapp,
              title: 'Live Chat',
              subtitle: '+92 326 2669988',
              onTap: () => _openWhatsApp('+923262669988'),
              iconColor: const Color(0xFF25D366), // WhatsApp green
            ),

            SizedBox(height: AppConstants.paddingSmall),
            buildOpeningHoursCard(context),
            SizedBox(height: AppConstants.paddingSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: ScreenUtils.heightPercent(context, 0.25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Image.asset(
          'assets/images/restaurants/restaurant_dining.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image fails to load
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 60,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    'Jaan Broast Restaurant',
                    style: TextStyle(
                      fontSize: AppConstants.headingSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoRow(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDeliveryInfoItem(
              context: context,
              icon: Icons.delivery_dining,
              title: 'Delivery Charges',
              value: 'Rs. 150',
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            margin: EdgeInsets.symmetric(horizontal: AppConstants.paddingSmall),
          ),
          Expanded(
            child: _buildDeliveryInfoItem(
              context: context,
              icon: Icons.access_time,
              title: 'Delivery Time',
              value: '30 - 45 min',
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color backgroundColor,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(AppConstants.paddingSmall),
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        ),
        SizedBox(height: AppConstants.paddingSmall),
        Text(
          title,
          style: TextStyle(
            fontSize: AppConstants.captionTextSize,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: AppConstants.headingSizeSmall,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: ScreenUtils.heightPercent(context, 0.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Image.asset(
          'assets/images/locations/restaurant_location.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image fails to load
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    'Restaurant Location',
                    style: TextStyle(
                      fontSize: AppConstants.captionTextSize,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationDetails(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppConstants.paddingSmall),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadius / 2,
              ),
            ),
            child: Icon(
              Icons.location_on_outlined,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(width: AppConstants.paddingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: AppConstants.captionTextSize,
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Prince Road, Quetta',
                  style: TextStyle(
                    fontSize: AppConstants.bodyTextSize,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppConstants.paddingSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppConstants.paddingSmall),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadius / 2,
                ),
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            SizedBox(width: AppConstants.paddingSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppConstants.captionTextSize,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppConstants.bodyTextSize,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 24,
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    // Remove all spaces, +, and special chars from number
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // WhatsApp API URL
    final url = Uri.parse('https://wa.me/$cleanNumber');

    // Direct WhatsApp app deep link
    final whatsappApp = Uri.parse('whatsapp://send?phone=$cleanNumber&text=');

    try {
      // 1️⃣ Try launching WhatsApp app directly
      if (await canLaunchUrl(whatsappApp)) {
        await launchUrl(whatsappApp, mode: LaunchMode.externalApplication);
        return;
      }

      // 2️⃣ Fallback to wa.me link (browser → WhatsApp)
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }

      print('❌ WhatsApp not installed.');
    } catch (e) {
      print('Error launching WhatsApp: $e');
    }
  }

  Widget buildOpeningHoursCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Row(
        children: [
          // Icon Box (same as contact card)
          Container(
            padding: EdgeInsets.all(AppConstants.paddingSmall),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadius / 2,
              ),
            ),
            child: Icon(
              Icons.access_time,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
          ),

          SizedBox(width: AppConstants.paddingSmall),

          // Texts
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Open Till',
                style: TextStyle(
                  fontSize: AppConstants.captionTextSize,
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 4),
              Text(
                '12:00 AM',
                style: TextStyle(
                  fontSize: AppConstants.bodyTextSize,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
