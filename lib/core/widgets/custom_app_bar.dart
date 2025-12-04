// lib/core/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    Key? superkey,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.automaticallyImplyLeading = true,
  }) : super(key: superkey);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: AppConstants.headingSizeMedium,
          fontWeight: FontWeight.bold,
        ),
      ),
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      elevation: 0,
      centerTitle: true,
    );
  }
}
