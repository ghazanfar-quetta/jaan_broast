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
                  height: 120,
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? Theme.of(context).colorScheme.error
                          : Colors.white,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                ),
              ],
            ),

            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Food Name
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Price
                    Text(
                      portions.length <= 1
                          ? 'Rs${basePrice.toStringAsFixed(2)}'
                          : 'From Rs${basePrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Order Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleOrder(context),
                        style: ButtonStyles.primaryButton(context).copyWith(
                          padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                        child: const Text(
                          'Tap to Order',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
