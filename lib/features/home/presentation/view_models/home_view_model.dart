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
  Future<void> toggleFavorite(String itemId, BuildContext context) async {
    final favoritesManager = Provider.of<FavoritesManagerService>(
      context,
      listen: false,
    );
    final currentUser = FirebaseAuth.instance.currentUser;

    // Check if user is logged in FIRST - before any operations
    if (currentUser == null) {
      _showLoginPrompt(context);
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
        if (e.toString().contains('Please log in')) {
          _showLoginPrompt(context);
        } else {
          _showErrorSnackbar(context, 'Failed to update favorites');
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

      // Update favorite status for all items
      for (int i = 0; i < _allMenuItems.length; i++) {
        final item = _allMenuItems[i];
        final isFavorite = favoritesManager.isFavorite(item.id);
        if (item.isFavorite != isFavorite) {
          _allMenuItems[i] = item.copyWith(isFavorite: isFavorite);
        }
      }

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
}
