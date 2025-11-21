// lib/features/onboarding/presentation/views/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/screen_utils.dart';
import '../../../../core/services/local_storage_service.dart';
import '../view_models/onboarding_view_model.dart';
import 'onboarding_page1.dart';
import 'onboarding_page2.dart';
import 'onboarding_page3.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final currentPage = _pageController.page?.round() ?? 0;
    final viewModel = Provider.of<OnboardingViewModel>(context, listen: false);
    if (currentPage != viewModel.currentPage) {
      viewModel.setCurrentPage(currentPage);
    }
  }

  void _navigateToAuth() async {
    await LocalStorageService.setHasSeenOnboarding(true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<OnboardingViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // PageView that extends behind everything
          PageView(
            controller: _pageController,
            onPageChanged: (index) => viewModel.setCurrentPage(index),
            children: const [
              OnboardingPage1(),
              OnboardingPage2(),
              OnboardingPage3(),
            ],
          ),
          // Bottom navigation overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigation(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(OnboardingViewModel viewModel) {
    return Container(
      padding: EdgeInsets.all(
        ScreenUtils.responsiveValue(
          context,
          mobile: 20,
          tablet: 24,
          desktop: 32,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: ScreenUtils.responsiveValue(
                    context,
                    mobile: 4,
                    tablet: 6,
                    desktop: 8,
                  ),
                ),
                width: ScreenUtils.responsiveValue(
                  context,
                  mobile: 8,
                  tablet: 10,
                  desktop: 12,
                ),
                height: ScreenUtils.responsiveValue(
                  context,
                  mobile: 8,
                  tablet: 10,
                  desktop: 12,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: viewModel.currentPage == index
                      ? Colors.amber[700]
                      : Colors.white.withOpacity(0.7),
                ),
              );
            }),
          ),

          if (viewModel.currentPage < 2)
            TextButton(
              onPressed: _navigateToAuth,
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: ScreenUtils.responsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: _navigateToAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenUtils.responsiveValue(
                    context,
                    mobile: 24,
                    tablet: 32,
                    desktop: 40,
                  ),
                  vertical: ScreenUtils.responsiveValue(
                    context,
                    mobile: 12,
                    tablet: 14,
                    desktop: 16,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Get Started',
                style: TextStyle(
                  fontSize: ScreenUtils.responsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
