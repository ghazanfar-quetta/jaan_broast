import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/screen_utils.dart';

class FoodCategoryCard extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const FoodCategoryCard({
    Key? key,
    required this.name,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ScreenUtils.responsiveValue(
            context,
            mobile: AppConstants.paddingMedium,
            tablet: AppConstants.paddingLarge,
            desktop: AppConstants.paddingLarge,
          ),
          vertical: ScreenUtils.responsiveValue(
            context,
            mobile: AppConstants.paddingSmall,
            tablet: AppConstants.paddingMedium,
            desktop: AppConstants.paddingMedium,
          ),
        ),
        margin: EdgeInsets.only(
          right: ScreenUtils.responsiveValue(
            context,
            mobile: AppConstants.paddingSmall,
            tablet: AppConstants.paddingMedium,
            desktop: AppConstants.paddingMedium,
          ),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.captionTextSize,
              tablet: AppConstants.bodyTextSize,
              desktop: AppConstants.bodyTextSize,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
