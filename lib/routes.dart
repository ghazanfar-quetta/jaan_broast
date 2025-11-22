// lib/routes.dart
import 'package:flutter/material.dart';

// Import all your screens
import 'features/splash/presentation/views/splash_screen.dart';
import 'features/onboarding/presentation/views/onboarding_screen.dart';
import 'features/auth/presentation/views/sign_up_screen.dart';
import 'features/home/presentation/views/home_screen.dart';
import 'features/auth/presentation/views/sign_up_form_screen.dart';

// Import permission service
import 'core/services/permission_service.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String menu = '/menu';
  static const String foodDetail = '/food-detail';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String profile = '/profile';
  static const String orders = '/orders';
  static const String orderTracking = '/order-tracking';
  static const String addresses = '/addresses';
  static const String favorites = '/favorites';
  static const String signUpForm = '/sign-up-form';

  // Permission service getter for easy access
  static PermissionService get permissions => PermissionService();

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case signUpForm:
        return MaterialPageRoute(builder: (_) => const SignUpFormScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case auth:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      // TODO: Add routes for remaining screens as you build them
      /*
      case menu:
        return MaterialPageRoute(builder: (_) => const MenuScreen());
      
      case foodDetail:
        final arguments = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => FoodDetailScreen(
            foodId: arguments?['foodId'],
            foodItem: arguments?['foodItem'],
          ),
        );
      
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      
      case checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());
      
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      
      case orderTracking:
        final orderId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderId),
        );
      
      case addresses:
        return MaterialPageRoute(builder: (_) => const AddressesScreen());
      
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      */

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  // Navigation methods
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(
      context,
    ).pushReplacementNamed<T, TO>(routeName, arguments: arguments);
  }

  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
      routeName,
      predicate ?? (_) => false, // Fixed: Use constant default
      arguments: arguments,
    );
  }

  // Convenience method for removing all routes
  static Future<T?> pushAndRemoveAll<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false, // Remove all routes
      arguments: arguments,
    );
  }

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  static Future<T?> pushMaterialPage<T extends Object?>(
    BuildContext context,
    Widget page, {
    String? routeName,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (_) => page,
        settings: RouteSettings(name: routeName),
      ),
    );
  }

  // Utility methods for common navigation patterns
  static void popToRoot(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static Future<bool?> maybePop(BuildContext context) {
    return Navigator.of(context).maybePop();
  }
}
