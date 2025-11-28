// lib/features/cart/presentation/view_models/cart_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jaan_broast/features/cart/domain/models/cart_item.dart';
import 'package:jaan_broast/features/cart/domain/models/order.dart'
    as cart_models;
import 'package:jaan_broast/core/services/firestore_cart_service.dart';
import 'package:jaan_broast/features/home/domain/models/food_item.dart';

class CartViewModel with ChangeNotifier {
  final FirestoreCartService _cartService;
  final List<CartItem> _cartItems = [];
  bool _isCartOpen = false;

  CartViewModel(this._cartService);

  List<CartItem> get cartItems => _cartItems;
  bool get isCartOpen => _isCartOpen;

  double get totalAmount {
    return _cartItems.fold(0, (total, item) => total + item.totalPrice);
  }

  int get totalItems {
    return _cartItems.fold(0, (total, item) => total + item.quantity);
  }

  bool get isCartEmpty => _cartItems.isEmpty;

  void openCart() {
    _isCartOpen = true;
    notifyListeners();
  }

  void closeCart() {
    _isCartOpen = false;
    notifyListeners();
  }

  void addToCart(CartItem item) {
    final existingIndex = _cartItems.indexWhere(
      (cartItem) =>
          cartItem.foodItemId == item.foodItemId &&
          cartItem.selectedSize == item.selectedSize,
    );

    if (existingIndex != -1) {
      _cartItems[existingIndex].quantity += item.quantity;
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(String cartItemId) {
    _cartItems.removeWhere((item) => item.id == cartItemId);
    notifyListeners();
  }

  void updateQuantity(String cartItemId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.id == cartItemId);
    if (index != -1) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void updateSpecialInstructions(String cartItemId, String instructions) {
    final index = _cartItems.indexWhere((item) => item.id == cartItemId);
    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(
        specialInstructions: instructions.isEmpty ? null : instructions,
      );
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<void> checkout({
    required String userId,
    String? deliveryAddress,
    String? specialInstructions,
    String? customerName,
    String? customerPhone,
  }) async {
    if (_cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    final order = cart_models.Order(
      // Use alias
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      items: List.from(_cartItems),
      totalAmount: totalAmount,
      orderDate: DateTime.now(),
      deliveryAddress: deliveryAddress,
      specialInstructions: specialInstructions,
      customerName: customerName,
      customerPhone: customerPhone,
    );

    try {
      await _cartService.saveOrder(order);
      clearCart();
      closeCart();
    } catch (e) {
      throw Exception('Checkout failed: $e');
    }
  }

  // Helper method to create CartItem from FoodItem
  CartItem createCartItemFromFoodItem({
    required String foodItemId,
    required String name,
    required String description,
    required String imageUrl,
    required String selectedSize,
    required double price,
    int quantity = 1,
    String? specialInstructions,
  }) {
    return CartItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_$foodItemId',
      foodItemId: foodItemId,
      name: name,
      description: description,
      imageUrl: imageUrl,
      selectedSize: selectedSize,
      price: price,
      quantity: quantity,
      specialInstructions: specialInstructions,
    );
  }

  // Check if a food item with specific size is already in cart
  bool isItemInCart(String foodItemId, String size) {
    return _cartItems.any(
      (item) => item.foodItemId == foodItemId && item.selectedSize == size,
    );
  }

  // Get quantity of a specific food item with size in cart
  int getItemQuantity(String foodItemId, String size) {
    final item = _cartItems.firstWhere(
      (item) => item.foodItemId == foodItemId && item.selectedSize == size,
      orElse: () => CartItem(
        id: '',
        foodItemId: '',
        name: '',
        description: '',
        imageUrl: '',
        selectedSize: '',
        price: 0,
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  void addFoodItemToCart(FoodItem foodItem, FoodPortion portion) {
    final cartItem = createCartItemFromFoodItem(
      foodItemId: foodItem.id,
      name: foodItem.name,
      description: foodItem.description,
      imageUrl: foodItem.imageUrl,
      selectedSize: portion.size,
      price: portion.price,
      quantity: 1,
    );

    addToCart(cartItem);
  }
}
