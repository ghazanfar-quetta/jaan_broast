// lib/features/favorites/presentation/views/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/utils/screen_utils.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/food_item_card.dart';
import '../../../../../core/widgets/search_field.dart';
import '../view_models/favorites_view_model.dart';
import 'package:jaan_broast/features/home/domain/models/food_item.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  late FavoritesViewModel _viewModel;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel = Provider.of<FavoritesViewModel>(context, listen: false);
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    await _viewModel.loadUserFavorites();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: CustomAppBar(
        title: 'My Favorites',
        actions: [
          // Clear all favorites button
          Consumer<FavoritesViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.hasFavorites) {
                return IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: ScreenUtils.responsiveValue(
                      context,
                      mobile: 22,
                      tablet: 24,
                      desktop: 26,
                    ),
                  ),
                  onPressed: () => _showClearAllDialog(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<FavoritesViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return _buildLoadingState();
          }

          if (viewModel.error.isNotEmpty && !viewModel.hasData) {
            return _buildErrorState(viewModel);
          }

          if (!viewModel.isUserLoggedIn) {
            return _buildLoginRequiredState();
          }

          if (!viewModel.hasFavorites) {
            return _buildEmptyState();
          }

          return _buildFavoritesContent(viewModel);
        },
      ),
    );
  }

  Widget _buildFavoritesContent(FavoritesViewModel viewModel) {
    final filteredFavorites = _searchController.text.isEmpty
        ? viewModel.favoriteItems
        : viewModel.searchFavorites(_searchController.text);

    if (filteredFavorites.isEmpty && _searchController.text.isNotEmpty) {
      return _buildNoSearchResults();
    }

    return Column(
      children: [
        // Search and Stats Section
        Container(
          padding: ScreenUtils.responsivePadding(
            context,
            mobile: 16,
            tablet: 20,
            desktop: 24,
          ),
          color: Theme.of(context).colorScheme.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Field
              SearchField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {}); // Rebuild to show filtered results
                },
                onTap: () {
                  // Optional: You can add specific search screen navigation if needed
                  print('Search field tapped in favorites');
                },
                hintText: 'Search in favorites...',
              ),
              SizedBox(
                height: ScreenUtils.responsiveValue(
                  context,
                  mobile: 16,
                  tablet: 20,
                  desktop: 24,
                ),
              ),
              // Favorites Stats
              _buildFavoritesStats(viewModel, filteredFavorites.length),
            ],
          ),
        ),

        // Favorites Grid
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _viewModel.refreshFavorites(),
            color: Theme.of(context).primaryColor,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: ScreenUtils.responsiveValue(
                  context,
                  mobile: 80,
                  tablet: 80,
                  desktop: 80,
                ),
              ),
              child: _buildFavoritesGrid(filteredFavorites),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesStats(FavoritesViewModel viewModel, int filteredCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Favorites (${filteredCount}/${viewModel.favoritesCount})',
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
        ),
        if (_searchController.text.isEmpty && viewModel.hasFavorites)
          _buildClearAllButton(viewModel),
      ],
    );
  }

  Widget _buildClearAllButton(FavoritesViewModel viewModel) {
    return GestureDetector(
      onTap: () => _showClearAllDialog(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ScreenUtils.responsiveValue(
            context,
            mobile: 12,
            tablet: 14,
            desktop: 16,
          ),
          vertical: ScreenUtils.responsiveValue(
            context,
            mobile: 6,
            tablet: 8,
            desktop: 10,
          ),
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              size: ScreenUtils.responsiveValue(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(
              width: ScreenUtils.responsiveValue(
                context,
                mobile: 4,
                tablet: 6,
                desktop: 8,
              ),
            ),
            Text(
              'Clear All',
              style: TextStyle(
                fontSize: ScreenUtils.responsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesGrid(List<FoodItem> favorites) {
    return GridView.builder(
      padding: ScreenUtils.responsivePadding(
        context,
        mobile: 16,
        tablet: 20,
        desktop: 24,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ScreenUtils.responsiveValue(
          context,
          mobile: 2,
          tablet: 3,
          desktop: 4,
        ),
        crossAxisSpacing: ScreenUtils.responsiveValue(
          context,
          mobile: 16,
          tablet: 20,
          desktop: 24,
        ),
        mainAxisSpacing: ScreenUtils.responsiveValue(
          context,
          mobile: 16,
          tablet: 20,
          desktop: 24,
        ),
        childAspectRatio: ScreenUtils.responsiveValue(
          context,
          mobile: 0.7,
          tablet: 0.7,
          desktop: 0.7,
        ),
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final item = favorites[index];
        return FoodItemCard(
          name: item.name,
          portions: item.portions,
          imageUrl: item.imageUrl,
          isFavorite: true, // Always true since we're in favorites
          onTap: () {
            _openFoodDetails(item);
          },
          onToggleFavorite: () {
            _viewModel.removeFromFavorites(item.id, context);
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
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
            'Loading your favorites...',
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

  Widget _buildErrorState(FavoritesViewModel viewModel) {
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
              'Unable to load favorites',
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
              onPressed: () => _viewModel.refreshFavorites(),
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

  Widget _buildLoginRequiredState() {
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
              Icons.favorite_border,
              size: ScreenUtils.responsiveValue(
                context,
                mobile: 64,
                tablet: 72,
                desktop: 80,
              ),
              color: Theme.of(context).primaryColor.withOpacity(0.5),
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
              'Login to Save Favorites',
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
              'Sign in to save your favorite meals and access them across all your devices',
              style: TextStyle(
                fontSize: ScreenUtils.responsiveFontSize(
                  context,
                  mobile: AppConstants.bodyTextSize,
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
                mobile: 24,
                tablet: 28,
                desktop: 32,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/auth');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenUtils.responsiveValue(
                    context,
                    mobile: 32,
                    tablet: 36,
                    desktop: 40,
                  ),
                  vertical: ScreenUtils.responsiveValue(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                ),
              ),
              child: Text(
                'Sign In',
                style: TextStyle(
                  fontSize: ScreenUtils.responsiveFontSize(
                    context,
                    mobile: AppConstants.bodyTextSize,
                    tablet: AppConstants.bodyTextSize,
                    desktop: AppConstants.bodyTextSize + 2,
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

  Widget _buildEmptyState() {
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
              Icons.favorite_border,
              size: ScreenUtils.responsiveValue(
                context,
                mobile: 64,
                tablet: 72,
                desktop: 80,
              ),
              color: Theme.of(context).primaryColor.withOpacity(0.5),
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
              'No Favorites Yet',
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
            SizedBox(
              height: ScreenUtils.responsiveValue(
                context,
                mobile: 8,
                tablet: 12,
                desktop: 16,
              ),
            ),
            Text(
              'Start exploring our menu and tap the heart icon\n to save your favorite items here!',
              style: TextStyle(
                fontSize: ScreenUtils.responsiveFontSize(
                  context,
                  mobile: AppConstants.bodyTextSize,
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
                mobile: 24,
                tablet: 28,
                desktop: 32,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate back to home screen
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenUtils.responsiveValue(
                    context,
                    mobile: 32,
                    tablet: 36,
                    desktop: 40,
                  ),
                  vertical: ScreenUtils.responsiveValue(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                ),
              ),
              child: Text(
                'Explore Menu',
                style: TextStyle(
                  fontSize: ScreenUtils.responsiveFontSize(
                    context,
                    mobile: AppConstants.bodyTextSize,
                    tablet: AppConstants.bodyTextSize,
                    desktop: AppConstants.bodyTextSize + 2,
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

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: ScreenUtils.responsiveValue(
              context,
              mobile: 64,
              tablet: 72,
              desktop: 80,
            ),
            color: Theme.of(context).primaryColor.withOpacity(0.5),
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
            'No matching favorites',
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
            'Try searching with different keywords',
            style: TextStyle(
              fontSize: ScreenUtils.responsiveFontSize(
                context,
                mobile: AppConstants.bodyTextSize,
                tablet: AppConstants.bodyTextSize,
                desktop: AppConstants.bodyTextSize,
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

  void _openFoodDetails(FoodItem item) {
    // Navigate to food details screen
    print('Open food details for: ${item.name}');
    // You can implement navigation to food details screen here
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Clear All Favorites?',
            style: TextStyle(
              fontSize: ScreenUtils.responsiveFontSize(
                context,
                mobile: AppConstants.headingSizeMedium,
                tablet: AppConstants.headingSizeMedium,
                desktop: AppConstants.headingSizeMedium,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This will remove all items from your favorites list. This action cannot be undone.',
            style: TextStyle(
              fontSize: ScreenUtils.responsiveFontSize(
                context,
                mobile: AppConstants.bodyTextSize,
                tablet: AppConstants.bodyTextSize,
                desktop: AppConstants.bodyTextSize,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _viewModel.clearAllFavorites(context);
              },
              child: Text(
                'Clear All',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
