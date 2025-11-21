// lib/features/onboarding/presentation/view_models/onboarding_view_model.dart
import 'package:flutter/material.dart';

class OnboardingViewModel with ChangeNotifier {
  int _currentPage = 0;
  final PageController pageController = PageController();

  int get currentPage => _currentPage;

  void setCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage < 2) {
      _currentPage++;
      pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void skipToEnd() {
    _currentPage = 2;
    pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    notifyListeners();
  }

  void navigateToAuth(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
