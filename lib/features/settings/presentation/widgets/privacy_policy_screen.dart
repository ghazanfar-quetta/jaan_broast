import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/utils/screen_utils.dart';
import '../../../../../core/widgets/custom_app_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: CustomAppBar(title: 'Privacy Policy', showBackButton: true),
      body: _buildContent(context), // PASS CONTEXT HERE
    );
  }

  Widget _buildContent(BuildContext context) {
    // ADD CONTEXT PARAMETER
    return SingleChildScrollView(
      padding: ScreenUtils.responsivePadding(
        context,
        mobile: AppConstants.paddingLarge,
        tablet: AppConstants.paddingLarge,
        desktop: AppConstants.paddingLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context), // PASS CONTEXT
          const SizedBox(height: AppConstants.paddingLarge),

          // Privacy Policy Sections
          _buildSection(
            context: context, // PASS CONTEXT
            title: '1. Information We Collect',
            content: '''
We collect information to provide better services to all our users. The information we collect includes:

• Personal Information: When you create an account, we collect your name, email address, phone number, and delivery addresses.

• Order Information: We collect information about your food orders, including items ordered, delivery preferences, and payment details.

• Location Data: We collect your location information to show nearby restaurants and enable food delivery to your address.

• Device Information: We collect device-specific information such as your device type, operating system, and unique device identifiers.
''',
          ),

          _buildSection(
            context: context, // PASS CONTEXT
            title: '2. How We Use Your Information',
            content: '''
We use the information we collect for the following purposes:

• To provide and improve our food delivery services
• To process your orders and deliver food to your location
• To personalize your experience and restaurant recommendations
• To communicate with you about orders, promotions, and updates
• To ensure the security and safety of our services
• To comply with legal obligations
''',
          ),

          _buildSection(
            context: context, // PASS CONTEXT
            title: '3. Information Sharing',
            content: '''
We do not sell your personal information to third parties. We may share your information in the following circumstances:

• With restaurants to fulfill your food orders
• With delivery partners to deliver your orders
• With payment processors to complete transactions
• When required by law or to protect our rights
• With your consent for specific purposes

We require all third parties to respect the security of your personal data and to treat it in accordance with the law.
''',
          ),

          _buildSection(
            context: context, // PASS CONTEXT
            title: '4. Data Security',
            content: '''
We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. These measures include:

• Encryption of sensitive data during transmission
• Secure storage of personal information
• Regular security assessments and updates
• Access controls and authentication procedures

While we strive to protect your personal information, no method of transmission over the Internet or electronic storage is 100% secure.
''',
          ),

          _buildSection(
            context: context, // PASS CONTEXT
            title: '5. Your Rights',
            content: '''
You have the following rights regarding your personal information:

• Access: You can request access to the personal information we hold about you.
• Correction: You can request correction of inaccurate or incomplete information.
• Deletion: You can request deletion of your personal information in certain circumstances.
• Objection: You can object to the processing of your personal information.
• Portability: You can request a copy of your data in a machine-readable format.

To exercise these rights, please contact us using the information provided below.
''',
          ),

          _buildSection(
            context: context, // PASS CONTEXT
            title: '6. Data Retention',
            content: '''
We retain your personal information only for as long as necessary to fulfill the purposes for which we collected it, including for the purposes of satisfying any legal, accounting, or reporting requirements.

• Account information: Retained while your account is active
• Order history: Retained for 3 years for customer service purposes
• Location data: Retained only during active delivery sessions
• Payment information: Processed immediately and not stored on our servers
''',
          ),

          _buildSection(
            context: context, // PASS CONTEXT
            title: '7. Children\'s Privacy',
            content: '''
Our services are not directed to individuals under the age of 16. We do not knowingly collect personal information from children under 16. If we become aware that a child under 16 has provided us with personal information, we will take steps to delete such information.

If you become aware that a child has provided us with personal information, please contact us immediately.
''',
          ),

          _buildSection(
            context: context, // PASS CONTEXT
            title: '8. Changes to This Policy',
            content: '''
We may update this Privacy Policy from time to time to reflect changes in our practices or for other operational, legal, or regulatory reasons. We will notify you of any material changes by:

• Posting the new Privacy Policy in the app
• Sending you a notification through the app
• Updating the "Last Updated" date at the bottom of this policy

We encourage you to review this Privacy Policy periodically to stay informed about our information practices.
''',
          ),

          _buildSection(
            context: context, // PASS CONTEXT
            title: '9. Contact Us',
            content: '''
If you have any questions or concerns about this Privacy Policy or our data practices, please contact us:

• Email: privacy@jaanbroast.com
• Phone: +92-XXX-XXXXXXX
• Address: [Your Business Address]
• In-app: Through the Help & Support section

We will respond to your inquiry within 48 hours.
''',
          ),

          // _buildLastUpdated(context), // PASS CONTEXT
          const SizedBox(height: AppConstants.paddingLarge),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // ADD CONTEXT PARAMETER
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.headingSizeLarge,
              tablet: AppConstants.headingSizeLarge,
              desktop: AppConstants.headingSizeLarge + 4,
            ),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        Text(
          'Last Updated: ${_getCurrentDate()}',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.bodyTextSize,
              tablet: AppConstants.bodyTextSize,
              desktop: AppConstants.bodyTextSize,
            ),
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Text(
          'At Jaan Broast, we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, and safeguard your information when you use our food delivery app.',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.bodyTextSize,
              tablet: AppConstants.bodyTextSize,
              desktop: AppConstants.bodyTextSize,
            ),
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    // ADD CONTEXT PARAMETER
    required BuildContext context,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppConstants.paddingLarge),
        Text(
          title,
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.headingSizeSmall,
              tablet: AppConstants.headingSizeMedium,
              desktop: AppConstants.headingSizeMedium,
            ),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        Text(
          content,
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.bodyTextSize,
              tablet: AppConstants.bodyTextSize,
              desktop: AppConstants.bodyTextSize,
            ),
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  //  Widget _buildLastUpdated(BuildContext context) {
  // ADD CONTEXT PARAMETER
  //    return Container(
  //      width: double.infinity,
  //      padding: const EdgeInsets.all(AppConstants.paddingMedium),
  //      decoration: BoxDecoration(
  //        color: Theme.of(context).primaryColor.withOpacity(0.1),
  //        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
  //      ),
  //      child: Text(
  //        'This Privacy Policy was last updated on ${_getCurrentDate()}.',
  //        style: TextStyle(
  //          fontSize: ScreenUtils.responsiveFontSize(
  //            context,
  //            mobile: AppConstants.captionTextSize,
  //            tablet: AppConstants.bodyTextSize,
  //            desktop: AppConstants.bodyTextSize,
  //          ),
  //          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
  //          fontStyle: FontStyle.italic,
  //        ),
  //        textAlign: TextAlign.center,
  //      ),
  //    );
  //  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}
