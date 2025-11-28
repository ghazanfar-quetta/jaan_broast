import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:jaan_broast/features/cart/domain/models/order.dart'
    as cart_models; // Add alias

class FirestoreCartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveOrder(cart_models.Order order) async {
    // Use alias
    try {
      await _firestore.collection('orders').doc(order.id).set(order.toMap());
    } catch (e) {
      throw Exception('Failed to save order: $e');
    }
  }

  Stream<List<cart_models.Order>> getUserOrders(String userId) {
    // Use alias
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => cart_models.Order.fromMap(doc.data()!),
              ) // Add null check
              .toList(),
        );
  }

  Future<List<cart_models.Order>> getRecentOrders(
    String userId, {
    int limit = 10,
  }) async {
    // Use alias
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => cart_models.Order.fromMap(doc.data()!),
          ) // Add null check
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Get order statistics for admin dashboard
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      final orders = snapshot.docs
          .map(
            (doc) => cart_models.Order.fromMap(doc.data()!),
          ) // Add null check
          .toList();

      final totalOrders = orders.length;
      final pendingOrders = orders
          .where((order) => order.status == 'pending')
          .length;
      final completedOrders = orders
          .where((order) => order.status == 'completed')
          .length;
      final totalRevenue = orders.fold(
        0.0,
        (sum, order) => sum + order.totalAmount,
      );

      return {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      throw Exception('Failed to fetch order stats: $e');
    }
  }
}
