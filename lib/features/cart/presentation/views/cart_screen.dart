import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jaan_broast/core/constants/app_constants.dart';
import 'package:jaan_broast/core/constants/button_styles.dart';
import 'package:jaan_broast/core/utils/screen_utils.dart';
import 'package:jaan_broast/features/cart/presentation/view_models/cart_view_model.dart';
import 'package:jaan_broast/features/cart/domain/models/cart_item.dart';

class CartScreen extends StatefulWidget {
  final bool isOpen;

  const CartScreen({super.key, required this.isOpen});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    if (widget.isOpen) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant CartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _animationController.forward();
    } else if (!widget.isOpen && oldWidget.isOpen) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: () => context.read<CartViewModel>().closeCart(),
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Container(
                color: Colors.black.withOpacity(_fadeAnimation.value * 0.5),
              );
            },
          ),
        ),

        // Cart Content
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                0,
                _slideAnimation.value * ScreenUtils.getScreenHeight(context),
              ),
              child: child,
            );
          },
          child: Container(
            height: ScreenUtils.getScreenHeight(context) * 0.8,
            margin: EdgeInsets.only(
              top: ScreenUtils.getScreenHeight(context) * 0.2,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                _buildHeader(context),

                // Cart Items
                Expanded(child: _buildCartItems(context)),

                // Checkout Section
                _buildCheckoutSection(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Your Order',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => context.read<CartViewModel>().closeCart(),
            icon: const Icon(Icons.close, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(BuildContext context) {
    final cartViewModel = context.watch<CartViewModel>();

    if (cartViewModel.cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some delicious items to get started!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cartViewModel.cartItems.length,
      itemBuilder: (context, index) {
        final item = cartViewModel.cartItems[index];
        return _buildCartItem(context, item);
      },
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(item.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Portion Size
                  Text(
                    'Size: ${item.selectedSize}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs${item.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity Controls
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.remove,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      context.read<CartViewModel>().updateQuantity(
                        item.id,
                        item.quantity - 1,
                      );
                    },
                  ),
                  Text(
                    item.quantity.toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      context.read<CartViewModel>().updateQuantity(
                        item.id,
                        item.quantity + 1,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context) {
    final cartViewModel = context.watch<CartViewModel>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Rs${cartViewModel.totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Checkout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cartViewModel.cartItems.isEmpty
                  ? null
                  : () {
                      _showCheckoutDialog(context);
                    },
              style: ButtonStyles.primaryButton(context),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'PROCEED TO CHECKOUT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context) {
    final cartViewModel = context.read<CartViewModel>();
    final TextEditingController instructionsController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Order',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total: Rs${cartViewModel.totalAmount.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Special Instructions (Optional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: instructionsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any special requests or dietary requirements...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final userId = 'current_user_id';
                await cartViewModel.checkout(
                  userId: userId,
                  specialInstructions: instructionsController.text.isEmpty
                      ? null
                      : instructionsController.text,
                );
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order placed successfully!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to place order: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ButtonStyles.primaryButton(context),
            child: const Text('CONFIRM ORDER'),
          ),
        ],
      ),
    );
  }
}
