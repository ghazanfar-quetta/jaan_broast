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
  // In FavoritesViewModel - Fix removeFromFavorites context warning
  // In FavoritesViewModel - Fix removeFromFavorites using public method
  Future<void> removeFromFavorites(
    String foodItemId,
    BuildContext context,
  ) async {
    final currentContext = context;
    final favoritesManager = Provider.of<FavoritesManagerService>(
      currentContext,
      listen: false,
    );
    final currentUser = _auth.currentUser;

    if (currentUser == null || currentUser.isAnonymous) {
      if (currentContext.mounted) {
        _showSnackbar(currentContext, 'Please log in to manage favorites');
      }
      return;
    }

    try {
      // Remove from both Firestore and local storage
      await favoritesManager.removeFromFavorites(foodItemId);

      // Remove locally from current list
      _favoriteItems.removeWhere((item) => item.id == foodItemId);

      // Update HomeViewModel using public method
      final homeViewModel = Provider.of<HomeViewModel>(
        currentContext,
        listen: false,
      );
      homeViewModel.clearFavoriteStateForItem(foodItemId);

      notifyListeners();

      if (currentContext.mounted) {
        _showSnackbar(currentContext, 'Removed from favorites', isError: false);
      }
    } catch (e) {
      print('Error removing favorite: $e');
      if (currentContext.mounted) {
        _showSnackbar(currentContext, 'Failed to remove');
      }
    }
  }

  // Updated clearAllFavorites method
  Future<void> clearAllFavorites(BuildContext context) async {
    final currentContext = context;
    final favoritesManager = Provider.of<FavoritesManagerService>(
      currentContext,
      listen: false,
    );
    final currentUser = _auth.currentUser;

    if (currentUser == null || currentUser.isAnonymous) {
      if (currentContext.mounted) {
        _showSnackbar(currentContext, 'Please log in to manage favorites');
      }
      return;
    }

    try {
      // Get item IDs before clearing (for HomeViewModel update)
      final favoriteItemIds = _favoriteItems.map((item) => item.id).toList();

      // Clear using the shared service
      favoritesManager.clearAllFavorites();

      // Clear local list
      _favoriteItems.clear();

      // Update HomeViewModel using public method
      final homeViewModel = Provider.of<HomeViewModel>(
        currentContext,
        listen: false,
      );
      homeViewModel.clearFavoriteStateForItems(favoriteItemIds);

      if (currentContext.mounted) {
        _showSnackbar(currentContext, 'All favorites cleared', isError: false);
      }
    } catch (e) {
      print('Error clearing favorites: $e');
      if (currentContext.mounted) {
        _showSnackbar(currentContext, 'Failed to clear favorites');
      }
    } finally {
      notifyListeners();
    }
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
  // Add these methods to FavoritesViewModel class

  // Check if user is logged in (non-anonymous)
  bool get isUserLoggedIn {
    final currentUser = _auth.currentUser;
    return currentUser != null && !currentUser.isAnonymous;
  }

  // Refresh favorites - this should already exist but let's verify
  Future<void> refreshFavorites(BuildContext context) async {
    await loadUserFavorites(context);
  }

  // In FavoritesViewModel - Add the searchFavorites method
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
}
