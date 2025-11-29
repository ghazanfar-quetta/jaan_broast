import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jaan_broast/core/widgets/custom_app_bar.dart';
import 'package:jaan_broast/core/utils/screen_utils.dart';
import 'package:jaan_broast/features/orders/domain/models/order_history_model.dart';
import 'package:jaan_broast/features/orders/presentation/view_models/order_view_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<OrderStatus> _tabs = [
    OrderStatus.pending, // Live
    OrderStatus.confirmed, // Confirmed
    OrderStatus.outForDelivery, // In Process
    OrderStatus.delivered, // Completed
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    // Initialize real-time stream when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderViewModel = context.read<OrderViewModel>();
      orderViewModel.initializeOrdersStream();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Don't dispose the ViewModel here as it's managed by Provider
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Order History', showBackButton: false),
      body: Column(
        children: [
          // Fixed Tab Bar - No extra space
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: _tabs.map((status) {
                return Tab(text: status.displayName);
              }).toList(),
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                fontSize: ScreenUtils.responsiveValue(
                  context,
                  mobile: 12,
                  tablet: 14,
                  desktop: 16,
                ),
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: ScreenUtils.responsiveValue(
                  context,
                  mobile: 12,
                  tablet: 14,
                  desktop: 16,
                ),
                fontWeight: FontWeight.w500,
              ),
              isScrollable:
                  false, // Changed to false to fit all tabs in one screen
              indicatorWeight: 3,
              padding: EdgeInsets.zero, // Remove all padding
              indicatorPadding: EdgeInsets.zero, // Remove indicator padding
              labelPadding: EdgeInsets.zero, // Remove label padding
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((status) {
                return _buildOrderListByStatus(status);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Alternative: Using Container with custom padding for better control
  Widget _buildCustomTabBar() {
    return Container(
      height: 48, // Fixed height
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: _tabs.map((status) {
          return Tab(
            child: Text(
              status.displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ScreenUtils.responsiveValue(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
              ),
            ),
          );
        }).toList(),
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6),
        indicatorColor: Theme.of(context).primaryColor,
        indicatorWeight: 3,
        isScrollable: false, // All tabs in one row
        padding: const EdgeInsets.symmetric(
          horizontal: 0,
        ), // No horizontal padding
        indicatorPadding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(
          horizontal: 4,
        ), // Minimal padding
      ),
    );
  }

  Widget _buildOrderListByStatus(OrderStatus status) {
    return Consumer<OrderViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.orders.isEmpty) {
          return _buildLoadingState();
        }

        if (viewModel.error.isNotEmpty) {
          return _buildErrorState(viewModel.error);
        }

        final orders = viewModel.getOrdersByStatus(status);

        if (orders.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: () => viewModel.loadOrders(),
          child: ListView.builder(
            padding: EdgeInsets.all(
              ScreenUtils.responsiveValue(
                context,
                mobile: 12,
                tablet: 16,
                desktop: 20,
              ),
            ),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: ScreenUtils.responsiveValue(
                    context,
                    mobile: 12,
                    tablet: 16,
                    desktop: 20,
                  ),
                ),
                child: _buildOrderCard(orders[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderHistory order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(
          ScreenUtils.responsiveValue(
            context,
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header (existing code)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(order.id.length - 6)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.formattedDate} • ${order.formattedTime}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      // Order Type and Delivery Info
                      if (order.deliveryInfo != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          order.deliveryInfo!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: order.status
                        .getStatusColor(context)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: order.status.getStatusColor(context),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: order.status.getStatusColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Order Items Preview (existing code)
            _buildOrderItemsPreview(order),
            const SizedBox(height: 16),
            // Order Footer (existing code)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.totalItems} item${order.totalItems > 1 ? 's' : ''}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  order.formattedTotal,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            // Action Buttons (NEW - for cancellation)
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsPreview(OrderHistory order) {
    final previewItems = order.items.take(2).toList();
    final hasMoreItems = order.items.length > 2;

    return Column(
      children: [
        ...previewItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item.quantity}x ${item.name}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Rs${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        if (hasMoreItems)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ ${order.items.length - 2} more items',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
      ],
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
            'Loading your orders...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load orders',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<OrderViewModel>().loadOrders(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(OrderStatus status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${status.displayName} Orders',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your ${status.displayName.toLowerCase()} orders will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderHistory order) {
    final orderViewModel = context.read<OrderViewModel>();

    if (orderViewModel.canCancelOrder(order)) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showCancelConfirmationDialog(context, order),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Cancel Order',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return const SizedBox();
  }

  void _showCancelConfirmationDialog(BuildContext context, OrderHistory order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Keep Order',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              await _cancelOrder(context, order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context, OrderHistory order) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final orderViewModel = context.read<OrderViewModel>();

    try {
      // Show loading
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Cancelling order...'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await orderViewModel.cancelOrderWithConfirmation(order.id);

      // Success message will be shown automatically when stream updates
    } catch (e) {
      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
