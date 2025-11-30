import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this import for context.read
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jaan_broast/features/orders/domain/models/order_history_model.dart';
import 'package:jaan_broast/features/cart/presentation/view_models/cart_view_model.dart';
import 'package:jaan_broast/features/cart/domain/models/cart_item.dart';
import 'package:jaan_broast/core/services/firestore_order_service.dart';

class OrderViewModel with ChangeNotifier {
  final FirestoreOrderService _orderService;
  List<OrderHistory> _orders = [];
  bool _isLoading = false;
  String _error = '';
  StreamSubscription<List<OrderHistory>>? _ordersSubscription;

  OrderViewModel() : _orderService = FirestoreOrderService();

  List<OrderHistory> get orders => _orders;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Initialize real-time stream
  void initializeOrdersStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    _ordersSubscription = _orderService
        .getOrdersStream(user.uid)
        .listen(
          (orders) {
            _orders = orders;
            _isLoading = false;
            _error = '';
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _error = 'Failed to load orders: $error';
            notifyListeners();
          },
        );
  }

  // For initial load (fallback)
  Future<void> loadOrders() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('orderDate', descending: true)
          .get();

      _orders.clear();
      _orders.addAll(
        snapshot.docs.map((doc) => OrderHistory.fromMap(doc.data())),
      );
    } catch (e) {
      _error = 'Failed to load orders: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if order can be cancelled (only live orders)
  bool canCancelOrder(OrderHistory order) {
    return order.status == OrderStatus.live;
  }

  // Check if order can be re-ordered (only completed orders)
  bool canReorderOrder(OrderHistory order) {
    return order.status == OrderStatus.completed;
  }

  // Cancel order with confirmation
  Future<void> cancelOrderWithConfirmation(String orderId) async {
    try {
      await _orderService.cancelOrder(orderId);
      // No need to update UI manually - stream will handle it
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Re-order functionality - adds all items from completed order to cart
  // Re-order functionality - adds all items from completed order to cart
  Future<void> reorderItems(OrderHistory order, BuildContext context) async {
    try {
      final cartViewModel = context.read<CartViewModel>();

      // Add each item from the order to cart
      for (var item in order.items) {
        final cartItem = CartItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${item.foodItemId}',
          foodItemId: item.foodItemId,
          name: item.name,
          description: item.description,
          imageUrl: item.imageUrl,
          selectedSize: item.selectedSize,
          price: item.price,
          quantity: item.quantity,
          specialInstructions: item.specialInstructions,
        );
        cartViewModel.addToCart(cartItem);
      }
    } catch (e) {
      throw Exception('Failed to reorder items: $e');
    }
  }

  List<OrderHistory> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  bool hasOrdersInStatus(OrderStatus status) {
    return _orders.any((order) => order.status == status);
  }

  // Get cancelled orders separately (for future use if needed)
  List<OrderHistory> get cancelledOrders {
    return _orders
        .where((order) => order.status == OrderStatus.cancelled)
        .toList();
  }

  // Clean up subscription - FIXED: call super.dispose()
  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose(); // Add this line
  }
}
