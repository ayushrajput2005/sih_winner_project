// import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fasalmitra/services/listing_service.dart';

class CartItem {
  final ListingData listing;
  int quantity;

  CartItem({required this.listing, this.quantity = 1});

  Map<String, dynamic> toJson() {
    return {
      'listingId': listing.id,
      'quantity': quantity,
      // We store minimal listing data to reconstruct it or fetch it.
      // For simplicity in this mock, we'll store the whole listing data we need.
      'listingTitle': listing.title,
      'listingPrice': listing.price,
      'listingImage': listing.imageUrls.isNotEmpty
          ? listing.imageUrls.first
          : '',
    };
  }
}

class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();

  // static const _cartKey = 'user_cart';
  // late SharedPreferences _prefs;
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + (item.listing.price * item.quantity));

  Future<void> init(SharedPreferences prefs) async {
    // _prefs = prefs;
    // In a real app, we'd load from prefs here.
    // For now, we'll start empty or load mock if needed.
  }

  void addToCart(ListingData listing) {
    final existingIndex = _items.indexWhere(
      (item) => item.listing.id == listing.id,
    );
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(listing: listing));
    }
    notifyListeners();
    // _saveCart();
  }

  void removeFromCart(String listingId) {
    _items.removeWhere((item) => item.listing.id == listingId);
    notifyListeners();
    // _saveCart();
  }

  void updateQuantity(String listingId, int quantity) {
    final index = _items.indexWhere((item) => item.listing.id == listingId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
      // _saveCart();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    // _saveCart();
  }
}
