// lib/features/home/presentation/view_models/home_view_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../domain/models/food_category.dart';
import '../../domain/models/food_item.dart';
import 'package:jaan_broast/core/services/favorites_manager_service.dart';

class HomeViewModel with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<FoodCategory> _categories = [];
  List<FoodItem> _menuItems = [];
  List<FoodItem> _allMenuItems = [];
  String _selectedCategoryId = '';
  String _searchQuery = '';
  bool _isLoading = false;
  String _error = '';
  int _activeCategoryIndex = 0;

  // Getters
  List<FoodCategory> get categories => _categories;
  List<FoodItem> get menuItems => _menuItems;
  String get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isCategorySelected => _selectedCategoryId.isNotEmpty;
  int get activeCategoryIndex => _activeCategoryIndex;

  // Get category name by ID
  String getCategoryName(String categoryId) {
    final category = _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => FoodCategory(
        id: '',
        name: 'All Categories',
        description: '',
        imageUrl: '',
        displayOrder: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return category.name;
  }

  // Get items count for a category
  int getItemsCountForCategory(String categoryId) {
    return _allMenuItems
        .where((item) => item.category == categoryId && item.isAvailable)
        .length;
  }

  // Clear category selection
  void clearCategorySelection() {
    _selectedCategoryId = '';
    _applyFilters();
    notifyListeners();
  }

  // Toggle favorite status using shared service
  // In HomeViewModel - Update the toggleFavorite method
  // In HomeViewModel - Fix toggleFavorite context warning
  Future<void> toggleFavorite(String itemId, BuildContext context) async {
    final currentContext = context; // Store context locally
    final favoritesManager = Provider.of<FavoritesManagerService>(
      currentContext,
      listen: false,
    );
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || currentUser.isAnonymous) {
      if (currentContext.mounted) {
        _showLoginPrompt(currentContext);
      }
      return;
    }

    final itemIndex = _allMenuItems.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      final isCurrentlyFavorite = favoritesManager.isFavorite(itemId);
      final foodItem = _allMenuItems[itemIndex];

      try {
        if (isCurrentlyFavorite) {
          await favoritesManager.removeFromFavorites(itemId);
        } else {
          await favoritesManager.addToFavorites(itemId);
        }

        // Update local state
        _allMenuItems[itemIndex] = foodItem.copyWith(
          isFavorite: !isCurrentlyFavorite,
        );

        // Update filtered items
        final filteredIndex = _menuItems.indexWhere(
          (item) => item.id == itemId,
        );
        if (filteredIndex != -1) {
          _menuItems[filteredIndex] = _menuItems[filteredIndex].copyWith(
            isFavorite: !isCurrentlyFavorite,
          );
        }

        print(
          '${isCurrentlyFavorite ? 'Removed from' : 'Added to'} favorites: ${foodItem.name}',
        );
      } catch (e) {
        print('Error toggling favorite: $e');
        if (currentContext.mounted) {
          if (e.toString().contains('Please log in')) {
            _showLoginPrompt(currentContext);
          } else {
            _showErrorSnackbar(currentContext, 'Failed to update favorites');
          }
        }
      } finally {
        notifyListeners();
      }
    }
  }

  // Check if item is favorite using shared service
  bool isFavorite(String itemId, BuildContext context) {
    final favoritesManager = Provider.of<FavoritesManagerService>(
      context,
      listen: false,
    );
    return favoritesManager.isFavorite(itemId);
  }

  // Get favorite items
  List<FoodItem> getFavoriteItems() {
    return _allMenuItems.where((item) => item.isFavorite).toList();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  // Load initial data
  Future<void> loadInitialData(BuildContext context) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Load categories from Firebase
      await _loadCategoriesFromFirebase();

      // Load food items from Firebase
      await _loadFoodItemsFromFirebase();

      // Load favorites through the shared service
      final favoritesManager = Provider.of<FavoritesManagerService>(
        context,
        listen: false,
      );
      await favoritesManager.loadUserFavorites();
      _syncFavoritesWithManager(favoritesManager);

      _applyFilters();
      _error = '';
    } catch (e) {
      _error = 'Failed to load data: $e';
      print('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _syncFavoritesWithManager(FavoritesManagerService favoritesManager) {
    for (int i = 0; i < _allMenuItems.length; i++) {
      final item = _allMenuItems[i];
      final isFavorite = favoritesManager.isFavorite(item.id);
      if (item.isFavorite != isFavorite) {
        _allMenuItems[i] = item.copyWith(isFavorite: isFavorite);
      }
    }

    for (int i = 0; i < _menuItems.length; i++) {
      final item = _menuItems[i];
      final isFavorite = favoritesManager.isFavorite(item.id);
      if (item.isFavorite != isFavorite) {
        _menuItems[i] = item.copyWith(isFavorite: isFavorite);
      }
    }
  }

  Future<void> _loadCategoriesFromFirebase() async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder')
          .get();

      _categories = querySnapshot.docs.map((doc) {
        return FoodCategory.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Error loading categories: $e');
      throw e;
    }
  }

  Future<void> _loadFoodItemsFromFirebase() async {
    try {
      final querySnapshot = await _firestore
          .collection('foodItems')
          .where('isAvailable', isEqualTo: true)
          .get();

      _allMenuItems = querySnapshot.docs.map((doc) {
        return FoodItem.fromMap({'id': doc.id, ...doc.data()});
      }).toList();

      _menuItems = _allMenuItems;
    } catch (e) {
      print('Error loading food items: $e');
      throw e;
    }
  }

  // Category selection
  void selectCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
    notifyListeners();
  }

  // Search functionality
  void searchFoodItems(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  // Apply both category and search filters
  void _applyFilters() {
    List<FoodItem> filteredItems = _allMenuItems;

    // Filter by category
    if (_selectedCategoryId.isNotEmpty) {
      filteredItems = filteredItems
          .where((item) => item.category == _selectedCategoryId)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredItems = filteredItems
          .where(
            (item) =>
                item.name.toLowerCase().contains(_searchQuery) ||
                item.description.toLowerCase().contains(_searchQuery) ||
                item.tags.any(
                  (tag) => tag.toLowerCase().contains(_searchQuery),
                ),
          )
          .toList();
    }

    _menuItems = filteredItems;
  }

  // Get filtered menu items
  List<FoodItem> getFilteredMenuItems() {
    return _menuItems;
  }

  // Get popular/featured items
  List<FoodItem> getPopularItems() {
    return _allMenuItems
        .where((item) => item.isFeatured && item.isAvailable)
        .toList();
  }

  // Get items by category
  List<FoodItem> getItemsByCategory(String categoryId) {
    return _allMenuItems
        .where((item) => item.category == categoryId && item.isAvailable)
        .toList();
  }

  // Food item actions
  void showFoodItemDetails(FoodItem item) {
    print('Showing details for: ${item.name}');
  }

  void addToCart(FoodItem item, {int portionIndex = 0}) {
    final selectedPortion = item.portions[portionIndex];
    print(
      'Added to cart: ${item.name} - ${selectedPortion.size} - ${selectedPortion.formattedPrice}',
    );
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Refresh data
  Future<void> refreshData(BuildContext context) async {
    await loadInitialData(context);
  }

  void setActiveCategoryIndex(int index) {
    _activeCategoryIndex = index;
    notifyListeners();
  }

  // Get category by index
  FoodCategory? getCategoryByIndex(int index) {
    if (index >= 0 && index < _categories.length) {
      return _categories[index];
    }
    return null;
  }

  // Clear all filters
  void clearAllFilters() {
    _selectedCategoryId = '';
    _searchQuery = '';
    _activeCategoryIndex = 0;
    _applyFilters();
    notifyListeners();
  }

  // Helper methods for snackbars
  void _showLoginPrompt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please log in to add favorites'),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Login',
          onPressed: () {
            Navigator.pushNamed(context, '/auth');
          },
        ),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  // Add this method to HomeViewModel
  // In HomeViewModel - Update clearAllFavoriteStates with debug prints
  void clearAllFavoriteStates() {
    print('clearAllFavoriteStates called');
    print(
      'Before: ${_allMenuItems.where((item) => item.isFavorite).length} favorite items in _allMenuItems',
    );
    print(
      'Before: ${_menuItems.where((item) => item.isFavorite).length} favorite items in _menuItems',
    );

    // Update all menu items
    for (int i = 0; i < _allMenuItems.length; i++) {
      final item = _allMenuItems[i];
      if (item.isFavorite) {
        _allMenuItems[i] = item.copyWith(isFavorite: false);
      }
    }

    // Update filtered menu items
    for (int i = 0; i < _menuItems.length; i++) {
      final item = _menuItems[i];
      if (item.isFavorite) {
        _menuItems[i] = item.copyWith(isFavorite: false);
      }
    }

    print(
      'After: ${_allMenuItems.where((item) => item.isFavorite).length} favorite items in _allMenuItems',
    );
    print(
      'After: ${_menuItems.where((item) => item.isFavorite).length} favorite items in _menuItems',
    );

    notifyListeners();
    print('Notified listeners');
  }
  // In HomeViewModel - Add these public methods

  // Method to clear favorite state for specific items
  // In HomeViewModel - Add this NEW method for multiple items
  void clearFavoriteStateForItems(List<String> itemIds) {
    print(
      'clearFavoriteStateForItems called with ${itemIds.length} items: $itemIds',
    );
    int updatedAllItems = 0;
    int updatedMenuItems = 0;

    // Update all menu items
    for (int i = 0; i < _allMenuItems.length; i++) {
      if (itemIds.contains(_allMenuItems[i].id) &&
          _allMenuItems[i].isFavorite) {
        _allMenuItems[i] = _allMenuItems[i].copyWith(isFavorite: false);
        updatedAllItems++;
      }
    }

    // Update filtered menu items
    for (int i = 0; i < _menuItems.length; i++) {
      if (itemIds.contains(_menuItems[i].id) && _menuItems[i].isFavorite) {
        _menuItems[i] = _menuItems[i].copyWith(isFavorite: false);
        updatedMenuItems++;
      }
    }

    print('Updated $updatedAllItems items in _allMenuItems');
    print('Updated $updatedMenuItems items in _menuItems');
    notifyListeners();
    print('Notified listeners in clearFavoriteStateForItems');
  }

  // Method to clear favorite state for a single item
  void clearFavoriteStateForItem(String itemId) {
    // Update all menu items
    for (int i = 0; i < _allMenuItems.length; i++) {
      if (_allMenuItems[i].id == itemId) {
        _allMenuItems[i] = _allMenuItems[i].copyWith(isFavorite: false);
        break;
      }
    }

    // Update filtered menu items
    for (int i = 0; i < _menuItems.length; i++) {
      if (_menuItems[i].id == itemId) {
        _menuItems[i] = _menuItems[i].copyWith(isFavorite: false);
        break;
      }
    }
    notifyListeners();
  }

  // Method to sync all favorite states with FavoritesManagerService
  void syncAllFavoriteStates(FavoritesManagerService favoritesManager) {
    for (int i = 0; i < _allMenuItems.length; i++) {
      final item = _allMenuItems[i];
      final isFavorite = favoritesManager.isFavorite(item.id);
      if (item.isFavorite != isFavorite) {
        _allMenuItems[i] = item.copyWith(isFavorite: isFavorite);
      }
    }

    for (int i = 0; i < _menuItems.length; i++) {
      final item = _menuItems[i];
      final isFavorite = favoritesManager.isFavorite(item.id);
      if (item.isFavorite != isFavorite) {
        _menuItems[i] = item.copyWith(isFavorite: isFavorite);
      }
    }
    notifyListeners();
  }
}
