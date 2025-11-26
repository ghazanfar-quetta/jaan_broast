//lib/features/home/presentation/views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/utils/screen_utils.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/food_category_card.dart';
import '../../../../../core/widgets/food_item_card.dart';
import '../../../../../core/widgets/search_field.dart';
import '../view_models/home_view_model.dart';
// Add this import for FoodItem
import '../../domain/models/food_item.dart';
import 'package:jaan_broast/features/location/presentation/view_models/location_view_model.dart';
// Add Firebase imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import LocationSetupScreen
import 'package:jaan_broast/features/location/presentation/views/location_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  late HomeViewModel _viewModel;
  int _currentIndex = 0; // Track current bottom nav index
  bool _isInitialized = false;
  String _userAddress = 'Loading...'; // Default address

  // Scroll controller for categories
  final ScrollController _categoriesScrollController = ScrollController();

  // Bottom navigation items
  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.favorite_outline),
      activeIcon: Icon(Icons.favorite),
      label: 'Favorites',
    ),

    const BottomNavigationBarItem(
      icon: Icon(Icons.history_outlined),
      activeIcon: Icon(Icons.history),
      label: 'Order History',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel = Provider.of<HomeViewModel>(context, listen: false);
      _initializeData();
      _loadUserAddress(); // Load address from Firestore
      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload address when the screen becomes active again
    _loadUserAddress();
  }

  Future<void> _initializeData() async {
    await _viewModel.loadInitialData();
  }

  // New method to load user address from Firestore
  Future<void> _loadUserAddress() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _userAddress = 'Please log in';
        });
        return;
      }

      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get user document
      final userDoc = await firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final address = userData?['address']?['fullAddress'] as String?;

        if (address != null && address.isNotEmpty) {
          setState(() {
            _userAddress = address;
          });

          // Also update the LocationViewModel with the fetched address
          final locationViewModel = Provider.of<LocationViewModel>(
            context,
            listen: false,
          );
          locationViewModel.updateLocationManually(address);

          print('✅ Address loaded from Firebase: $address');
        } else {
          setState(() {
            _userAddress = 'Address not set';
          });
          print('ℹ️ No address found in Firebase');
        }
      } else {
        setState(() {
          _userAddress = 'User data not found';
        });
        print('❌ User document not found in Firebase');
      }
    } catch (e) {
      print('❌ Error loading user address: $e');
      setState(() {
        _userAddress = 'Error loading address';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: CustomAppBar(
        title: AppConstants.appName,
        actions: [
          IconButton(
            icon: Icon(
              Icons.shopping_cart,
              size: ScreenUtils.responsiveValue(
                context,
                mobile: 22,
                tablet: 24,
                desktop: 26,
              ),
            ),
            onPressed: _viewCart,
          ),
          IconButton(
            icon: Icon(
              Icons.person,
              size: ScreenUtils.responsiveValue(
                context,
                mobile: 22,
                tablet: 24,
                desktop: 26,
              ),
            ),
            onPressed: _viewProfile,
          ),
        ],
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCurrentScreen() {
    // For now, we'll only implement the Home screen content
    // Other screens will show placeholders
    if (_currentIndex == 0) {
      return _buildHomeContent();
    } else {
      return _buildPlaceholderScreen();
    }
  }

  Widget _buildHomeContent() {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return _buildLoadingState();
        }

        if (viewModel.error.isNotEmpty) {
          return _buildErrorState(viewModel);
        }

        return _buildContent(viewModel);
      },
    );
  }

  Widget _buildPlaceholderScreen() {
    final List<String> screenTitles = [
      'Favorites',
      'Order History',
      'Settings',
    ];

    // Get the correct icon data for the current tab
    final IconData iconData;
    switch (_currentIndex) {
      case 1:
        iconData = Icons.favorite_outline;
        break;
      case 2:
        iconData = Icons.replay_outlined;
        break;
      case 3:
        iconData = Icons.history_outlined;
        break;
      case 4:
        iconData = Icons.settings_outlined;
        break;
      default:
        iconData = Icons.home_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 64,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '${screenTitles[_currentIndex - 1]} Screen',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _bottomNavItems,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6),
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(
            height: ScreenUtils.responsiveValue(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),
          Text(
            'Loading delicious food...',
            style: TextStyle(
              fontSize: ScreenUtils.responsiveFontSize(
                context,
                mobile: AppConstants.bodyTextSize,
                tablet: AppConstants.bodyTextSize,
                desktop: AppConstants.bodyTextSize + 2,
              ),
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(HomeViewModel viewModel) {
    return Center(
      child: Padding(
        padding: ScreenUtils.responsivePadding(
          context,
          mobile: 20,
          tablet: 30,
          desktop: 40,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ScreenUtils.responsiveValue(
                context,
                mobile: 48,
                tablet: 56,
                desktop: 64,
              ),
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(
              height: ScreenUtils.responsiveValue(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24,
              ),
            ),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: ScreenUtils.responsiveFontSize(
                  context,
                  mobile: AppConstants.headingSizeSmall,
                  tablet: AppConstants.headingSizeMedium,
                  desktop: AppConstants.headingSizeMedium,
                ),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: ScreenUtils.responsiveValue(
                context,
                mobile: 8,
                tablet: 12,
                desktop: 16,
              ),
            ),
            Text(
              viewModel.error,
              style: TextStyle(
                fontSize: ScreenUtils.responsiveFontSize(
                  context,
                  mobile: AppConstants.captionTextSize,
                  tablet: AppConstants.bodyTextSize,
                  desktop: AppConstants.bodyTextSize,
                ),
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: ScreenUtils.responsiveValue(
                context,
                mobile: 20,
                tablet: 24,
                desktop: 28,
              ),
            ),
            ElevatedButton(
              onPressed: _viewModel.refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenUtils.responsiveValue(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                  vertical: ScreenUtils.responsiveValue(
                    context,
                    mobile: 12,
                    tablet: 14,
                    desktop: 16,
                  ),
                ),
              ),
              child: Text(
                'Try Again',
                style: TextStyle(
                  fontSize: ScreenUtils.responsiveFontSize(
                    context,
                    mobile: AppConstants.bodyTextSize,
                    tablet: AppConstants.bodyTextSize,
                    desktop: AppConstants.bodyTextSize,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(HomeViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: _viewModel.refreshData,
      color: Theme.of(context).primaryColor,
      child: Column(
        children: [
          // Location and Search Section - Fixed at top
          Container(
            color: Theme.of(context).colorScheme.background,
            padding: ScreenUtils.responsivePadding(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Header
                _buildLocationHeader(),
                SizedBox(
                  height: ScreenUtils.responsiveValue(
                    context,
                    mobile: 20,
                    tablet: 24,
                    desktop: 28,
                  ),
                ),

                // Search Field
                SearchField(
                  controller: _searchController,
                  onChanged: (value) {
                    _viewModel.searchFoodItems(value);
                  },
                  onTap: _openSearchScreen,
                ),
                SizedBox(
                  height: ScreenUtils.responsiveValue(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                ),

                // Categories Section
                _buildCategoriesSection(viewModel),
              ],
            ),
          ),

          // Menu Items Section - Scrollable
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: ScreenUtils.responsivePadding(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24,
              ),
              child: _buildMenuItemsSection(viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(HomeViewModel viewModel) {
    if (viewModel.categories.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and clear button when category is selected
        if (viewModel.isCategorySelected)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${viewModel.getCategoryName(viewModel.selectedCategoryId)} (${viewModel.getItemsCountForCategory(viewModel.selectedCategoryId)})',
                    style: TextStyle(
                      fontSize: ScreenUtils.responsiveFontSize(
                        context,
                        mobile: AppConstants.headingSizeMedium,
                        tablet: AppConstants.headingSizeMedium,
                        desktop: AppConstants.headingSizeLarge,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _clearSearch();
                    _viewModel.clearCategorySelection();
                  },
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: ScreenUtils.responsiveFontSize(
                        context,
                        mobile: AppConstants.captionTextSize,
                        tablet: AppConstants.bodyTextSize,
                        desktop: AppConstants.bodyTextSize,
                      ),
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Categories Title (only when no category is selected)
        if (!viewModel.isCategorySelected)
          Text(
            'Categories',
            style: TextStyle(
              fontSize: ScreenUtils.responsiveFontSize(
                context,
                mobile: AppConstants.headingSizeMedium,
                tablet: AppConstants.headingSizeMedium,
                desktop: AppConstants.headingSizeLarge,
              ),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),

        if (!viewModel.isCategorySelected)
          SizedBox(
            height: ScreenUtils.responsiveValue(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),

        // Categories List
        SizedBox(
          height: ScreenUtils.responsiveValue(
            context,
            mobile: 100, // Same height as before
            tablet: 110,
            desktop: 120,
          ),
          child: ListView.builder(
            controller: _categoriesScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.categories.length,
            itemBuilder: (context, index) {
              final category = viewModel.categories[index];
              return FoodCategoryCard(
                name: category.name,
                imageUrl: category.imageUrl,
                isSelected: viewModel.selectedCategoryId == category.id,
                onTap: () {
                  _clearSearch();
                  if (viewModel.selectedCategoryId == category.id) {
                    // If same category clicked, show all items
                    _viewModel.clearCategorySelection();
                  } else {
                    // Select category and show only those items
                    _viewModel.selectCategory(category.id);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationHeader() {
    return Consumer<LocationViewModel>(
      builder: (context, locationViewModel, child) {
        return Row(
          children: [
            Icon(
              Icons.location_on,
              size: ScreenUtils.responsiveValue(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(
              width: ScreenUtils.responsiveValue(
                context,
                mobile: 6,
                tablet: 8,
                desktop: 10,
              ),
            ),
            Expanded(
              child: Text(
                _userAddress, // Use the address from Firestore
                style: TextStyle(
                  fontSize: ScreenUtils.responsiveFontSize(
                    context,
                    mobile: AppConstants.bodyTextSize,
                    tablet: AppConstants.bodyTextSize,
                    desktop: AppConstants.bodyTextSize + 2,
                  ),
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: _changeLocation,
              child: Text(
                'Change',
                style: TextStyle(
                  fontSize: ScreenUtils.responsiveFontSize(
                    context,
                    mobile: AppConstants.captionTextSize,
                    tablet: AppConstants.bodyTextSize,
                    desktop: AppConstants.bodyTextSize,
                  ),
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItemsSection(HomeViewModel viewModel) {
    final menuItems = viewModel.getFilteredMenuItems();

    if (menuItems.isEmpty) {
      return Center(
        child: Padding(
          padding: ScreenUtils.responsivePadding(
            context,
            mobile: 40,
            tablet: 60,
            desktop: 80,
          ),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: ScreenUtils.responsiveValue(
                  context,
                  mobile: 48,
                  tablet: 56,
                  desktop: 64,
                ),
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.5),
              ),
              SizedBox(
                height: ScreenUtils.responsiveValue(
                  context,
                  mobile: 12,
                  tablet: 16,
                  desktop: 20,
                ),
              ),
              Text(
                _searchController.text.isEmpty
                    ? 'No items found in this category'
                    : 'No items found for "${_searchController.text}"',
                style: TextStyle(
                  fontSize: ScreenUtils.responsiveFontSize(
                    context,
                    mobile: AppConstants.bodyTextSize,
                    tablet: AppConstants.bodyTextSize,
                    desktop: AppConstants.bodyTextSize + 2,
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!viewModel.isCategorySelected)
          Text(
            'Menu Items',
            style: TextStyle(
              fontSize: ScreenUtils.responsiveFontSize(
                context,
                mobile: AppConstants.headingSizeMedium,
                tablet: AppConstants.headingSizeMedium,
                desktop: AppConstants.headingSizeLarge,
              ),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        if (!viewModel.isCategorySelected)
          SizedBox(
            height: ScreenUtils.responsiveValue(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ScreenUtils.responsiveValue(
              context,
              mobile: 2,
              tablet: 3,
              desktop: 4,
            ),
            crossAxisSpacing: ScreenUtils.responsiveValue(
              context,
              mobile: 1,
              tablet: 2,
              desktop: 3,
            ),
            mainAxisSpacing: ScreenUtils.responsiveValue(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
            childAspectRatio: ScreenUtils.responsiveValue(
              context,
              mobile: 0.7, // More vertical space for text
              tablet: 0.7,
              desktop: 0.7,
            ),
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return FoodItemCard(
              name: item.name,
              portions: item.portions,
              imageUrl: item.imageUrl,
              isFavorite: item.isFavorite,
              onTap: () {
                _viewModel.showFoodItemDetails(item);
                _openFoodDetails(item);
              },
              onToggleFavorite: () {
                _viewModel.toggleFavorite(item.id);
              },
            );
          },
        ),
      ],
    );
  }

  // Add this method to clear search
  void _clearSearch() {
    _searchController.clear();
    _viewModel.clearSearch();
  }

  // Navigation and Action Methods
  void _openSearchScreen() {
    // Navigate to dedicated search screen
    print('Open search screen');
  }

  void _openFoodDetails(FoodItem item) {
    // Navigate to food details screen
    print('Open food details for: ${item.name}');
  }

  void _viewCart() {
    // Navigate to cart screen
    print('Open cart screen');
  }

  void _viewProfile() {
    // Navigate to profile screen
    print('Open profile screen');
  }

  void _changeLocation() {
    // Navigate to LocationSetupScreen for address change with contact details preserved
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSetupScreen(
          isAutoLocation: false, // User can choose manual or auto
          preserveContactDetails: true, // Add this parameter
        ),
      ),
    ).then((_) {
      // Reload address when returning from LocationSetupScreen
      _loadUserAddress();
    });
  }

  void _showAddToCartMessage(FoodItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart!'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(label: 'View Cart', onPressed: _viewCart),
      ),
    );
  }

  @override
  void dispose() {
    _categoriesScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
