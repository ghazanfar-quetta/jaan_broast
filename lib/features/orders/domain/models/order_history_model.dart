import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jaan_broast/features/cart/domain/models/cart_item.dart';

class OrderHistory {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final OrderStatus status;
  final String? deliveryAddress;
  final String? customerName;
  final String? customerPhone;
  final OrderType orderType;

  OrderHistory({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    this.deliveryAddress,
    this.customerName,
    this.customerPhone,
    this.orderType = OrderType.delivery,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'orderDate': Timestamp.fromDate(orderDate),
      'status': status.value,
      'deliveryAddress': deliveryAddress,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'orderType': orderType.value,
      'updatedAt': Timestamp.now(),
    };
  }

  factory OrderHistory.fromMap(Map<String, dynamic> map) {
    return OrderHistory(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      items: List<CartItem>.from(
        (map['items'] as List<dynamic>).map(
          (item) => CartItem.fromMap(item as Map<String, dynamic>),
        ),
      ),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      orderDate: (map['orderDate'] as Timestamp).toDate(),
      status: OrderStatus.fromString(map['status'] ?? 'pending'),
      deliveryAddress: map['deliveryAddress'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      orderType: OrderType.fromString(map['orderType'] ?? 'delivery'),
    );
  }

  String get formattedTotal => 'Rs${totalAmount.toStringAsFixed(2)}';

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  String get formattedDate {
    return '${orderDate.day}/${orderDate.month}/${orderDate.year}';
  }

  String get formattedTime {
    return '${orderDate.hour.toString().padLeft(2, '0')}:${orderDate.minute.toString().padLeft(2, '0')}';
  }

  // Helper method to display order type
  String get orderTypeDisplay {
    return orderType.displayName;
  }

  // Helper method to display delivery info
  String? get deliveryInfo {
    if (orderType == OrderType.delivery && deliveryAddress != null) {
      return 'Delivery: $deliveryAddress';
    } else if (orderType == OrderType.takeAway) {
      return 'Take Away';
    } else if (orderType == OrderType.dineIn) {
      return 'Dine In';
    }
    return null;
  }
}

enum OrderType {
  delivery('delivery', 'Delivery'),
  takeAway('take_away', 'Take Away'),
  dineIn('dine_in', 'Dine In');

  final String value;
  final String displayName;

  const OrderType(this.value, this.displayName);

  static OrderType fromString(String type) {
    switch (type) {
      case 'delivery':
        return OrderType.delivery;
      case 'take_away':
        return OrderType.takeAway;
      case 'dine_in':
        return OrderType.dineIn;
      default:
        return OrderType.delivery;
    }
  }
}

enum OrderStatus {
  live('live', 'Live'),
  confirmed('confirmed', 'Confirmed'),
  inProcess('in_process', 'In Process'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String displayName;

  const OrderStatus(this.value, this.displayName);

  static OrderStatus fromString(String status) {
    switch (status) {
      case 'live':
        return OrderStatus.live;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'in_process':
        return OrderStatus.inProcess;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.live; // Default to live if unknown
    }
  }

  Color getStatusColor(BuildContext context) {
    switch (this) {
      case OrderStatus.live:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.inProcess:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}
