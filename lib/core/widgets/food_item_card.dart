// lib/core/widgets/food_item_card.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/screen_utils.dart';
import '../../features/home/domain/models/food_item.dart';

class FoodItemCard extends StatelessWidget {
  final String name;
  final List<FoodPortion> portions;
  final String imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onToggleFavorite;
  final bool isFavorite;
  final int selectedPortionIndex;
  final bool isCompact;

  const FoodItemCard({
    Key? key,
    required this.name,
    required this.portions,
    required this.imageUrl,
    required this.onTap,
    this.onAddToCart,
    this.onToggleFavorite,
    this.isFavorite = false,
    this.selectedPortionIndex = 0,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FoodPortion selectedPortion = portions[selectedPortionIndex];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: isCompact
              ? const EdgeInsets.all(12.0)
              : ScreenUtils.responsivePadding(
                  context,
                  mobile: 16,
                  tablet: 20,
                  desktop: 24,
                ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Food Image - MAXIMUM SIZE
              Container(
                width: isCompact
                    ? 140 // Much larger - was 100
                    : ScreenUtils.responsiveValue(
                        context,
                        mobile: 160, // Much larger - was 120
                        tablet: 180, // Much larger - was 140
                        desktop: 200, // Much larger - was 160
                      ),
                height: isCompact
                    ? 140 // Much larger - was 100
                    : ScreenUtils.responsiveValue(
                        context,
                        mobile: 160, // Much larger - was 120
                        tablet: 180, // Much larger - was 140
                        desktop: 200, // Much larger - was 160
                      ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  image: imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: imageUrl.isEmpty
                    ? Icon(
                        Icons.fastfood,
                        size: isCompact
                            ? 50 // Larger icon for placeholder
                            : ScreenUtils.responsiveValue(
                                context,
                                mobile: 60,
                                tablet: 65,
                                desktop: 70,
                              ),
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
              ),

              SizedBox(
                width: isCompact
                    ? 12
                    : ScreenUtils.responsiveValue(
                        context,
                        mobile: 16,
                        tablet: 20,
                        desktop: 24,
                      ),
              ),

              // Food Details - Smaller content area
              Expanded(
                child: Container(
                  height: isCompact ? 120 : 140, // Fixed height to match image
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // Space out content
                    children: [
                      // Food Name - Smaller and compact
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: isCompact
                                  ? AppConstants.captionTextSize +
                                        2 // Smaller - was headingSizeSmall
                                  : ScreenUtils.responsiveFontSize(
                                      context,
                                      mobile:
                                          AppConstants.bodyTextSize, // Smaller
                                      tablet: AppConstants.bodyTextSize + 2,
                                      desktop: AppConstants.bodyTextSize + 4,
                                    ),
                              fontWeight: FontWeight.w600, // Slightly lighter
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: 4),

                          // Price below name - Smaller
                          Text(
                            selectedPortion.formattedPrice,
                            style: TextStyle(
                              fontSize: isCompact
                                  ? AppConstants
                                        .captionTextSize // Smaller
                                  : ScreenUtils.responsiveFontSize(
                                      context,
                                      mobile: AppConstants.bodyTextSize - 2,
                                      tablet: AppConstants.bodyTextSize,
                                      desktop: AppConstants.bodyTextSize + 2,
                                    ),
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),

                      // Portion selection - only show in regular mode (smaller)
                      if (!isCompact && portions.length > 1)
                        _buildPortionSelection(context, selectedPortion),

                      // Action buttons - Smaller and compact
                      Container(
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Spacer to push buttons to right
                            Spacer(),

                            // Action buttons - SMALLER
                            Container(
                              width: isCompact ? 60 : 80, // Smaller container
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Favorite Icon Button - SMALLER
                                  if (onToggleFavorite != null)
                                    Container(
                                      width: isCompact ? 24 : 28, // Smaller
                                      height: isCompact ? 24 : 28,
                                      child: IconButton(
                                        onPressed: onToggleFavorite,
                                        icon: Icon(
                                          isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: isCompact ? 18 : 22, // Smaller
                                        ),
                                        padding: EdgeInsets.zero,
                                        color: isFavorite
                                            ? Colors.red
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                      ),
                                    ),

                                  SizedBox(width: isCompact ? 6 : 8),

                                  // Add to Cart Icon Button - SMALLER
                                  if (onAddToCart != null)
                                    Container(
                                      width: isCompact ? 24 : 28, // Smaller
                                      height: isCompact ? 24 : 28,
                                      child: IconButton(
                                        onPressed: onAddToCart,
                                        icon: Icon(
                                          Icons.add_circle,
                                          size: isCompact ? 18 : 22, // Smaller
                                        ),
                                        padding: EdgeInsets.zero,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortionSelection(
    BuildContext context,
    FoodPortion selectedPortion,
  ) {
    return Wrap(
      spacing: ScreenUtils.responsiveValue(
        context,
        mobile: 6,
        tablet: 8,
        desktop: 10,
      ),
      runSpacing: ScreenUtils.responsiveValue(
        context,
        mobile: 4,
        tablet: 6,
        desktop: 6,
      ),
      children: portions.asMap().entries.map((entry) {
        final index = entry.key;
        final portion = entry.value;
        final isSelected = index == selectedPortionIndex;

        return GestureDetector(
          onTap: () {
            // This would be handled by the parent widget
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ScreenUtils.responsiveValue(
                context,
                mobile: 8,
                tablet: 10,
                desktop: 12,
              ),
              vertical: ScreenUtils.responsiveValue(
                context,
                mobile: 4,
                tablet: 6,
                desktop: 6,
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
              portion.size,
              style: TextStyle(
                fontSize: ScreenUtils.responsiveFontSize(
                  context,
                  mobile: AppConstants.captionTextSize - 2, // Smaller
                  tablet: AppConstants.captionTextSize - 1,
                  desktop: AppConstants.captionTextSize,
                ),
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
