// lib/features/home/domain/models/food_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String name;
  final String description;
  final List<FoodPortion> portions;
  final String imageUrl;
  final String category;
  final List<String> tags;
  final bool isAvailable;
  final bool isFeatured;
  final double? rating;
  final int? ratingCount;
  final int? preparationTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.portions,
    required this.imageUrl,
    required this.category,
    this.tags = const [],
    this.isAvailable = true,
    this.isFeatured = false,
    this.rating,
    this.ratingCount,
    this.preparationTime,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      portions: (map['portions'] as List<dynamic>? ?? [])
          .map((p) => FoodPortion.fromMap(p as Map<String, dynamic>))
          .toList(),
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      rating: map['rating'] != null ? (map['rating']).toDouble() : null,
      ratingCount: map['ratingCount'],
      preparationTime: map['preparationTime'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  /// ADD THIS — REQUIRED FIX
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'portions': portions.map((p) => p.toMap()).toList(),
      'imageUrl': imageUrl,
      'category': category,
      'tags': tags,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'rating': rating,
      'ratingCount': ratingCount,
      'preparationTime': preparationTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isFavorite': isFavorite,
    };
  }

  FoodItem copyWith({bool? isFavorite}) {
    return FoodItem(
      id: id,
      name: name,
      description: description,
      portions: portions,
      imageUrl: imageUrl,
      category: category,
      tags: tags,
      isAvailable: isAvailable,
      isFeatured: isFeatured,
      rating: rating,
      ratingCount: ratingCount,
      preparationTime: preparationTime,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  double get basePrice => portions.isNotEmpty ? portions.first.price : 0.0;
  String get formattedBasePrice => 'Rs${basePrice.toStringAsFixed(2)}';

  double get minPrice {
    if (portions.isEmpty) return 0.0;
    return portions.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (portions.isEmpty) return 0.0;
    return portions.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  }

  String get priceRange {
    if (portions.length <= 1) return formattedBasePrice;
    return 'Rs${minPrice.toStringAsFixed(2)} - Rs${maxPrice.toStringAsFixed(2)}';
  }
}

class FoodPortion {
  final String size;
  final double price;
  final String? description;
  final int? serves;

  FoodPortion({
    required this.size,
    required this.price,
    this.description,
    this.serves,
  });

  factory FoodPortion.fromMap(Map<String, dynamic> map) {
    return FoodPortion(
      size: map['size'] ?? 'Regular',
      price: (map['price'] ?? 0.0).toDouble(),
      description: map['description'],
      serves: map['serves'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'size': size,
      'price': price,
      'description': description,
      'serves': serves,
    };
  }

  String get formattedPrice => 'Rs${price.toStringAsFixed(2)}';

  String get displayText => serves != null ? '$size (Serves $serves)' : size;
}
