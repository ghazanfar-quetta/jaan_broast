// lib/core/services/firebase_food_service.dart
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

  // Add to FirestoreFoodService class in lib/core/services/firestore_food_service.dart

  // Favorites Operations
  Stream<List<FoodItem>> getFavoriteFoodItems(String userId) {
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
              .where((item) => item.isFavorite)
              .toList(),
        );
  }

  Future<void> toggleFavoriteStatus(
    String foodItemId,
    bool isFavorite,
    String uid,
    FoodItem item,
  ) async {
    final favRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(foodItemId);

    try {
      if (isFavorite) {
        // ADD DOCUMENT FOR FAVORITE
        await favRef.set({
          'id': item.id,
          'name': item.name,
          'imageUrl': item.imageUrl,
          'category': item.category,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // REMOVE FAVORITE
        await favRef.delete();
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite status: $e');
    }
  }

  Stream<List<FoodItem>> getUserFavorites(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .asyncMap((favoritesSnapshot) async {
          final favoriteIds = favoritesSnapshot.docs
              .map((doc) => doc.id)
              .toList();

          if (favoriteIds.isEmpty) return [];

          final foodItemsSnapshot = await foodItemsCollection
              .where(FieldPath.documentId, whereIn: favoriteIds)
              .where('isAvailable', isEqualTo: true)
              .get();

          return foodItemsSnapshot.docs
              .map(
                (doc) => FoodItem.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList();
        });
  }

  Future<void> addToFavorites(String userId, String foodItemId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(foodItemId)
          .set({'addedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  Future<void> removeFromFavorites(String userId, String foodItemId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(foodItemId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  // Check if item is favorite
  Stream<bool> isItemFavorite(String userId, String foodItemId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(foodItemId)
        .snapshots()
        .map((doc) => doc.exists);
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

  /// Add a favorite for a user (creates users/{uid}/favorites/{foodItemId})
  Future<void> addFavorite({
    required String uid,
    required FoodItem item,
  }) async {
    final favRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(item.id);

    try {
      await favRef.set({
        'id': item.id,
        'name': item.name,
        'imageUrl': item.imageUrl,
        'category': item.category,
        // any other fields you want to keep
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  /// Remove a favorite for a user
  Future<void> removeFavorite({
    required String uid,
    required String foodItemId,
  }) async {
    final favRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(foodItemId);

    try {
      await favRef.delete();
    } catch (e) {
      // If doc doesn't exist, deletion will still pass; still catch unexpected errors
      throw Exception('Failed to remove favorite: $e');
    }
  }
}
