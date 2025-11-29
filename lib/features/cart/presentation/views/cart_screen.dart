// lib/features/cart/presentation/views/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jaan_broast/core/constants/app_constants.dart';
import 'package:jaan_broast/core/constants/button_styles.dart';
import 'package:jaan_broast/core/utils/screen_utils.dart';
import 'package:jaan_broast/features/cart/presentation/view_models/cart_view_model.dart';
import 'package:jaan_broast/features/cart/domain/models/cart_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jaan_broast/core/constants/app_themes.dart';

class CartScreen extends StatefulWidget {
  final bool isOpen;
  final VoidCallback? onOrderMore;

  const CartScreen({super.key, required this.isOpen, this.onOrderMore});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final TextEditingController _specialInstructionsController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _instructionsFocusNode = FocusNode();
  final GlobalKey _instructionsKey = GlobalKey();

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

    // Listen to focus changes to scroll to text field when keyboard appears
    _instructionsFocusNode.addListener(_onInstructionsFocusChanged);

    if (widget.isOpen) {
      _animationController.forward();
    }
  }

  void _onInstructionsFocusChanged() {
    if (_instructionsFocusNode.hasFocus) {
      // Wait for the next frame to ensure the widget is built, then scroll
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Delay to allow keyboard to appear
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            // Get the position of the special instructions section
            final context = _instructionsKey.currentContext;
            if (context != null) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final position = box.localToGlobal(Offset.zero);
                final scrollPosition = _scrollController.position;

                // Calculate how much we need to scroll to make the text field visible
                final viewportHeight = scrollPosition.viewportDimension;
                final textFieldBottom = position.dy + box.size.height;
                final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

                // If text field is hidden by keyboard, scroll to make it visible
                if (textFieldBottom > viewportHeight - keyboardHeight) {
                  final scrollOffset =
                      textFieldBottom - (viewportHeight - keyboardHeight) + 20;
                  _scrollController.animateTo(
                    scrollPosition.pixels + scrollOffset,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              }
            } else {
              // Fallback: scroll to bottom if we can't calculate position
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          }
        });
      });
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
    _specialInstructionsController.dispose();
    _scrollController.dispose();
    _instructionsFocusNode.removeListener(_onInstructionsFocusChanged);
    _instructionsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
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

                  // Scrollable Cart Content
                  Expanded(child: _buildCartContent(context)),

                  // Fixed Checkout Section - Always visible at bottom
                  _buildCheckoutSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // In cart_screen.dart - Update the _buildHeader method
  Widget _buildHeader(BuildContext context) {
    final cartViewModel = context.watch<CartViewModel>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Order',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  // Single Toggle Button
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: 150,
                    ), // Prevent overflow
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      onTap: () {
                        // Cycle through order types
                        if (cartViewModel.orderType == 'delivery') {
                          cartViewModel.setOrderType('takeaway');
                        } else if (cartViewModel.orderType == 'takeaway') {
                          cartViewModel.setOrderType('dinein');
                        } else {
                          cartViewModel.setOrderType('delivery');
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon based on order type
                            Icon(
                              _getOrderTypeIcon(cartViewModel.orderType),
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getOrderTypeText(cartViewModel.orderType),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => context.read<CartViewModel>().closeCart(),
                    icon: const Icon(Icons.close, size: 24),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Order Type Description
          Text(
            _getOrderTypeDescription(cartViewModel.orderType),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for order type
  IconData _getOrderTypeIcon(String orderType) {
    switch (orderType) {
      case 'delivery':
        return Icons.delivery_dining;
      case 'takeaway':
        return Icons.takeout_dining;
      case 'dinein':
        return Icons.restaurant;
      default:
        return Icons.delivery_dining;
    }
  }

  String _getOrderTypeText(String orderType) {
    switch (orderType) {
      case 'delivery':
        return 'Delivery';
      case 'takeaway':
        return 'Take Away';
      case 'dinein':
        return 'Dine In';
      default:
        return 'Delivery';
    }
  }

  String _getOrderTypeDescription(String orderType) {
    switch (orderType) {
      case 'delivery':
        return 'Your order will be delivered to your address';
      case 'takeaway':
        return 'Ready for pickup at our restaurant';
      case 'dinein':
        return 'Enjoy your meal at our restaurant';
      default:
        return 'Your order will be delivered to your address';
    }
  }

  Widget _buildCartContent(BuildContext context) {
    final cartViewModel = context.watch<CartViewModel>();

    if (cartViewModel.cartItems.isEmpty) {
      return _buildEmptyCart(context);
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          // Cart Items List
          _buildCartItemsList(context),

          // Special Instructions Section
          _buildSpecialInstructionsSection(context),

          // Add some bottom padding to ensure content doesn't hide behind fixed checkout section
          const SizedBox(
            height: 150,
          ), // Increased padding to account for checkout section height
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Column(
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
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            context.read<CartViewModel>().closeCart();
            widget.onOrderMore?.call();
          },
          style: ButtonStyles.primaryButton(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text('ORDER NOW'),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemsList(BuildContext context) {
    final cartViewModel = context.watch<CartViewModel>();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: cartViewModel.cartItems.length,
      itemBuilder: (context, index) {
        final item = cartViewModel.cartItems[index];
        return _buildCartItem(context, item);
      },
    );
  }

  Widget _buildSpecialInstructionsSection(BuildContext context) {
    return Container(
      key: _instructionsKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Special Instructions (Optional)',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _specialInstructionsController,
            focusNode: _instructionsFocusNode,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Any special requests or dietary requirements...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
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
                  // Item Description
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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

          // Buttons Row - Both buttons same size and height
          Row(
            children: [
              // Order More Button - Same size and height as checkout
              Expanded(
                child: SizedBox(
                  height: 50, // Fixed height to match checkout button
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<CartViewModel>().closeCart();
                      widget.onOrderMore?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                      side: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    child: Text(
                      'ORDER MORE',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Proceed to Checkout Button - Same size and height as order more
              Expanded(
                child: SizedBox(
                  height: 50, // Fixed height to match order more button
                  child: ElevatedButton(
                    onPressed: cartViewModel.cartItems.isEmpty
                        ? null
                        : () {
                            _showCheckoutDialog(context);
                          },
                    style: ButtonStyles.primaryButton(context),
                    child: Text(
                      'CHECKOUT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context) {
    final cartViewModel = context.read<CartViewModel>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Order'),
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
              'Confirm your order & Enjoy your meal!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity, // Take full width of dialog
            child: Row(
              children: [
                // Cancel Button - Fixed width
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                        side: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Place Order Button - Fixed width
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await cartViewModel.checkout(
                            specialInstructions:
                                _specialInstructionsController.text.isEmpty
                                ? null
                                : _specialInstructionsController.text.trim(),
                          );
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Order placed successfully!'),
                              backgroundColor: Theme.of(context).primaryColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          Navigator.pop(context);

                          if (e.toString().contains('MISSING_USER_INFO')) {
                            // Redirect to profile setup
                            _showMissingInfoDialog(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to place order: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: ButtonStyles.primaryButton(context),
                      child: Text(
                        'PLACE ORDER',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMissingInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Complete Your Profile'),
        content: Text(
          'Please complete your profile with name, phone number, and delivery address before placing an order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('LATER'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close this dialog
              Navigator.pop(context); // Close checkout dialog
              // Navigate to profile screen - you'll need to implement this
              _navigateToProfileScreen(context);
            },
            style: ButtonStyles.primaryButton(context),
            child: Text('UPDATE PROFILE'),
          ),
        ],
      ),
    );
  }

  void _navigateToProfileScreen(BuildContext context) {
    // You'll need to implement this based on your app structure
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Please navigate to profile screen to update your information',
        ),
        duration: Duration(seconds: 3),
      ),
    );

    // TODO: Replace with actual navigation to your profile screen
    // Example: Navigator.pushNamed(context, '/profile');
  }
}
