import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/screen_utils.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;
  final String hintText;

  const SearchField({
    Key? key,
    required this.controller,
    required this.onChanged,
    required this.onTap,
    this.hintText = 'Search for your favourite food',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          Icons.search,
          size: ScreenUtils.responsiveValue(
            context,
            mobile: 20,
            tablet: 22,
            desktop: 24,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: ScreenUtils.responsiveValue(
            context,
            mobile: AppConstants.paddingMedium,
            tablet: AppConstants.paddingMedium,
            desktop: AppConstants.paddingLarge,
          ),
          horizontal: ScreenUtils.responsiveValue(
            context,
            mobile: AppConstants.paddingMedium,
            tablet: AppConstants.paddingLarge,
            desktop: AppConstants.paddingLarge,
          ),
        ),
        hintStyle: TextStyle(
          fontSize: ScreenUtils.responsiveFontSize(
            context,
            mobile: AppConstants.bodyTextSize,
            tablet: AppConstants.bodyTextSize,
            desktop: AppConstants.bodyTextSize,
          ),
        ),
      ),
      style: TextStyle(
        fontSize: ScreenUtils.responsiveFontSize(
          context,
          mobile: AppConstants.bodyTextSize,
          tablet: AppConstants.bodyTextSize,
          desktop: AppConstants.bodyTextSize,
        ),
      ),
    );
  }
}
