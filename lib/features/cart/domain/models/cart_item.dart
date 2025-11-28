// lib/features/cart/domain/models/cart_item.dart
class CartItem {
  final String id;
  final String foodItemId;
  final String name;
  final String description;
  final String imageUrl;
  final String selectedSize;
  final double price;
  int quantity;
  final String? specialInstructions;

  CartItem({
    required this.id,
    required this.foodItemId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.selectedSize,
    required this.price,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get totalPrice => price * quantity;

  CartItem copyWith({
    int? quantity,
    String? specialInstructions,
    String? selectedSize,
    double? price,
  }) {
    return CartItem(
      id: id,
      foodItemId: foodItemId,
      name: name,
      description: description,
      imageUrl: imageUrl,
      selectedSize: selectedSize ?? this.selectedSize,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodItemId': foodItemId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'selectedSize': selectedSize,
      'price': price,
      'quantity': quantity,
      'specialInstructions': specialInstructions,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      foodItemId: map['foodItemId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      selectedSize: map['selectedSize'] ?? 'Regular',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      specialInstructions: map['specialInstructions'],
    );
  }
}
