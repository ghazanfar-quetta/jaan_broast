import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/view_models/auth_view_model.dart';
import '../../features/home/presentation/view_models/home_view_model.dart';
import '../../features/location/presentation/view_models/location_view_model.dart';
import '../../features/onboarding/presentation/view_models/onboarding_view_model.dart';
import '../../features/favorites/presentation/view_models/favorites_view_model.dart';

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthViewModel()),
        ChangeNotifierProvider(create: (context) => HomeViewModel()),
        ChangeNotifierProvider(create: (context) => LocationViewModel()),
        ChangeNotifierProvider(create: (context) => OnboardingViewModel()),
        ChangeNotifierProvider(create: (context) => FavoritesViewModel()),
      ],
      child: child,
    );
  }
}
