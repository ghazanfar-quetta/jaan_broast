// lib/features/home/presentation/views/item_details_screen.dart
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
    final modalHeight =
        screenHeight *
        ScreenUtils.responsiveValue(
          context,
          mobile: 0.8, // 80% for mobile
          tablet: 0.75, // 75% for tablet
          desktop: 0.7, // 70% for desktop
        );

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Container(
        height: modalHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(
              ScreenUtils.responsiveValue(
                context,
                mobile: AppConstants.borderRadius,
                tablet: AppConstants.borderRadius * 1.5,
                desktop: AppConstants.borderRadius * 2,
              ),
            ),
            topRight: Radius.circular(
              ScreenUtils.responsiveValue(
                context,
                mobile: AppConstants.borderRadius,
                tablet: AppConstants.borderRadius * 1.5,
                desktop: AppConstants.borderRadius * 2,
              ),
            ),
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
          CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
            strokeWidth: ScreenUtils.responsiveValue(
              context,
              mobile: 3.0,
              tablet: 3.5,
              desktop: 4.0,
            ),
          ),
          SizedBox(
            height: ScreenUtils.responsiveValue(
              context,
              mobile: 16.0,
              tablet: 20.0,
              desktop: 24.0,
            ),
          ),
          Text(
            'Loading item details...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: ScreenUtils.responsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          ScreenUtils.responsiveValue(
            context,
            mobile: 24.0,
            tablet: 32.0,
            desktop: 40.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ScreenUtils.responsiveValue(
                context,
                mobile: 48.0,
                tablet: 56.0,
                desktop: 64.0,
              ),
              color: Colors.red,
            ),
            SizedBox(
              height: ScreenUtils.responsiveValue(
                context,
                mobile: 16.0,
                tablet: 20.0,
                desktop: 24.0,
              ),
            ),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red,
                fontSize: ScreenUtils.responsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: ScreenUtils.responsiveValue(
                context,
                mobile: 24.0,
                tablet: 28.0,
                desktop: 32.0,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _viewModel.loadFoodItemDetails(widget.itemId);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenUtils.responsiveValue(
                    context,
                    mobile: 24.0,
                    tablet: 32.0,
                    desktop: 40.0,
                  ),
                  vertical: ScreenUtils.responsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 14.0,
                    desktop: 16.0,
                  ),
                ),
              ),
              child: Text(
                'Retry',
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fastfood_outlined,
            size: ScreenUtils.responsiveValue(
              context,
              mobile: 64.0,
              tablet: 72.0,
              desktop: 80.0,
            ),
            color: Colors.grey,
          ),
          SizedBox(
            height: ScreenUtils.responsiveValue(
              context,
              mobile: 16.0,
              tablet: 20.0,
              desktop: 24.0,
            ),
          ),
          Text(
            'Item not found',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: ScreenUtils.responsiveValue(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              ),
            ),
          ),
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
              width: ScreenUtils.responsiveValue(
                context,
                mobile: 40.0,
                tablet: 50.0,
                desktop: 60.0,
              ),
              height: ScreenUtils.responsiveValue(
                context,
                mobile: 4.0,
                tablet: 5.0,
                desktop: 6.0,
              ),
              margin: EdgeInsets.symmetric(
                vertical: ScreenUtils.responsiveValue(
                  context,
                  mobile: 6.0,
                  tablet: 14.0,
                  desktop: 16.0,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with close button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ScreenUtils.responsiveValue(
                  context,
                  mobile: 16.0,
                  tablet: 24.0,
                  desktop: 32.0,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    iconSize: ScreenUtils.responsiveValue(
                      context,
                      mobile: 24.0,
                      tablet: 28.0,
                      desktop: 32.0,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: ScreenUtils.responsiveValue(
                              context,
                              mobile: 18.0,
                              tablet: 22.0,
                              desktop: 26.0,
                            ),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: ScreenUtils.responsiveValue(
                      context,
                      mobile: 48.0,
                      tablet: 56.0,
                      desktop: 64.0,
                    ),
                  ), // For balance with close button
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenUtils.responsiveValue(
                    context,
                    mobile: 16.0,
                    tablet: 24.0,
                    desktop: 32.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: ScreenUtils.responsiveValue(
                        context,
                        mobile: 16.0,
                        tablet: 20.0,
                        desktop: 24.0,
                      ),
                    ),

                    // Image
                    if (item.imageUrl.isNotEmpty)
                      AspectRatio(
                        aspectRatio:
                            16 / 9, // Standard aspect ratio, adjust as needed
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit
                                .cover, // Cover but within aspect ratio constraints
                          ),
                        ),
                      ),

                    // Description
                    if (item.description.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: ScreenUtils.responsiveValue(
                                    context,
                                    mobile: 16.0,
                                    tablet: 18.0,
                                    desktop: 20.0,
                                  ),
                                ),
                          ),
                          SizedBox(
                            height: ScreenUtils.responsiveValue(
                              context,
                              mobile: 0.0,
                              tablet: 10.0,
                              desktop: 12.0,
                            ),
                          ),
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: ScreenUtils.responsiveValue(
                                    context,
                                    mobile: 14.0,
                                    tablet: 16.0,
                                    desktop: 18.0,
                                  ),
                                ),
                          ),
                          SizedBox(
                            height: ScreenUtils.responsiveValue(
                              context,
                              mobile: 20.0,
                              tablet: 24.0,
                              desktop: 28.0,
                            ),
                          ),
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
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: ScreenUtils.responsiveValue(
                                    context,
                                    mobile: 16.0,
                                    tablet: 18.0,
                                    desktop: 20.0,
                                  ),
                                ),
                          ),
                          SizedBox(
                            height: ScreenUtils.responsiveValue(
                              context,
                              mobile: 8.0,
                              tablet: 10.0,
                              desktop: 12.0,
                            ),
                          ),
                          Wrap(
                            spacing: ScreenUtils.responsiveValue(
                              context,
                              mobile: 8.0,
                              tablet: 12.0,
                              desktop: 16.0,
                            ),
                            runSpacing: ScreenUtils.responsiveValue(
                              context,
                              mobile: 4.0,
                              tablet: 6.0,
                              desktop: 8.0,
                            ),
                            children: item.ingredients
                                .map(
                                  (ingredient) => Chip(
                                    label: Text(
                                      ingredient,
                                      style: TextStyle(
                                        fontSize: ScreenUtils.responsiveValue(
                                          context,
                                          mobile: 12.0,
                                          tablet: 14.0,
                                          desktop: 16.0,
                                        ),
                                      ),
                                    ),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                                  ),
                                )
                                .toList(),
                          ),
                          SizedBox(
                            height: ScreenUtils.responsiveValue(
                              context,
                              mobile: 16.0,
                              tablet: 24.0,
                              desktop: 28.0,
                            ),
                          ),
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
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: ScreenUtils.responsiveValue(
                                    context,
                                    mobile: 16.0,
                                    tablet: 18.0,
                                    desktop: 20.0,
                                  ),
                                ),
                          ),
                          SizedBox(
                            height: ScreenUtils.responsiveValue(
                              context,
                              mobile: 8.0,
                              tablet: 10.0,
                              desktop: 12.0,
                            ),
                          ),
                          Text(
                            item.dietaryInfo,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: ScreenUtils.responsiveValue(
                                    context,
                                    mobile: 14.0,
                                    tablet: 16.0,
                                    desktop: 18.0,
                                  ),
                                ),
                          ),
                          SizedBox(
                            height: ScreenUtils.responsiveValue(
                              context,
                              mobile: 20.0,
                              tablet: 24.0,
                              desktop: 28.0,
                            ),
                          ),
                        ],
                      ),

                    // REMOVED: Preparation Time & Rating section
                    SizedBox(
                      height: ScreenUtils.responsiveValue(
                        context,
                        mobile: 120.0,
                        tablet: 140.0,
                        desktop: 160.0,
                      ),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: ScreenUtils.responsiveValue(
              context,
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
          ),
        ),
        SizedBox(
          height: ScreenUtils.responsiveValue(
            context,
            mobile: 0.0,
            tablet: 8.0,
            desktop: 16.0,
          ),
        ),
        Column(
          children: item.portions.map((portion) {
            final isSelected = viewModel.selectedPortion == portion.size;
            return CheckboxListTile(
              title: Text(
                portion.size,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: ScreenUtils.responsiveValue(
                    context,
                    mobile: 14.0,
                    tablet: 16.0,
                    desktop: 18.0,
                  ),
                ),
              ),
              subtitle: Text(
                portion.formattedPrice,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: ScreenUtils.responsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 14.0,
                    desktop: 16.0,
                  ),
                ),
              ),
              value: isSelected,
              onChanged: (_) => viewModel.selectPortion(portion.size),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.only(
                right: ScreenUtils.responsiveValue(
                  context,
                  mobile: 0.0,
                  tablet: 8.0,
                  desktop: 16.0,
                ),
              ),
              activeColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ScreenUtils.responsiveValue(
                    context,
                    mobile: 8.0,
                    tablet: 10.0,
                    desktop: 12.0,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(
          height: ScreenUtils.responsiveValue(
            context,
            mobile: 20.0,
            tablet: 24.0,
            desktop: 28.0,
          ),
        ),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: ScreenUtils.responsiveValue(
              context,
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
          ),
        ),
        SizedBox(
          height: ScreenUtils.responsiveValue(
            context,
            mobile: 12.0,
            tablet: 14.0,
            desktop: 16.0,
          ),
        ),
        Column(
          children: item.availableAddOns.map((addOn) {
            final isSelected = viewModel.selectedAddOns[addOn] ?? false;
            return CheckboxListTile(
              title: Text(
                addOn,
                style: TextStyle(
                  fontSize: ScreenUtils.responsiveValue(
                    context,
                    mobile: 14.0,
                    tablet: 16.0,
                    desktop: 18.0,
                  ),
                ),
              ),
              subtitle: Text(
                'Rs${item.getAddOnPrice(addOn).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: ScreenUtils.responsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 14.0,
                    desktop: 16.0,
                  ),
                ),
              ),
              value: isSelected,
              onChanged: (_) => viewModel.toggleAddOn(addOn),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.only(
                right: ScreenUtils.responsiveValue(
                  context,
                  mobile: 0.0,
                  tablet: 8.0,
                  desktop: 16.0,
                ),
              ),
              activeColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ScreenUtils.responsiveValue(
                    context,
                    mobile: 8.0,
                    tablet: 10.0,
                    desktop: 12.0,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(
          height: ScreenUtils.responsiveValue(
            context,
            mobile: 20.0,
            tablet: 24.0,
            desktop: 28.0,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(
    ItemDetailsViewModel viewModel,
    BuildContext context,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ScreenUtils.responsiveValue(
          context,
          mobile: AppConstants.paddingSmall,
          tablet: AppConstants.paddingLarge,
          desktop: AppConstants.paddingLarge * 2,
        ),
        vertical: ScreenUtils.responsiveValue(
          context,
          mobile: AppConstants.paddingSmall,
          tablet: AppConstants.paddingMedium,
          desktop: AppConstants.paddingLarge,
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: ScreenUtils.responsiveValue(
              context,
              mobile: 1.0,
              tablet: 1.2,
              desktop: 1.5,
            ),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: ScreenUtils.responsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 15.0,
            ),
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quantity Selector
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: ScreenUtils.responsiveValue(
                  context,
                  mobile: 1.0,
                  tablet: 1.2,
                  desktop: 1.5,
                ),
              ),
              borderRadius: BorderRadius.circular(
                ScreenUtils.responsiveValue(
                  context,
                  mobile: AppConstants.borderRadius,
                  tablet: AppConstants.borderRadius * 1.2,
                  desktop: AppConstants.borderRadius * 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: viewModel.decreaseQuantity,
                  iconSize: ScreenUtils.responsiveValue(
                    context,
                    mobile: 20.0,
                    tablet: 22.0,
                    desktop: 24.0,
                  ),
                  padding: EdgeInsets.all(
                    ScreenUtils.responsiveValue(
                      context,
                      mobile: 4.0,
                      tablet: 10.0,
                      desktop: 12.0,
                    ),
                  ),
                  constraints: const BoxConstraints(),
                ),
                Container(
                  width: ScreenUtils.responsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 30.0,
                    desktop: 50.0,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    viewModel.quantity.toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: ScreenUtils.responsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 18.0,
                        desktop: 20.0,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: viewModel.increaseQuantity,
                  iconSize: ScreenUtils.responsiveValue(
                    context,
                    mobile: 20.0,
                    tablet: 22.0,
                    desktop: 24.0,
                  ),
                  padding: EdgeInsets.all(
                    ScreenUtils.responsiveValue(
                      context,
                      mobile: 4.0,
                      tablet: 10.0,
                      desktop: 12.0,
                    ),
                  ),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          SizedBox(
            width: ScreenUtils.responsiveValue(
              context,
              mobile: 12.0,
              tablet: 16.0,
              desktop: 20.0,
            ),
          ),

          // Total Price and Add to Cart Button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.7),
                    fontSize: ScreenUtils.responsiveValue(
                      context,
                      mobile: 14.0,
                      tablet: 18.0,
                      desktop: 20.0,
                    ),
                  ),
                ),
                Text(
                  'Rs${viewModel.calculateTotalPrice().toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ScreenUtils.responsiveValue(
                      context,
                      mobile: 16.0,
                      tablet: 20.0,
                      desktop: 24.0,
                    ),
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: ScreenUtils.responsiveValue(
              context,
              mobile: 12.0,
              tablet: 16.0,
              desktop: 20.0,
            ),
          ),

          // Add to Cart Button
          ElevatedButton(
            onPressed: () {
              _addToCart(viewModel, context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: ScreenUtils.responsiveValue(
                  context,
                  mobile: AppConstants.paddingSmall,
                  tablet: AppConstants.paddingLarge,
                  desktop: AppConstants.paddingLarge * 2,
                ),
                vertical: ScreenUtils.responsiveValue(
                  context,
                  mobile: AppConstants.paddingSmall,
                  tablet: AppConstants.paddingMedium,
                  desktop: AppConstants.paddingLarge,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ScreenUtils.responsiveValue(
                    context,
                    mobile: AppConstants.borderRadius,
                    tablet: AppConstants.borderRadius * 1.2,
                    desktop: AppConstants.borderRadius * 1.5,
                  ),
                ),
              ),
              elevation: 2,
            ),
            child: Text(
              'Add to Cart',
              style: TextStyle(
                fontSize: ScreenUtils.responsiveValue(
                  context,
                  mobile: 12.0,
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
            style: TextStyle(
              fontSize: ScreenUtils.responsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              ),
            ),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          padding: EdgeInsets.all(
            ScreenUtils.responsiveValue(
              context,
              mobile: 16.0,
              tablet: 20.0,
              desktop: 24.0,
            ),
          ),
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
          content: Text(
            'Failed to add to cart: $e',
            style: TextStyle(
              fontSize: ScreenUtils.responsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              ),
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          padding: EdgeInsets.all(
            ScreenUtils.responsiveValue(
              context,
              mobile: 16.0,
              tablet: 20.0,
              desktop: 24.0,
            ),
          ),
        ),
      );
    }
  }
}
