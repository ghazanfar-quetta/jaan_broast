import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesManagerService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _favoriteItemIds = [];

  List<String> get favoriteItemIds => _favoriteItemIds;

  // Load user favorites
  Future<void> loadUserFavorites() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .get();

      _favoriteItemIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading favorites in FavoritesManager: $e');
    }
  }

  // Add to favorites
  Future<void> addToFavorites(String itemId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .doc(itemId)
          .set({'addedAt': FieldValue.serverTimestamp()});

      if (!_favoriteItemIds.contains(itemId)) {
        _favoriteItemIds.add(itemId);
      }
      notifyListeners();
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String itemId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .doc(itemId)
          .delete();

      _favoriteItemIds.remove(itemId);
      notifyListeners();
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  // Clear all favorites
  Future<void> clearAllFavorites() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .get();

      final batch = _firestore.batch();
      for (final doc in favoritesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _favoriteItemIds.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing all favorites: $e');
      rethrow;
    }
  }

  // Check if item is favorite
  bool isFavorite(String itemId) {
    return _favoriteItemIds.contains(itemId);
  }
}
