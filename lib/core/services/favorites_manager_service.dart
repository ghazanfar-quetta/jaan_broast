// lib/core/services/favorites_manager_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_storage_service.dart';

class FavoritesManagerService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _favoriteItemIds = [];

  List<String> get favoriteItemIds => _favoriteItemIds;

  // Load user favorites with proper guest handling
  Future<void> loadUserFavorites() async {
    final currentUser = _auth.currentUser;

    // If user is not logged in (guest), clear all favorites
    if (currentUser == null || currentUser.isAnonymous) {
      _favoriteItemIds = [];
      await LocalStorageService.cacheFavorites([]);
      notifyListeners();
      return;
    }
    try {
      // Step 1: Try to load from local storage first
      final cachedFavorites = await LocalStorageService.getCachedFavorites();

      if (cachedFavorites.isNotEmpty) {
        // Use cached favorites and sync with Firestore
        _favoriteItemIds = cachedFavorites;
        notifyListeners();

        // Sync local with Firestore in background
        _syncLocalWithFirestore(cachedFavorites);
      } else {
        // Step 2: If no local data, load from Firestore
        final favoritesSnapshot = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('favorites')
            .get();

        _favoriteItemIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();

        // Cache the Firestore data locally
        await LocalStorageService.cacheFavorites(_favoriteItemIds);

        notifyListeners();
      }
    } catch (e) {
      print('Error loading favorites in FavoritesManager: $e');
      // If Firestore fails, try to use local cache as fallback
      final cachedFavorites = await LocalStorageService.getCachedFavorites();
      _favoriteItemIds = cachedFavorites;
      notifyListeners();
    }
  }

  // Add to favorites - sync both local and Firestore
  Future<void> addToFavorites(String itemId) async {
    final currentUser = _auth.currentUser;

    // If user is not logged in (guest), throw exception to show login prompt
    if (currentUser == null || currentUser.isAnonymous) {
      throw Exception('Please log in to add favorites');
    }

    try {
      // Add to Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .doc(itemId)
          .set({'addedAt': FieldValue.serverTimestamp()});

      // Add to local storage
      await LocalStorageService.addToCachedFavorites(itemId);

      // Update local state
      if (!_favoriteItemIds.contains(itemId)) {
        _favoriteItemIds.add(itemId);
      }
      notifyListeners();
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  // Remove from favorites - sync both local and Firestore
  Future<void> removeFromFavorites(String itemId) async {
    final currentUser = _auth.currentUser;

    // If user is not logged in (guest), throw exception
    if (currentUser == null || currentUser.isAnonymous) {
      throw Exception('Please log in to add favorites');
    }

    try {
      // Remove from Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .doc(itemId)
          .delete();

      // Remove from local storage
      await LocalStorageService.removeFromCachedFavorites(itemId);

      // Update local state
      _favoriteItemIds.remove(itemId);
      notifyListeners();
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  // Clear all favorites - sync both local and Firestore
  Future<void> clearAllFavorites() async {
    final currentUser = _auth.currentUser;

    // If user is not logged in (guest), throw exception
    if (currentUser == null || currentUser.isAnonymous) {
      throw Exception('Please log in to add favorites');
    }

    try {
      // Clear from Firestore
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

      // Clear from local storage
      await LocalStorageService.cacheFavorites([]);

      // Update local state
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

  // Private method to sync local storage with Firestore
  Future<void> _syncLocalWithFirestore(List<String> localFavorites) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Get current Firestore favorites
      final firestoreSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .get();

      final firestoreFavorites = firestoreSnapshot.docs
          .map((doc) => doc.id)
          .toList();

      // Find differences and sync
      final batch = _firestore.batch();
      final userFavoritesRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites');

      // Add missing items to Firestore
      for (final itemId in localFavorites) {
        if (!firestoreFavorites.contains(itemId)) {
          batch.set(userFavoritesRef.doc(itemId), {
            'addedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Remove extra items from Firestore (if any)
      for (final itemId in firestoreFavorites) {
        if (!localFavorites.contains(itemId)) {
          batch.delete(userFavoritesRef.doc(itemId));
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error syncing local with Firestore: $e');
      // If sync fails, we'll keep using local data
    }
  }
}
