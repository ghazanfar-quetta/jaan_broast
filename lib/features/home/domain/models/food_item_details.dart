import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_item.dart';

class FoodItemDetails extends FoodItem {
  final List<String> ingredients;
  final Map<String, double> addOnPrices;
  final List<String> dietaryRestrictions;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final int calories;
  final List<String> allergens;

  FoodItemDetails({
    required String id,
    required String name,
    required String description,
    required List<FoodPortion> portions,
    required String imageUrl,
    required String category,
    List<String> tags = const [],
    bool isAvailable = true,
    bool isFeatured = false,
    double? rating,
    int? ratingCount,
    int? preparationTime,
    required DateTime createdAt,
    required DateTime updatedAt,
    bool isFavorite = false,
    this.ingredients = const [],
    this.addOnPrices = const {},
    this.dietaryRestrictions = const [],
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
    this.calories = 0,
    this.allergens = const [],
  }) : super(
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
         isFavorite: isFavorite,
       );

  // Factory method to create from FoodItem
  factory FoodItemDetails.fromFoodItem(
    FoodItem foodItem, {
    List<String> ingredients = const [],
    Map<String, double> addOnPrices = const {},
    List<String> dietaryRestrictions = const [],
    bool isVegetarian = false,
    bool isVegan = false,
    bool isGlutenFree = false,
    int calories = 0,
    List<String> allergens = const [],
  }) {
    return FoodItemDetails(
      id: foodItem.id,
      name: foodItem.name,
      description: foodItem.description,
      portions: foodItem.portions,
      imageUrl: foodItem.imageUrl,
      category: foodItem.category,
      tags: foodItem.tags,
      isAvailable: foodItem.isAvailable,
      isFeatured: foodItem.isFeatured,
      rating: foodItem.rating,
      ratingCount: foodItem.ratingCount,
      preparationTime: foodItem.preparationTime,
      createdAt: foodItem.createdAt,
      updatedAt: foodItem.updatedAt,
      isFavorite: foodItem.isFavorite,
      ingredients: ingredients,
      addOnPrices: addOnPrices,
      dietaryRestrictions: dietaryRestrictions,
      isVegetarian: isVegetarian,
      isVegan: isVegan,
      isGlutenFree: isGlutenFree,
      calories: calories,
      allergens: allergens,
    );
  }

  // Create from Firestore document with extended details
  factory FoodItemDetails.fromFirestore(Map<String, dynamic> data) {
    final baseItem = FoodItem.fromMap(data);

    return FoodItemDetails(
      id: baseItem.id,
      name: baseItem.name,
      description: baseItem.description,
      portions: baseItem.portions,
      imageUrl: baseItem.imageUrl,
      category: baseItem.category,
      tags: baseItem.tags,
      isAvailable: baseItem.isAvailable,
      isFeatured: baseItem.isFeatured,
      rating: baseItem.rating,
      ratingCount: baseItem.ratingCount,
      preparationTime: baseItem.preparationTime,
      createdAt: baseItem.createdAt,
      updatedAt: baseItem.updatedAt,
      isFavorite: baseItem.isFavorite,
      ingredients: List<String>.from(data['ingredients'] ?? []),
      addOnPrices: Map<String, double>.from(data['addOnPrices'] ?? {}),
      dietaryRestrictions: List<String>.from(data['dietaryRestrictions'] ?? []),
      isVegetarian: data['isVegetarian'] ?? false,
      isVegan: data['isVegan'] ?? false,
      isGlutenFree: data['isGlutenFree'] ?? false,
      calories: data['calories'] ?? 0,
      allergens: List<String>.from(data['allergens'] ?? []),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    baseMap.addAll({
      'ingredients': ingredients,
      'addOnPrices': addOnPrices,
      'dietaryRestrictions': dietaryRestrictions,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'calories': calories,
      'allergens': allergens,
    });
    return baseMap;
  }

  // Helper methods for the details screen
  List<String> get availableAddOns => addOnPrices.keys.toList();

  double getAddOnPrice(String addOn) => addOnPrices[addOn] ?? 0.0;

  bool get hasDietaryInfo =>
      isVegetarian || isVegan || isGlutenFree || dietaryRestrictions.isNotEmpty;

  String get dietaryInfo {
    final info = [];
    if (isVegetarian) info.add('Vegetarian');
    if (isVegan) info.add('Vegan');
    if (isGlutenFree) info.add('Gluten-Free');
    info.addAll(dietaryRestrictions);
    return info.join(' • ');
  }

  // Get default portion (first one or Regular if exists)
  FoodPortion? get defaultPortion {
    if (portions.isEmpty) return null;
    final regular = portions.firstWhere(
      (p) => p.size.toLowerCase() == 'regular',
      orElse: () => portions.first,
    );
    return regular;
  }
}
