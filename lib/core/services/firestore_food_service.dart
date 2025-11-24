import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/home/domain/models/food_item.dart';
import '../../features/home/domain/models/food_category.dart';

class FirestoreFoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get foodItemsCollection =>
      _firestore.collection('food_items');
  CollectionReference get categoriesCollection =>
      _firestore.collection('categories');

  // Food Items Operations
  Stream<List<FoodItem>> getFoodItems() {
    return foodItemsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FoodItem.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList(),
        );
  }

  Stream<List<FoodItem>> getFoodItemsByCategory(String category) {
    return foodItemsCollection
        .where('category', isEqualTo: category)
        .where('isAvailable', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FoodItem.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList(),
        );
  }

  Stream<List<FoodItem>> getFeaturedFoodItems() {
    return foodItemsCollection
        .where('isFeatured', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FoodItem.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList(),
        );
  }

  Future<void> addFoodItem(FoodItem foodItem) async {
    try {
      await foodItemsCollection.add(foodItem.toMap());
    } catch (e) {
      throw Exception('Failed to add food item: $e');
    }
  }

  Future<void> updateFoodItem(String id, FoodItem foodItem) async {
    try {
      await foodItemsCollection.doc(id).update(foodItem.toMap());
    } catch (e) {
      throw Exception('Failed to update food item: $e');
    }
  }

  Future<void> deleteFoodItem(String id) async {
    try {
      await foodItemsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete food item: $e');
    }
  }

  // Categories Operations
  Stream<List<FoodCategory>> getCategories() {
    return categoriesCollection
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FoodCategory.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList(),
        );
  }

  Future<void> addCategory(FoodCategory category) async {
    try {
      await categoriesCollection.add(category.toMap());
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  // Search functionality
  Stream<List<FoodItem>> searchFoodItems(String query) {
    if (query.isEmpty) {
      return getFoodItems();
    }

    return foodItemsCollection
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FoodItem.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .where(
                (item) =>
                    item.name.toLowerCase().contains(query.toLowerCase()) ||
                    item.description.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    item.tags.any(
                      (tag) => tag.toLowerCase().contains(query.toLowerCase()),
                    ),
              )
              .toList(),
        );
  }
}
