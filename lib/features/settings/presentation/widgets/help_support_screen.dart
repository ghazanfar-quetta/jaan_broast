import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/utils/screen_utils.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import 'package:flutter/services.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'How do I place an order?',
      answer:
          'To place an order:\n1. Browse menu items\n2. Add items to your cart\n3. Select order portion size\n4. Choose order type (COD, Take Away, Dine In)\n5. Confirm your order',
    ),
    FAQItem(
      question: 'What are your order hours?',
      answer:
          'We deliver daily from 7:00 AM to 12:00 AM. Some restaurants may have different hours which will be shown on their menu.',
    ),
    FAQItem(
      question: 'How can I track my order?',
      answer:
          'You can track your order in real-time from the "Orders" section in the app. You\'ll see updates from restaurant preparation to delivery.',
    ),
    FAQItem(
      question: 'What payment methods do you accept?',
      answer:
          'We accept:\n• Cash on Delivery\n• Credit/Debit Cards\n• Bank Transfers',
    ),
    FAQItem(
      question: 'Can I modify or cancel my order?',
      answer:
          'You can modify or cancel your order within 5 minutes of placing it. After that, please contact our support team immediately.',
    ),
  ];

  final Map<int, bool> _expandedItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: CustomAppBar(title: 'Help & Support', showBackButton: true),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
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
          _buildHeader(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Contact Section
          _buildContactSection(),
          const SizedBox(height: AppConstants.paddingLarge),

          // FAQ Section
          _buildFaqSection(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Business Hours
          _buildBusinessHours(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Social Media (Optional)
          _buildSocialMedia(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'We\'re Here to Help!',
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
          'Get assistance with orders, account issues, or any questions you may have. Our team is available to help you 24/7.',
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
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Options',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.headingSizeMedium,
              tablet: AppConstants.headingSizeMedium,
              desktop: AppConstants.headingSizeMedium,
            ),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),

        // Support Email
        _buildContactCard(
          icon: Icons.email_outlined,
          title: 'Support Email',
          subtitle: 'jaanbroast42@gmail.com',
          description: 'Send us an email for non-urgent inquiries',
          onTap: _launchEmail,
        ),
        const SizedBox(height: AppConstants.paddingMedium),

        // Support Phone
        _buildContactCard(
          icon: Icons.phone_outlined,
          title: 'Support Phone',
          subtitle: '+92 311 1786550',
          description: 'Call us for urgent order issues',
          onTap: _launchPhone,
        ),
        const SizedBox(height: AppConstants.paddingMedium),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ScreenUtils.responsiveFontSize(
                          context,
                          mobile: AppConstants.bodyTextSize,
                          tablet: AppConstants.bodyTextSize,
                          desktop: AppConstants.bodyTextSize,
                        ),
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: ScreenUtils.responsiveFontSize(
                          context,
                          mobile: AppConstants.bodyTextSize,
                          tablet: AppConstants.bodyTextSize,
                          desktop: AppConstants.bodyTextSize,
                        ),
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: ScreenUtils.responsiveFontSize(
                          context,
                          mobile: AppConstants.captionTextSize,
                          tablet: AppConstants.bodyTextSize,
                          desktop: AppConstants.bodyTextSize,
                        ),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.headingSizeMedium,
              tablet: AppConstants.headingSizeMedium,
              desktop: AppConstants.headingSizeMedium,
            ),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),

        ..._faqItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isExpanded = _expandedItems[index] ?? false;

          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: ExpansionTile(
              key: Key('faq_$index'),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedItems[index] = expanded;
                });
              },
              leading: Icon(
                Icons.help_outline,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(
                item.question,
                style: TextStyle(
                  fontSize: ScreenUtils.responsiveFontSize(
                    context,
                    mobile: AppConstants.bodyTextSize,
                    tablet: AppConstants.bodyTextSize,
                    desktop: AppConstants.bodyTextSize,
                  ),
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.paddingLarge,
                    0,
                    AppConstants.paddingLarge,
                    AppConstants.paddingMedium,
                  ),
                  child: Text(
                    item.answer,
                    style: TextStyle(
                      fontSize: ScreenUtils.responsiveFontSize(
                        context,
                        mobile: AppConstants.bodyTextSize,
                        tablet: AppConstants.bodyTextSize,
                        desktop: AppConstants.bodyTextSize,
                      ),
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBusinessHours() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Text(
                  'Business Hours',
                  style: TextStyle(
                    fontSize: ScreenUtils.responsiveFontSize(
                      context,
                      mobile: AppConstants.bodyTextSize,
                      tablet: AppConstants.bodyTextSize,
                      desktop: AppConstants.bodyTextSize,
                    ),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildBusinessHourRow('Monday - Sunday', ""),
            _buildBusinessHourRow('7:00 AM - 12:00 AM', ""),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Note: Delivery hours may vary during holidays',
              style: TextStyle(
                fontSize: ScreenUtils.responsiveFontSize(
                  context,
                  mobile: AppConstants.captionTextSize,
                  tablet: AppConstants.bodyTextSize,
                  desktop: AppConstants.bodyTextSize,
                ),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHourRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
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
          Text(
            hours,
            style: TextStyle(
              fontSize: ScreenUtils.responsiveFontSize(
                context,
                mobile: AppConstants.bodyTextSize,
                tablet: AppConstants.bodyTextSize,
                desktop: AppConstants.bodyTextSize,
              ),
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMedia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Follow Us',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.headingSizeMedium,
              tablet: AppConstants.headingSizeMedium,
              desktop: AppConstants.headingSizeMedium,
            ),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSocialIcon(Icons.facebook, 'Facebook'),
            _buildSocialIcon(Icons.camera_alt_outlined, 'Instagram'),
            _buildSocialIcon(Icons.sms_outlined, 'WhatsApp'),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.captionTextSize,
              tablet: AppConstants.bodyTextSize,
              desktop: AppConstants.bodyTextSize,
            ),
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail() async {
    final String email = 'jaanbroast42@gmail.com';

    final String subject = Uri.encodeComponent('Support Request - Jaan Broast');
    final String body = Uri.encodeComponent('Hello,\n\nI need help with');

    final Uri emailUri = Uri.parse('mailto:$email?subject=$subject&body=$body');

    print("📧 Trying to launch: $emailUri");

    try {
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showEmailFallback(context, email);
      }
    } catch (e) {
      _showEmailFallback(context, email);
    }
  }

  Future<bool> _tryLaunchEmail(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      print('Email launch attempt failed: $e');
    }
    return false;
  }

  Future<void> _launchPhone() async {
    try {
      final phoneNumber = '+923111786550';
      final String phoneUrl = 'tel:$phoneNumber';

      print('📞 Launching phone URL: $phoneUrl');

      if (await canLaunchUrl(Uri.parse(phoneUrl))) {
        await launchUrl(
          Uri.parse(phoneUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('❌ Could not launch phone');
        _showPhoneFallback(context, phoneNumber);
      }
    } catch (e) {
      print('❌ Phone launch error: $e');
      _showPhoneFallback(context, '+92 326 2669988');
    }
  }

  void _showEmailFallback(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email App Not Found'),
        content: Text('Please send your email to: $email'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Copy to clipboard
              Clipboard.setData(ClipboardData(text: email));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _showPhoneFallback(BuildContext context, String phone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phone App Not Found'),
        content: Text('Please call: $phone'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Copy to clipboard
              Clipboard.setData(ClipboardData(text: phone));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone number copied to clipboard'),
                ),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
