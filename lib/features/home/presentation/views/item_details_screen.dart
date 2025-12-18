import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/screen_utils.dart';
import '../view_models/item_details_view_model.dart';
import '../../../cart/presentation/view_models/cart_view_model.dart';
import '../../domain/models/food_item_details.dart';
import '../../domain/models/food_item.dart';

class ItemDetailsScreen extends StatefulWidget {
  final String itemId;
  final BuildContext parentContext;

  const ItemDetailsScreen({
    Key? key,
    required this.itemId,
    required this.parentContext,
  }) : super(key: key);

  // Static method to show as modal
  static Future<void> show({
    required BuildContext context,
    required String itemId,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ItemDetailsScreen(itemId: itemId, parentContext: context),
    );
  }

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  late ItemDetailsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ItemDetailsViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadFoodItemDetails(widget.itemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = ScreenUtils.getScreenHeight(context);
    final modalHeight = screenHeight * 0.8; // Changed from 0.6 to 0.8 (80%)

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Container(
        height: modalHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppConstants.borderRadius),
            topRight: Radius.circular(AppConstants.borderRadius),
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Consumer<ItemDetailsViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return _buildLoadingState();
              }

              if (viewModel.error != null) {
                return _buildErrorState(viewModel.error!);
              }

              if (viewModel.selectedItem == null) {
                return _buildEmptyState();
              }

              return _buildMainContent(viewModel, modalHeight, context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Theme.of(context).primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading item details...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _viewModel.loadFoodItemDetails(widget.itemId);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Item not found', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    ItemDetailsViewModel viewModel,
    double modalHeight,
    BuildContext context,
  ) {
    final item = viewModel.selectedItem!;

    return Stack(
      children: [
        // Main content
        Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    iconSize: 24,
                  ),
                  Expanded(
                    child: Text(
                      item.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // For balance with close button
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Image
                    if (item.imageUrl.isNotEmpty)
                      Container(
                        height: 180, // Slightly increased for 80% modal
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(item.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Description
                    if (item.description.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                    // Ingredients
                    if (item.ingredients.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ingredients',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: item.ingredients
                                .map(
                                  (ingredient) => Chip(
                                    label: Text(ingredient),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                    // Portions Selection - CHANGED TO CHECKBOXES
                    _buildPortionsSection(viewModel, context),

                    // Add-ons (if available)
                    if (item.availableAddOns.isNotEmpty)
                      _buildAddOnsSection(viewModel, context),

                    // Dietary Info
                    if (item.hasDietaryInfo)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dietary Information',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.dietaryInfo,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                    // REMOVED: Preparation Time & Rating section
                    const SizedBox(
                      height: 120,
                    ), // Extra space for bottom action bar
                  ],
                ),
              ),
            ),
          ],
        ),

        // Bottom Action Bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomActionBar(viewModel, context),
        ),
      ],
    );
  }

  Widget _buildPortionsSection(
    ItemDetailsViewModel viewModel,
    BuildContext context,
  ) {
    final item = viewModel.selectedItem!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Portion',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Column(
          children: item.portions.map((portion) {
            final isSelected = viewModel.selectedPortion == portion.size;
            return CheckboxListTile(
              title: Text(
                portion.size,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Text(
                portion.formattedPrice,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              value: isSelected,
              onChanged: (_) => viewModel.selectPortion(portion.size),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              activeColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAddOnsSection(
    ItemDetailsViewModel viewModel,
    BuildContext context,
  ) {
    final item = viewModel.selectedItem!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add-ons',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Column(
          children: item.availableAddOns.map((addOn) {
            final isSelected = viewModel.selectedAddOns[addOn] ?? false;
            return CheckboxListTile(
              title: Text(addOn),
              subtitle: Text(
                'Rs${item.getAddOnPrice(addOn).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: isSelected,
              onChanged: (_) => viewModel.toggleAddOn(addOn),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              activeColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBottomActionBar(
    ItemDetailsViewModel viewModel,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
        vertical: AppConstants.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quantity Selector
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: viewModel.decreaseQuantity,
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    viewModel.quantity.toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: viewModel.increaseQuantity,
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Total Price and Add to Cart Button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
                Text(
                  'Rs${viewModel.calculateTotalPrice().toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Add to Cart Button
          ElevatedButton(
            onPressed: () {
              _addToCart(viewModel, context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge,
                vertical: AppConstants.paddingMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              elevation: 2,
            ),
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(
    ItemDetailsViewModel viewModel,
    BuildContext context,
  ) async {
    if (viewModel.selectedItem == null || viewModel.selectedPortion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a portion'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get the cart view model from the parent context
      final cartViewModel = Provider.of<CartViewModel>(
        widget.parentContext,
        listen: false,
      );
      final item = viewModel.selectedItem!;
      final selectedPortion = viewModel.selectedPortion!;

      // Find the selected portion object
      final selectedPortionObj = item.portions.firstWhere(
        (p) => p.size == selectedPortion,
        orElse: () => item.portions.first,
      );

      // Get selected add-ons
      final List<String> selectedAddOns = viewModel.selectedAddOns.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      // Calculate total price with add-ons
      double totalPrice = selectedPortionObj.price;
      for (var addOn in selectedAddOns) {
        totalPrice += item.getAddOnPrice(addOn);
      }

      // Create a description that includes add-ons
      String description = item.description;
      if (selectedAddOns.isNotEmpty) {
        description += '\n\nAdd-ons: ${selectedAddOns.join(', ')}';
      }

      // Create cart item using the CartViewModel helper method
      final cartItem = cartViewModel.createCartItemFromFoodItem(
        foodItemId: item.id,
        name: item.name,
        description: description,
        imageUrl: item.imageUrl,
        selectedSize: selectedPortion,
        price: totalPrice,
        quantity: viewModel.quantity,
        specialInstructions: null,
      );

      // Add to cart
      cartViewModel.addToCart(cartItem);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${viewModel.quantity}x ${item.name} (${selectedPortion}) added to cart',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to cart screen
      Navigator.of(context).pop(); // Close the modal

      // Use a small delay to ensure modal is closed before navigation
      await Future.delayed(const Duration(milliseconds: 300));

      // Navigate to cart screen using parent context
      Navigator.of(widget.parentContext).pushNamed('/cart');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
