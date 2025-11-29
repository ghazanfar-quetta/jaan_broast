import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jaan_broast/features/orders/domain/models/order_history_model.dart';

class FirestoreOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<OrderHistory>> getOrdersStream(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where(
          'status',
          isNotEqualTo: 'cancelled',
        ) // Exclude cancelled orders from main stream
        .orderBy('status') // Sort by status for consistent ordering
        .orderBy('orderDate', descending: true) // Then by date
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderHistory.fromMap(doc.data()))
              .toList();
        });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status.value,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> cancelOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': 'cancelled',
      'updatedAt': Timestamp.now(),
      'cancelledAt': Timestamp.now(), // Add cancellation timestamp
    });
  }

  // Get cancelled orders separately if needed
  Stream<List<OrderHistory>> getCancelledOrdersStream(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'cancelled')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderHistory.fromMap(doc.data()))
              .toList();
        });
  }
}
