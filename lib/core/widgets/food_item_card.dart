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
  final int selectedPortionIndex;
  final bool isCompact; // Add this for horizontal list

  const FoodItemCard({
    Key? key,
    required this.name,
    required this.description,
    required this.portions,
    required this.imageUrl,
    required this.onTap,
    this.onAddToCart,
    this.selectedPortionIndex = 0,
    this.isCompact = false, // Default to regular size
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
              ? const EdgeInsets.all(8.0) // Compact padding
              : ScreenUtils.responsivePadding(
                  context,
                  mobile: 12,
                  tablet: 16,
                  desktop: 20,
                ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food Image - Responsive size
              Container(
                width: isCompact
                    ? 60 // Compact image size
                    : ScreenUtils.responsiveValue(
                        context,
                        mobile: 70,
                        tablet: 90,
                        desktop: 100,
                      ),
                height: isCompact
                    ? 60 // Compact image size
                    : ScreenUtils.responsiveValue(
                        context,
                        mobile: 70,
                        tablet: 90,
                        desktop: 100,
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
                            ? 24 // Compact icon size
                            : ScreenUtils.responsiveValue(
                                context,
                                mobile: 30,
                                tablet: 35,
                                desktop: 40,
                              ),
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
              ),

              SizedBox(
                width: isCompact
                    ? 8 // Compact spacing
                    : ScreenUtils.responsiveValue(
                        context,
                        mobile: 12,
                        tablet: 16,
                        desktop: 20,
                      ),
              ),

              // Food Details - Compact layout
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Important: don't expand
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: isCompact
                            ? AppConstants
                                  .captionTextSize // Compact font
                            : ScreenUtils.responsiveFontSize(
                                context,
                                mobile: AppConstants.headingSizeSmall - 2,
                                tablet: AppConstants.headingSizeSmall,
                                desktop: AppConstants.headingSizeSmall,
                              ),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: isCompact
                          ? 2
                          : ScreenUtils.responsiveValue(
                              context,
                              mobile: 2,
                              tablet: 4,
                              desktop: 4,
                            ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: isCompact
                            ? AppConstants.captionTextSize -
                                  2 // Very compact
                            : ScreenUtils.responsiveFontSize(
                                context,
                                mobile: AppConstants.captionTextSize - 2,
                                tablet: AppConstants.captionTextSize,
                                desktop: AppConstants.captionTextSize,
                              ),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: isCompact
                          ? 1
                          : (isMobile ? 2 : 3), // Fewer lines in compact
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (!isCompact)
                      SizedBox(
                        height: ScreenUtils.responsiveValue(
                          context,
                          mobile: 6,
                          tablet: 8,
                          desktop: 8,
                        ),
                      ),

                    // Portion Selection - Only show in regular mode or simplified
                    if (!isCompact)
                      _buildPortionSelection(context, selectedPortion),

                    if (!isCompact)
                      SizedBox(
                        height: ScreenUtils.responsiveValue(
                          context,
                          mobile: 6,
                          tablet: 8,
                          desktop: 8,
                        ),
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedPortion.formattedPrice,
                          style: TextStyle(
                            fontSize: isCompact
                                ? AppConstants
                                      .captionTextSize // Compact price
                                : ScreenUtils.responsiveFontSize(
                                    context,
                                    mobile: AppConstants.bodyTextSize - 1,
                                    tablet: AppConstants.bodyTextSize,
                                    desktop: AppConstants.bodyTextSize,
                                  ),
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        if (onAddToCart != null)
                          IconButton(
                            onPressed: onAddToCart,
                            icon: Icon(
                              Icons.add_circle,
                              color: Theme.of(context).primaryColor,
                              size: isCompact
                                  ? 20 // Compact icon
                                  : ScreenUtils.responsiveValue(
                                      context,
                                      mobile: 26,
                                      tablet: 28,
                                      desktop: 30,
                                    ),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
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
