// lib/features/cart/presentation/view_models/cart_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jaan_broast/features/cart/domain/models/cart_item.dart';
import 'package:jaan_broast/features/cart/domain/models/order.dart'
    as cart_models;
import 'package:jaan_broast/core/services/firestore_cart_service.dart';
import 'package:jaan_broast/features/home/domain/models/food_item.dart';

class CartViewModel with ChangeNotifier {
  final FirestoreCartService _cartService;
  final List<CartItem> _cartItems = [];
  bool _isCartOpen = false;
  String _orderType = 'delivery'; // Default to delivery

  CartViewModel(this._cartService);

  List<CartItem> get cartItems => _cartItems;
  bool get isCartOpen => _isCartOpen;
  String get orderType => _orderType; // Add order type getter

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

  // Add order type setter
  void setOrderType(String type) {
    if (type == 'delivery' || type == 'takeaway' || type == 'dinein') {
      _orderType = type;
      notifyListeners();
    }
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

  // In cart_view_model.dart - Fix the checkout method
  Future<void> checkout({String? specialInstructions}) async {
    if (_cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to checkout');
    }

    print(
      '🔍 Checkout started - User: ${user.uid}, IsAnonymous: ${user.isAnonymous}, Order Type: $_orderType',
    );

    // Check if user has mandatory info (only for delivery)
    if (_orderType == 'delivery') {
      final hasInfo = await hasMandatoryUserInfo();
      if (!hasInfo) {
        throw Exception('MISSING_USER_INFO');
      }
    }

    // Fetch user data from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      throw Exception('User data not found');
    }

    final userData = userDoc.data()!;
    final personalInfo = userData['personalInfo'] as Map<String, dynamic>?;
    final addressData = userData['address'] as Map<String, dynamic>?;

    // Set delivery address only for delivery orders
    String? deliveryAddressValue;
    if (_orderType == 'delivery') {
      deliveryAddressValue = addressData?['fullAddress'] as String?;
    } else {
      deliveryAddressValue = null;
    }

    final order = cart_models.Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      items: List.from(_cartItems),
      totalAmount: totalAmount,
      orderDate: DateTime.now(),
      status: 'pending',
      deliveryAddress: deliveryAddressValue,
      specialInstructions: specialInstructions,
      customerName: personalInfo?['fullName'],
      customerPhone: personalInfo?['phoneNumber'],
      customerEmail: user.email,
      customerNotes: _buildDeliveryNotes(addressData),
      orderType: _orderType,
    );

    print(
      '🔍 Order created - Type: "$_orderType", Name: "${order.customerName}", Phone: "${order.customerPhone}"',
    );

    try {
      await _cartService.saveOrder(order);
      clearCart();
      closeCart();
    } catch (e) {
      throw Exception('Checkout failed: $e');
    }
  }

  String _buildDeliveryAddress(Map<String, dynamic> addressData) {
    final components = [
      addressData['street'],
      addressData['city'],
      addressData['state'],
      addressData['zipCode'],
    ].where((component) => component != null && component.isNotEmpty).toList();

    return components.join(', ');
  }

  String? _buildDeliveryNotes(Map<String, dynamic>? addressData) {
    if (addressData == null) return null;

    final notes = [
      if (addressData['houseNumber'] != null)
        'House: ${addressData['houseNumber']}',
      if (addressData['apartment'] != null)
        'Apartment: ${addressData['apartment']}',
      if (addressData['floor'] != null) 'Floor: ${addressData['floor']}',
      if (addressData['landmark'] != null)
        'Landmark: ${addressData['landmark']}',
      if (addressData['deliveryInstructions'] != null)
        'Instructions: ${addressData['deliveryInstructions']}',
    ].where((note) => note != null).toList();

    return notes.isNotEmpty ? notes.join(', ') : null;
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

  Future<bool> hasMandatoryUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final personalInfo = userData['personalInfo'] as Map<String, dynamic>?;
      final addressData = userData['address'] as Map<String, dynamic>?;

      // Check if all mandatory fields are present and not empty
      final hasName = personalInfo?['fullName']?.toString().isNotEmpty == true;
      final hasPhone =
          personalInfo?['phoneNumber']?.toString().isNotEmpty == true;
      final hasAddress =
          addressData?['fullAddress']?.toString().isNotEmpty == true;

      return hasName && hasPhone && hasAddress;
    } catch (e) {
      print('Error checking user info: $e');
      return false;
    }
  }
}
