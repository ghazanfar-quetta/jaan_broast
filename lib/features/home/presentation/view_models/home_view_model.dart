import 'package:flutter/material.dart';
import '../../domain/models/food_category.dart';
import '../../domain/models/food_item.dart';

class HomeViewModel with ChangeNotifier {
  List<FoodCategory> _categories = [];
  List<FoodItem> _menuItems = [];
  List<FoodItem> _allMenuItems = []; // Keep original list for filtering
  String _selectedCategoryId = '';
  String _searchQuery = '';
  bool _isLoading = false;
  String _error = '';

  List<FoodCategory> get categories => _categories;
  List<FoodItem> get menuItems => _menuItems;
  String get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  String get error => _error;

  void clearSearch() {
    _searchQuery = '';
    _applyFilters(); // Reapply filters to show all items
    notifyListeners();
  }

  // Load initial data
  Future<void> loadInitialData() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Load mock categories
      _loadCategories();

      // Load mock menu items
      _loadMenuItems();

      // Select first category by default
      if (_categories.isNotEmpty) {
        _selectedCategoryId = _categories.first.id;
      }

      _error = '';
    } catch (e) {
      _error = 'Failed to load data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load categories
  void _loadCategories() {
    _categories = [
      FoodCategory(
        id: '1',
        name: 'Birvani',
        description: 'Various types of biryanis',
        imageUrl: '',
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

  // Load menu items
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
    // This will be handled by navigation in the UI
    print('Showing details for: ${item.name}');
  }

  void addToCart(FoodItem item, {int portionIndex = 0}) {
    final selectedPortion = item.portions[portionIndex];

    // Show success message (this will be handled by the UI)
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
