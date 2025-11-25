// lib/features/home/domain/models/food_item.dart
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
  final bool isFavorite; // Add this field

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
    this.isFavorite = false, // Default to false
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    final List<dynamic> portionsData = map['portions'] ?? [];
    final List<FoodPortion> portions = portionsData.isNotEmpty
        ? portionsData.map((portion) => FoodPortion.fromMap(portion)).toList()
        : [
            FoodPortion(
              size: 'Regular',
              price: (map['price'] ?? 0.0).toDouble(),
            ),
          ];

    final createdAt = map['createdAt'] != null
        ? DateTime.parse(map['createdAt'])
        : DateTime.now();
    final updatedAt = map['updatedAt'] != null
        ? DateTime.parse(map['updatedAt'])
        : DateTime.now();

    return FoodItem(
      id: map['id'] ?? map['documentId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      portions: portions,
      imageUrl: map['imageUrl'] ?? map['image'] ?? '',
      category: map['category'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      rating: (map['rating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      preparationTime: map['preparationTime'] ?? map['cookTime'] ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isFavorite: map['isFavorite'] ?? false, // Add this
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'portions': portions.map((portion) => portion.toMap()).toList(),
      'imageUrl': imageUrl,
      'category': category,
      'tags': tags,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'rating': rating,
      'ratingCount': ratingCount,
      'preparationTime': preparationTime,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorite': isFavorite, // Add this
    };
  }

  // Add copyWith method for updating favorite status
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

  // Helper methods
  double get basePrice => portions.isNotEmpty ? portions.first.price : 0.0;
  String get formattedBasePrice => 'Rs${basePrice.toStringAsFixed(2)}';

  // Get min and max prices for price range display
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
  final int? serves; // Number of people this portion serves

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

  String get displayText {
    if (serves != null) {
      return '$size (Serves $serves)';
    }
    return size;
  }
}
