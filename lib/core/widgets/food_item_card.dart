// lib/core/widgets/food_item_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../utils/screen_utils.dart';
import '../../features/home/domain/models/food_item.dart';
import 'package:jaan_broast/features/cart/presentation/views/cart_screen.dart';
import 'package:jaan_broast/features/cart/presentation/view_models/cart_view_model.dart';
import '../constants/button_styles.dart';

class FoodItemCard extends StatelessWidget {
  final String name;
  final List<FoodPortion> portions;
  final String imageUrl;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final FoodItem? foodItem;

  const FoodItemCard({
    super.key,
    required this.name,
    required this.portions,
    required this.imageUrl,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.foodItem,
  });

  @override
  Widget build(BuildContext context) {
    final basePrice = portions.isNotEmpty ? portions.first.price : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Image Section
            Stack(
              children: [
                Container(
                  height: ScreenUtils.responsiveValue(
                    context,
                    mobile: 140.0,
                    tablet: 200.0,
                    desktop: 300.0,
                  ),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.borderRadius),
                      topRight: Radius.circular(AppConstants.borderRadius),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),

            // Content Section
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(
                  ScreenUtils.responsiveValue(
                    context,
                    mobile: 4.0,
                    tablet: 8.0,
                    desktop: 12.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Responsive Food Name
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: ScreenUtils.responsiveValue(
                          context,
                          mobile: 11.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                      ),
                      maxLines: ScreenUtils.responsiveValue(
                        context,
                        mobile: 2,
                        tablet: 2,
                        desktop: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Responsive Price
                    Text(
                      portions.length <= 1
                          ? 'Rs. ${basePrice.toStringAsFixed(0)}'
                          : 'From Rs. ${basePrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: ScreenUtils.responsiveValue(
                          context,
                          mobile: 10.0,
                          tablet: 13.0,
                          desktop: 15.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 0),

                    // Order Button with Favorite Icon - Responsive
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Responsive Order Button
                        SizedBox(
                          width: ScreenUtils.responsiveValue(
                            context,
                            mobile: 80.0,
                            tablet: 100.0,
                            desktop: 120.0,
                          ),
                          child: OutlinedButton(
                            onPressed: () => _handleOrder(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 1.0,
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: ScreenUtils.responsiveValue(
                                  context,
                                  mobile: 0.0,
                                  tablet: 8.0,
                                  desktop: 12.0,
                                ),
                                horizontal: ScreenUtils.responsiveValue(
                                  context,
                                  mobile: 4.0,
                                  tablet: 8.0,
                                  desktop: 12.0,
                                ),
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  ScreenUtils.responsiveValue(
                                    context,
                                    mobile: 6.0,
                                    tablet: 8.0,
                                    desktop: 10.0,
                                  ),
                                ),
                              ),
                            ),
                            child: Text(
                              'Order Now',
                              style: TextStyle(
                                fontSize: ScreenUtils.responsiveValue(
                                  context,
                                  mobile: 10.0,
                                  tablet: 13.0,
                                  desktop: 15.0,
                                ),
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),

                        // Responsive Favorite Icon
                        GestureDetector(
                          onTap: onToggleFavorite,
                          child: Container(
                            width: ScreenUtils.responsiveValue(
                              context,
                              mobile: 26.0,
                              tablet: 36.0,
                              desktop: 40.0,
                            ),
                            height: ScreenUtils.responsiveValue(
                              context,
                              mobile: 26.0,
                              tablet: 36.0,
                              desktop: 40.0,
                            ),
                            decoration: BoxDecoration(
                              color: isFavorite
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isFavorite
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.3),
                                width: ScreenUtils.responsiveValue(
                                  context,
                                  mobile: 1.2,
                                  tablet: 1.8,
                                  desktop: 2.0,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: ScreenUtils.responsiveValue(
                                  context,
                                  mobile: 18.0,
                                  tablet: 20.0,
                                  desktop: 22.0,
                                ),
                                color: isFavorite
                                    ? Colors.white
                                    : Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleOrder(BuildContext context) {
    if (foodItem == null) return;

    final cartViewModel = context.read<CartViewModel>();

    // If only one portion available, add directly
    if (foodItem!.portions.length == 1) {
      final portion = foodItem!.portions.first;
      cartViewModel.addFoodItemToCart(foodItem!, portion);
      cartViewModel.openCart();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${foodItem!.name} added to cart!'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Show portion selection dialog for multiple portions
      _showPortionSelectionDialog(context, foodItem!);
    }
  }

  void _showPortionSelectionDialog(BuildContext context, FoodItem foodItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Serving Size',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveValue(
              context,
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: foodItem.portions.map((portion) {
            return ListTile(
              leading: Icon(
                Icons.restaurant,
                color: Theme.of(context).primaryColor,
                size: ScreenUtils.responsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 22.0,
                  desktop: 24.0,
                ),
              ),
              title: Text(
                portion.size,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ScreenUtils.responsiveValue(
                    context,
                    mobile: 14.0,
                    tablet: 16.0,
                    desktop: 18.0,
                  ),
                ),
              ),
              subtitle: portion.serves != null
                  ? Text(
                      'Serves ${portion.serves} persons',
                      style: TextStyle(
                        fontSize: ScreenUtils.responsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                      ),
                    )
                  : Text(
                      portion.description ?? '',
                      style: TextStyle(
                        fontSize: ScreenUtils.responsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                      ),
                    ),
              trailing: Text(
                'Rs${portion.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: ScreenUtils.responsiveValue(
                    context,
                    mobile: 14.0,
                    tablet: 16.0,
                    desktop: 18.0,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                final cartViewModel = context.read<CartViewModel>();
                cartViewModel.addFoodItemToCart(foodItem, portion);
                cartViewModel.openCart();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${foodItem.name} (${portion.size}) added to cart!',
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(
                fontSize: ScreenUtils.responsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
