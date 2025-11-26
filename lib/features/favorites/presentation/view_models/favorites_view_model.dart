// lib/features/favorites/presentation/view_models/favorites_view_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../home/domain/models/food_item.dart';

class FavoritesViewModel with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<FoodItem> _favoriteItems = [];
  bool _isLoading = false;
  String _error = '';
  bool _hasData = false;

  // Getters
  List<FoodItem> get favoriteItems => _favoriteItems;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasData => _hasData;
  bool get hasFavorites => _favoriteItems.isNotEmpty;
  int get favoritesCount => _favoriteItems.length; // Add this back

  // Load user favorites
  Future<void> loadUserFavorites() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      _error = 'Please log in to view favorites';
      _hasData = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Get favorite item IDs
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      final favoriteIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();

      if (favoriteIds.isEmpty) {
        _favoriteItems = [];
        _hasData = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get the actual food items
      final foodItemsSnapshot = await _firestore
          .collection('foodItems')
          .where(FieldPath.documentId, whereIn: favoriteIds)
          .where('isAvailable', isEqualTo: true)
          .get();

      final foodItemsMap = {
        for (var doc in foodItemsSnapshot.docs)
          doc.id: FoodItem.fromMap({
            'id': doc.id,
            ...doc.data(),
            'isFavorite': true, // Force true since we're in favorites
          }),
      };

      _favoriteItems = favoriteIds
          .map((id) => foodItemsMap[id])
          .where((item) => item != null)
          .cast<FoodItem>()
          .toList();

      _hasData = true;
      _error = '';
    } catch (e) {
      _error = 'Failed to load favorites: $e';
      print('Error loading favorites: $e');
      _favoriteItems = [];
      _hasData = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove item from favorites
  Future<void> removeFromFavorites(String itemId, BuildContext context) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      _showSnackbar(context, 'Please log in to manage favorites');
      return;
    }

    try {
      // Remove from Firebase
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .doc(itemId)
          .delete();

      // Remove from local list
      _favoriteItems.removeWhere((item) => item.id == itemId);

      notifyListeners();
      _showSnackbar(context, 'Removed from favorites', isError: false);
    } catch (e) {
      print('Error removing favorite: $e');
      _showSnackbar(context, 'Failed to remove from favorites');
    }
  }

  // Clear all favorites
  Future<void> clearAllFavorites(BuildContext context) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      _showSnackbar(context, 'Please log in to manage favorites');
      return;
    }

    try {
      // Get all favorites
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .get();

      // Delete all in batch
      final batch = _firestore.batch();
      for (final doc in favoritesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Clear local list
      _favoriteItems.clear();

      notifyListeners();
      _showSnackbar(context, 'All favorites cleared', isError: false);
    } catch (e) {
      print('Error clearing favorites: $e');
      _showSnackbar(context, 'Failed to clear favorites');
    }
  }

  // Check if user is logged in
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Refresh favorites
  Future<void> refreshFavorites() async {
    await loadUserFavorites();
  }

  // Search within favorites
  List<FoodItem> searchFavorites(String query) {
    if (query.isEmpty) return _favoriteItems;

    return _favoriteItems
        .where(
          (item) =>
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              item.description.toLowerCase().contains(query.toLowerCase()) ||
              item.tags.any(
                (tag) => tag.toLowerCase().contains(query.toLowerCase()),
              ),
        )
        .toList();
  }

  // Helper method to show snackbar
  void _showSnackbar(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
