// lib/core/widgets/food_category_card.dart (create this file if it doesn't exist)
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/screen_utils.dart';

class FoodCategoryCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const FoodCategoryCard({
    Key? key,
    required this.name,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          right: ScreenUtils.responsiveValue(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
        ),
        child: Column(
          children: [
            // Circular category image/icon
            Container(
              width: ScreenUtils.responsiveValue(
                context,
                mobile: 60,
                tablet: 70,
                desktop: 80,
              ),
              height: ScreenUtils.responsiveValue(
                context,
                mobile: 60,
                tablet: 70,
                desktop: 80,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  width: 2,
                ),
                image: imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl.isEmpty
                  ? Icon(
                      _getCategoryIcon(name),
                      size: ScreenUtils.responsiveValue(
                        context,
                        mobile: 24,
                        tablet: 28,
                        desktop: 32,
                      ),
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                    )
                  : null,
            ),
            SizedBox(height: 8),
            // Category name
            Text(
              name,
              style: TextStyle(
                fontSize: ScreenUtils.responsiveFontSize(
                  context,
                  mobile: AppConstants.captionTextSize,
                  tablet: AppConstants.bodyTextSize,
                  desktop: AppConstants.bodyTextSize,
                ),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get icons for categories
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'birvani':
      case 'biryani':
        return Icons.rice_bowl;
      case 'burgers':
        return Icons.fastfood;
      case 'broast':
        return Icons.kebab_dining;
      case 'bar b.q':
      case 'barbecue':
        return Icons.outdoor_grill;
      case 'chinese':
        return Icons.ramen_dining;
      default:
        return Icons.restaurant;
    }
  }
}
