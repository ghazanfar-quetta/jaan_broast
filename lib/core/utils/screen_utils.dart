// lib/core/utils/screen_utils.dart
import 'package:flutter/material.dart';

class ScreenUtils {
  // Screen dimensions
  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Screen type detection
  static bool isMobile(BuildContext context) => getScreenWidth(context) < 600;
  static bool isTablet(BuildContext context) =>
      getScreenWidth(context) >= 600 && getScreenWidth(context) < 1200;
  static bool isDesktop(BuildContext context) =>
      getScreenWidth(context) >= 1200;

  // Responsive value selector
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive padding
  static EdgeInsets responsivePadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    final value = responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
    return EdgeInsets.all(value);
  }

  // Responsive font size
  static double responsiveFontSize(
    BuildContext context, {
    double mobile = 16,
    double tablet = 18,
    double desktop = 20,
  }) {
    return responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Percentage-based dimensions
  static double heightPercent(BuildContext context, double percent) =>
      getScreenHeight(context) * percent;

  static double widthPercent(BuildContext context, double percent) =>
      getScreenWidth(context) * percent;

  // Safe area dimensions
  static double safeAreaHeight(BuildContext context) =>
      getScreenHeight(context) -
      MediaQuery.of(context).padding.top -
      MediaQuery.of(context).padding.bottom;
}
