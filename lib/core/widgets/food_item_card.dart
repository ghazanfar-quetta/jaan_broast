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
  final VoidCallback? onToggleFavorite;
  final bool isFavorite;
  final bool isCompact;

  const FoodItemCard({
    Key? key,
    required this.name,
    required this.portions,
    required this.imageUrl,
    required this.onTap,
    this.onToggleFavorite,
    this.isFavorite = false,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FoodPortion firstPortion = portions.first;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Container(
          padding: EdgeInsets.all(
            ScreenUtils.responsiveValue(
              context,
              mobile: 12,
              tablet: 14,
              desktop: 16,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Food Image - Large size
              Stack(
                children: [
                  Container(
                    height: ScreenUtils.responsiveValue(
                      context,
                      mobile: 140,
                      tablet: 150,
                      desktop: 160,
                    ),
                    width: double.infinity,
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
                        ? Center(
                            child: Icon(
                              Icons.fastfood,
                              size: 50,
                              color: Theme.of(context).primaryColor,
                            ),
                          )
                        : null,
                  ),

                  // Price Tag
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        firstPortion.formattedPrice,
                        style: TextStyle(
                          fontSize: ScreenUtils.responsiveFontSize(
                            context,
                            mobile: 10,
                            tablet: 11,
                            desktop: 12,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(
                height: ScreenUtils.responsiveValue(
                  context,
                  mobile: 5,
                  tablet: 7,
                  desktop: 9,
                ),
              ),

              // Food Name and Favorite Button Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food Name - Flexible container that adjusts to content
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: ScreenUtils.responsiveValue(
                          context,
                          mobile: 100,
                          tablet: 108,
                          desktop: 116,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Food Name - Responsive font size with auto height
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: ScreenUtils.responsiveFontSize(
                                context,
                                mobile:
                                    12, // Smaller for mobile to fit more text
                                tablet: 13,
                                desktop: 14,
                              ),
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onBackground,
                              height: 1.2, // Better line spacing
                            ),
                            maxLines: 3, // Increased from 2 to 3 lines
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(
                            height: ScreenUtils.responsiveValue(
                              context,
                              mobile: 10,
                              tablet: 11,
                              desktop: 12,
                            ),
                          ),

                          // Tap to order hint
                          Text(
                            'Tap to order',
                            style: TextStyle(
                              fontSize: ScreenUtils.responsiveFontSize(
                                context,
                                mobile: 9,
                                tablet: 10,
                                desktop: 11,
                              ),
                              color: Theme.of(
                                context,
                              ).colorScheme.onBackground.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                    width: ScreenUtils.responsiveValue(
                      context,
                      mobile: 8,
                      tablet: 10,
                      desktop: 12,
                    ),
                  ),

                  // Favorite Button - Responsive size
                  if (onToggleFavorite != null)
                    Container(
                      width: ScreenUtils.responsiveValue(
                        context,
                        mobile: 40,
                        tablet: 44,
                        desktop: 48,
                      ),
                      height: ScreenUtils.responsiveValue(
                        context,
                        mobile: 40,
                        tablet: 44,
                        desktop: 48,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: onToggleFavorite,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: ScreenUtils.responsiveValue(
                            context,
                            mobile: 20,
                            tablet: 22,
                            desktop: 24,
                          ),
                          color: isFavorite
                              ? Colors.red
                              : Theme.of(context).primaryColor,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
