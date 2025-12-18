// lib/core/widgets/food_item_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../utils/screen_utils.dart';
import '../../features/home/domain/models/food_item.dart';
import 'package:jaan_broast/features/cart/presentation/views/cart_screen.dart';
import 'package:jaan_broast/features/cart/presentation/view_models/cart_view_model.dart';
import '../constants/button_styles.dart';
import 'package:jaan_broast/features/home/domain/models/food_item.dart';
import 'package:jaan_broast/features/cart/presentation/view_models/cart_view_model.dart';

class FoodItemCard extends StatelessWidget {
  final String name;
  final List<FoodPortion> portions;
  final String imageUrl;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final FoodItem? foodItem; // Add this optional parameter

  const FoodItemCard({
    super.key,
    required this.name,
    required this.portions,
    required this.imageUrl,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.foodItem, // Add this
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
            // Image Section
            Stack(
              children: [
                Container(
                  height: 100,
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
                padding: const EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Food Name
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Price
                    Text(
                      portions.length <= 1
                          ? 'Rs. ${basePrice.toStringAsFixed(0)}'
                          : 'From Rs. ${basePrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),

                    // Order Button with Favorite Icon - Primary Color Scheme
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Order Button
                        SizedBox(
                          width: 80,
                          child: ElevatedButton(
                            onPressed: () => _handleOrder(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 4,
                              ),
                              minimumSize: const Size(0, 28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              'Order',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // Round Favorite Icon
                        GestureDetector(
                          onTap: onToggleFavorite,
                          child: Container(
                            width: 32, // Increased size
                            height: 32,
                            decoration: BoxDecoration(
                              color: isFavorite
                                  ? Theme.of(context)
                                        .primaryColor // Using primary color
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
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18, // Increased size
                                color: isFavorite
                                    ? Colors
                                          .white // White for filled
                                    : Theme.of(
                                        context,
                                      ).primaryColor, // Primary color for outline
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
          duration: Duration(seconds: 2),
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
        title: Text('Select Serving Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: foodItem.portions.map((portion) {
            return ListTile(
              leading: Icon(
                Icons.restaurant,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(
                portion.size,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: portion.serves != null
                  ? Text('Serves ${portion.serves} persons')
                  : Text(portion.description ?? ''),
              trailing: Text(
                'Rs${portion.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
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
                    duration: Duration(seconds: 2),
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
            child: Text('CANCEL'),
          ),
        ],
      ),
    );
  }
}
