import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jaan_broast/features/home/domain/models/food_item_details.dart';
import '../../../../core/services/firestore_food_service.dart';

class ItemDetailsViewModel extends ChangeNotifier {
  FoodItemDetails? _selectedItem;
  bool _isLoading = false;
  String? _error;
  String? _selectedPortion;
  final Map<String, bool> _selectedAddOns = {};
  int _quantity = 1;

  ItemDetailsViewModel();

  // Getters
  FoodItemDetails? get selectedItem => _selectedItem;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedPortion => _selectedPortion;
  Map<String, bool> get selectedAddOns => Map.from(_selectedAddOns);
  int get quantity => _quantity;

  // Load food item details from Firebase
  Future<void> loadFoodItemDetails(String itemId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetch item details from Firebase
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('foodItems') // Changed from 'foodItems' to 'food_items'
          .doc(itemId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        _selectedItem = FoodItemDetails.fromFirestore(data);

        // Set default portion
        if (_selectedItem!.portions.isNotEmpty) {
          _selectedPortion = _selectedItem!.portions.first.size;
        }

        // Initialize add-ons selection
        for (var addOn in _selectedItem!.availableAddOns) {
          _selectedAddOns[addOn] = false;
        }
      } else {
        _error = 'Food item not found';
      }
    } catch (e) {
      _error = 'Failed to load item details: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set selected portion
  void selectPortion(String portion) {
    _selectedPortion = portion;
    notifyListeners();
  }

  // Toggle add-on selection
  void toggleAddOn(String addOn) {
    if (_selectedAddOns.containsKey(addOn)) {
      _selectedAddOns[addOn] = !(_selectedAddOns[addOn] ?? false);
      notifyListeners();
    }
  }

  // Update quantity
  void increaseQuantity() {
    _quantity++;
    notifyListeners();
  }

  void decreaseQuantity() {
    if (_quantity > 1) {
      _quantity--;
      notifyListeners();
    }
  }

  // Calculate total price
  double calculateTotalPrice() {
    if (_selectedItem == null || _selectedPortion == null) return 0.0;

    double total = 0.0;

    // Get portion price
    final portion = _selectedItem!.portions.firstWhere(
      (p) => p.size == _selectedPortion,
      orElse: () => _selectedItem!.portions.first,
    );
    total += portion.price;

    // Add add-ons prices
    for (var entry in _selectedAddOns.entries) {
      if (entry.value) {
        total += _selectedItem!.getAddOnPrice(entry.key);
      }
    }

    // Multiply by quantity
    total *= _quantity;

    return total;
  }

  // Get portion price
  double getPortionPrice(String? portion) {
    if (_selectedItem == null || portion == null) return 0.0;

    final foundPortion = _selectedItem!.portions.firstWhere(
      (p) => p.size == portion,
      orElse: () => _selectedItem!.portions.first,
    );
    return foundPortion.price;
  }

  // Reset state
  void reset() {
    _selectedItem = null;
    _selectedPortion = null;
    _selectedAddOns.clear();
    _quantity = 1;
    _error = null;
    _isLoading = false;
  }
}
