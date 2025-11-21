// lib/features/splash/presentation/views/splash_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    final initialRoute = await AppRouter.getInitialRoute();
    if (mounted) {
      AppRoutes.pushReplacement(context, initialRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash/splash_image.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
