// lib/features/home/presentation/view_models/home_view_model.dart
import 'package:flutter/material.dart';
import '../../domain/models/food_category.dart';
import '../../domain/models/food_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeViewModel with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<FoodCategory> _categories = [];
  List<FoodItem> _menuItems = [];
  List<FoodItem> _allMenuItems = [];
  String _selectedCategoryId = '';
  String _searchQuery = '';
  bool _isLoading = false;
  String _error = '';
  List<String> _favoriteItemIds = [];

  // Getters
  List<FoodCategory> get categories => _categories;
  List<FoodItem> get menuItems => _menuItems;
  List<String> get favoriteItemIds => _favoriteItemIds;
  String get selectedCategoryId => _selectedCategoryId; // Make sure this exists
  bool get isLoading => _isLoading;
  String get error => _error;

  // Toggle favorite status
  void toggleFavorite(String itemId) {
    final itemIndex = _allMenuItems.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      final isCurrentlyFavorite = _favoriteItemIds.contains(itemId);

      if (isCurrentlyFavorite) {
        _favoriteItemIds.remove(itemId);
      } else {
        _favoriteItemIds.add(itemId);
      }

      // Update the item's favorite status
      _allMenuItems[itemIndex] = _allMenuItems[itemIndex].copyWith(
        isFavorite: !isCurrentlyFavorite,
      );

      // Update filtered menu items
      _applyFilters();

      notifyListeners();

      print(
        '${isCurrentlyFavorite ? 'Removed from' : 'Added to'} favorites: ${_allMenuItems[itemIndex].name}',
      );
    }
  }

  // Check if item is favorite
  bool isFavorite(String itemId) {
    return _favoriteItemIds.contains(itemId);
  }

  // Get favorite items
  List<FoodItem> getFavoriteItems() {
    return _allMenuItems
        .where((item) => _favoriteItemIds.contains(item.id))
        .toList();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  // Load initial data
  Future<void> loadInitialData() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Load categories from Firebase
      await _loadCategoriesFromFirebase();

      // Load food items from Firebase
      await _loadFoodItemsFromFirebase();

      // Select first category by default
      if (_categories.isNotEmpty) {
        _selectedCategoryId = _categories.first.id;
      }

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

  // In your HomeViewModel, update the _loadCategories method:
  void _loadCategories() {
    _categories = [
      FoodCategory(
        id: '1',
        name: 'Birvani',
        description: 'Various types of biryanis',
        imageUrl: '', // You can add image URLs later
        displayOrder: 1,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FoodCategory(
        id: '2',
        name: 'Burgers',
        description: 'Delicious burgers',
        imageUrl: '',
        displayOrder: 2,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FoodCategory(
        id: '3',
        name: 'Broast',
        description: 'Crispy broast chicken',
        imageUrl: '',
        displayOrder: 3,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FoodCategory(
        id: '4',
        name: 'Bar B.Q',
        description: 'Barbecue items',
        imageUrl: '',
        displayOrder: 4,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FoodCategory(
        id: '5',
        name: 'Chinese',
        description: 'Chinese cuisine',
        imageUrl: '',
        displayOrder: 5,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  void _loadMenuItems() {
    _allMenuItems = [
      FoodItem(
        id: '1',
        name: 'Chicken Biryani',
        description:
            'Delicious chicken biryani with aromatic spices and basmati rice',
        portions: [
          FoodPortion(size: 'Single', price: 380.00, serves: 1),
          FoodPortion(size: 'Double', price: 650.00, serves: 2),
        ],
        imageUrl: '',
        category: '1',
        tags: ['spicy', 'rice', 'chicken'],
        isAvailable: true,
        isFeatured: true,
        rating: 4.5,
        ratingCount: 120,
        preparationTime: 25,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
      ),
      FoodItem(
        id: '2',
        name: 'Beef Pulao',
        description: 'Traditional beef pulao with tender beef and rice',
        portions: [
          FoodPortion(size: 'Single', price: 380.00, serves: 1),
          FoodPortion(size: 'Double', price: 700.00, serves: 2),
        ],
        imageUrl: '',
        category: '1',
        tags: ['rice', 'beef', 'traditional'],
        isAvailable: true,
        isFeatured: false,
        rating: 4.3,
        ratingCount: 85,
        preparationTime: 30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
      ),
      FoodItem(
        id: '3',
        name: 'Chicken Pulao',
        description: 'Flavorful chicken pulao with herbs and spices',
        portions: [FoodPortion(size: 'Single', price: 380.00, serves: 1)],
        imageUrl: '',
        category: '1',
        tags: ['rice', 'chicken', 'herbs'],
        isAvailable: true,
        isFeatured: false,
        rating: 4.2,
        ratingCount: 75,
        preparationTime: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
      ),
      FoodItem(
        id: '4',
        name: 'Jaan Load Box Biryani',
        description: 'Special loaded biryani box with extra portions',
        portions: [FoodPortion(size: 'Family', price: 1650.00, serves: 4)],
        imageUrl: '',
        category: '1',
        tags: ['special', 'loaded', 'family'],
        isAvailable: true,
        isFeatured: true,
        rating: 4.8,
        ratingCount: 45,
        preparationTime: 35,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
      ),
    ];

    _menuItems = _allMenuItems;
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
  Future<void> refreshData() async {
    await loadInitialData();
  }
}
