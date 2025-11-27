// lib/features/favorites/presentation/view_models/favorites_view_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../home/domain/models/food_item.dart';
import 'package:jaan_broast/core/services/favorites_manager_service.dart';
import 'package:jaan_broast/features/home/presentation/view_models/home_view_model.dart';

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
  int get favoritesCount => _favoriteItems.length;

  // Load user favorites using the shared service
  // In FavoritesViewModel - Update loadUserFavorites method
  Future<void> loadUserFavorites(BuildContext context) async {
    final favoritesManager = Provider.of<FavoritesManagerService>(
      context,
      listen: false,
    );
    final currentUser = _auth.currentUser;

    // BLOCK GUEST USERS COMPLETELY
    if (currentUser == null) {
      _error = 'Please log in to view favorites';
      _hasData = false;
      _favoriteItems = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Load favorites through the shared service
      await favoritesManager.loadUserFavorites();

      // Get favorite item IDs from shared service
      final favoriteIds = favoritesManager.favoriteItemIds;

      if (favoriteIds.isEmpty) {
        _favoriteItems = [];
        _hasData = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get the actual food items for these IDs from Firestore
      final foodItemsSnapshot = await _firestore
          .collection('foodItems')
          .where(FieldPath.documentId, whereIn: favoriteIds)
          .where('isAvailable', isEqualTo: true)
          .get();

      // Create a map for quick lookup
      final foodItemsMap = {
        for (var doc in foodItemsSnapshot.docs)
          doc.id: FoodItem.fromMap({'id': doc.id, ...doc.data()}),
      };

      // Rebuild the list in the order of favoriteIds
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove item from favorites using shared service
  Future<void> removeFromFavorites(
    String foodItemId,
    BuildContext context,
  ) async {
    final favoritesManager = Provider.of<FavoritesManagerService>(
      context,
      listen: false,
    );
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      _showSnackbar(context, 'Please log in to manage favorites');
      return;
    }

    try {
      // Remove from Firestore
      final favRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .doc(foodItemId);
      await favRef.delete();

      // Remove from local storage using shared service
      await favoritesManager.removeFromFavorites(foodItemId);

      // Remove locally from current list
      _favoriteItems.removeWhere((item) => item.id == foodItemId);

      notifyListeners();
      _showSnackbar(context, 'Removed from favorites', isError: false);
    } catch (e) {
      print('Error removing favorite: $e');
      _showSnackbar(context, 'Failed to remove');
    }
  }

  // Clear all favorites using shared service
  // In FavoritesViewModel - replace the clearAllFavorites method
  Future<void> clearAllFavorites(BuildContext context) async {
    final favoritesManager = Provider.of<FavoritesManagerService>(
      context,
      listen: false,
    );
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      _showSnackbar(context, 'Please log in to manage favorites');
      return;
    }

    try {
      // Use the shared service to clear all favorites (this will handle both local and Firestore)
      await favoritesManager.clearAllFavorites();

      // Clear local list
      _favoriteItems.clear();

      // NOTIFY HOME VIEW MODEL TO REFRESH
      final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
      await homeViewModel.refreshData(context); // This will reload home data

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
  Future<void> refreshFavorites(BuildContext context) async {
    await loadUserFavorites(context);
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
