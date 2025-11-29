// lib/features/cart/domain/models/order.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart'; // Add this import

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final String status;
  final String? deliveryAddress;
  final String? specialInstructions;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail; // Add this
  final String? customerNotes; // Add this for delivery instructions
  final String orderType;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    this.status = 'pending',
    this.deliveryAddress,
    this.specialInstructions,
    this.customerName,
    this.customerPhone,
    this.customerEmail, // Add this
    this.customerNotes, // Add this
    required this.orderType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'orderDate': Timestamp.fromDate(orderDate),
      'status': status,
      'deliveryAddress': deliveryAddress,
      'specialInstructions': specialInstructions,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail, // Add this
      'customerNotes': customerNotes, // Add this
      'orderType': orderType,
      'createdAt': Timestamp.now(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      items: List<CartItem>.from(
        (map['items'] as List<dynamic>).map(
          (item) => CartItem.fromMap(item as Map<String, dynamic>),
        ),
      ),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      orderDate: (map['orderDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      deliveryAddress: map['deliveryAddress'],
      specialInstructions: map['specialInstructions'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      customerEmail: map['customerEmail'], // Add this
      customerNotes: map['customerNotes'], // Add this
      orderType: map['orderType'] ?? 'delivery',
    );
  }

  String get formattedTotal => 'Rs${totalAmount.toStringAsFixed(2)}';

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}
