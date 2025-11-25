// lib/core/widgets/food_item_card.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/screen_utils.dart';
import '../../features/home/domain/models/food_item.dart';

class FoodItemCard extends StatelessWidget {
  final String name;
  final String description;
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
    required this.description,
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
    final bool isMobile = ScreenUtils.isMobile(context);
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
              ? const EdgeInsets.all(
                  12.0,
                ) // Increased padding for larger images
              : ScreenUtils.responsivePadding(
                  context,
                  mobile: 16,
                  tablet: 20,
                  desktop: 24,
                ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food Image - INCREASED SIZE
              Container(
                width: isCompact
                    ? 80 // Increased from 60
                    : ScreenUtils.responsiveValue(
                        context,
                        mobile: 100, // Increased from 70
                        tablet: 120, // Increased from 90
                        desktop: 140, // Increased from 100
                      ),
                height: isCompact
                    ? 80 // Increased from 60
                    : ScreenUtils.responsiveValue(
                        context,
                        mobile: 100, // Increased from 70
                        tablet: 120, // Increased from 90
                        desktop: 140, // Increased from 100
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
                ),
                child: imageUrl.isEmpty
                    ? Icon(
                        Icons.fastfood,
                        size: isCompact
                            ? 32 // Increased from 24
                            : ScreenUtils.responsiveValue(
                                context,
                                mobile: 40, // Increased from 30
                                tablet: 45, // Increased from 35
                                desktop: 50, // Increased from 40
                              ),
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
              ),

              SizedBox(
                width: isCompact
                    ? 12 // Increased from 8
                    : ScreenUtils.responsiveValue(
                        context,
                        mobile: 16, // Increased from 12
                        tablet: 20, // Increased from 16
                        desktop: 24, // Increased from 20
                      ),
              ),

              // Food Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name and description
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: isCompact
                                ? AppConstants
                                      .bodyTextSize // Increased from caption
                                : ScreenUtils.responsiveFontSize(
                                    context,
                                    mobile: AppConstants.headingSizeSmall,
                                    tablet: AppConstants.headingSizeSmall + 2,
                                    desktop: AppConstants.headingSizeSmall + 4,
                                  ),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(
                          height: isCompact
                              ? 4 // Increased from 2
                              : ScreenUtils.responsiveValue(
                                  context,
                                  mobile: 4,
                                  tablet: 6,
                                  desktop: 8,
                                ),
                        ),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: isCompact
                                ? AppConstants.captionTextSize
                                : ScreenUtils.responsiveFontSize(
                                    context,
                                    mobile: AppConstants.bodyTextSize - 2,
                                    tablet: AppConstants.bodyTextSize,
                                    desktop: AppConstants.bodyTextSize + 2,
                                  ),
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: isCompact
                              ? 2 // Increased from 1
                              : (isMobile ? 3 : 4), // Increased lines
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    if (!isCompact)
                      SizedBox(
                        height: ScreenUtils.responsiveValue(
                          context,
                          mobile: 8,
                          tablet: 12,
                          desktop: 16,
                        ),
                      ),

                    if (!isCompact)
                      _buildPortionSelection(context, selectedPortion),

                    if (!isCompact)
                      SizedBox(
                        height: ScreenUtils.responsiveValue(
                          context,
                          mobile: 8,
                          tablet: 12,
                          desktop: 16,
                        ),
                      ),

                    // Bottom row with price and action buttons
                    Container(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Price
                          Flexible(
                            child: Text(
                              selectedPortion.formattedPrice,
                              style: TextStyle(
                                fontSize: isCompact
                                    ? AppConstants
                                          .bodyTextSize // Increased from caption
                                    : ScreenUtils.responsiveFontSize(
                                        context,
                                        mobile: AppConstants.bodyTextSize,
                                        tablet: AppConstants.bodyTextSize + 2,
                                        desktop: AppConstants.bodyTextSize + 4,
                                      ),
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Action buttons
                          Container(
                            width: isCompact ? 60 : 80, // Increased width
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Favorite Icon Button
                                if (onToggleFavorite != null)
                                  Container(
                                    width: isCompact
                                        ? 24
                                        : 30, // Increased size
                                    height: isCompact ? 24 : 30,
                                    child: IconButton(
                                      onPressed: onToggleFavorite,
                                      icon: Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: isCompact
                                            ? 18
                                            : 24, // Increased size
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

                                SizedBox(
                                  width: isCompact ? 6 : 8,
                                ), // Increased spacing
                                // Add to Cart Icon Button
                                if (onAddToCart != null)
                                  Container(
                                    width: isCompact
                                        ? 24
                                        : 30, // Increased size
                                    height: isCompact ? 24 : 30,
                                    child: IconButton(
                                      onPressed: onAddToCart,
                                      icon: Icon(
                                        Icons.add_circle,
                                        size: isCompact
                                            ? 18
                                            : 24, // Increased size
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
    if (portions.length <= 1) {
      return Text(
        selectedPortion.size,
        style: TextStyle(
          fontSize: ScreenUtils.responsiveFontSize(
            context,
            mobile: AppConstants.captionTextSize - 2,
            tablet: AppConstants.captionTextSize,
            desktop: AppConstants.captionTextSize,
          ),
          fontWeight: FontWeight.w500,
          color: Theme.of(context).primaryColor,
        ),
      );
    }

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
                  mobile: AppConstants.captionTextSize - 3,
                  tablet: AppConstants.captionTextSize - 2,
                  desktop: AppConstants.captionTextSize - 2,
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
