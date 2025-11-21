// lib/features/onboarding/presentation/views/onboarding_page1.dart
import 'package:flutter/material.dart';
import '../../../../core/utils/screen_utils.dart';

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Prevents white flash
      body: Stack(
        children: [
          // Full screen background image covering entire screen
          Positioned.fill(
            child: Image.asset(
              'assets/images/onboarding/onboarding1.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.amber[50]);
              },
            ),
          ),
          // Dark overlay for better text readability
          Container(color: Colors.black.withOpacity(0.3)),
          // Content overlay
          Container(
            padding: ScreenUtils.responsivePadding(
              context,
              mobile: 24,
              tablet: 32,
              desktop: 48,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Where Every Flavor Has Jaan',
                  style: TextStyle(
                    fontSize: ScreenUtils.responsiveFontSize(
                      context,
                      mobile: 24,
                      tablet: 28,
                      desktop: 32,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 10,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ScreenUtils.heightPercent(context, 0.02)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenUtils.widthPercent(context, 0.05),
                  ),
                  child: Text(
                    'From sizzling desi delights to juicy burgers and crispy broast- enjoy a feast full of passion, taste, and comfort. Every dish is cooked fresh, just the way you love it.',
                    style: TextStyle(
                      fontSize: ScreenUtils.responsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 8,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // This space ensures content doesn't overlap with bottom navigation
                SizedBox(height: ScreenUtils.heightPercent(context, 0.15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
