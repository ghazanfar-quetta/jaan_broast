// lib/features/home/presentation/views/home_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/utils/screen_utils.dart';
import '../../../../core/services/local_storage_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jaan Broast',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: 20,
              tablet: 22,
              desktop: 24,
            ),
          ),
        ),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              size: ScreenUtils.responsiveValue(
                context,
                mobile: 20,
                tablet: 22,
                desktop: 24,
              ),
            ),
            onPressed: () async {
              await LocalStorageService.setIsLoggedIn(false);
              Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome to Jaan Broast!',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: 24,
              tablet: 28,
              desktop: 32,
            ),
          ),
        ),
      ),
    );
  }
}
