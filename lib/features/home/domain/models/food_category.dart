class FoodCategory {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int displayOrder; // For sorting categories
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.displayOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodCategory.fromMap(Map<String, dynamic> map) {
    final createdAt = map['createdAt'] != null
        ? DateTime.parse(map['createdAt'])
        : DateTime.now();
    final updatedAt = map['updatedAt'] != null
        ? DateTime.parse(map['updatedAt'])
        : DateTime.now();

    return FoodCategory(
      id: map['id'] ?? map['documentId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      displayOrder: map['displayOrder'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
