import '../models/cart_item.dart';
import '../models/bouquet.dart';
import 'database_service.dart';

class CartService {
  final List<CartItem> _items = [];
  final DatabaseService _dbService = DatabaseService();
  String? _userId;

  CartService({String? userId}) {
    _userId = userId;
  }

  List<CartItem> get items => _items;

  // Set user ID (call after login)
  void setUserId(String userId) {
    _userId = userId;
  }

  // Load cart from database
  Future<void> loadCartFromDatabase() async {
    if (_userId == null) return;
    _items.clear();
    final savedItems = await _dbService.getCartItems(_userId!);
    _items.addAll(savedItems);
  }

  void addItem(Bouquet bouquet) {
    final existingItem = _items.firstWhere(
      (item) => item.bouquet.id == bouquet.id,
      orElse: () => CartItem(id: bouquet.id, bouquet: bouquet),
    );

    if (_items.contains(existingItem)) {
      existingItem.quantity++;
    } else {
      _items.add(existingItem);
    }

    // Save to database
    if (_userId != null) {
      _dbService.addToCart(_userId!, existingItem);
    }
  }

  void removeItem(String bouquetId) {
    final item = _items.firstWhere(
      (item) => item.bouquet.id == bouquetId,
      orElse: () => CartItem(
          id: bouquetId,
          bouquet: Bouquet(
            id: '',
            name: '',
            description: '',
            price: 0,
            city: '',
            images: [],
            category: '',
            rating: 0,
            reviews: 0,
            readyStock: 0,
          )),
    );
    _items.removeWhere((i) => i.bouquet.id == bouquetId);

    // Delete from database
    if (_userId != null) {
      _dbService.removeFromCart(item.id);
    }
  }

  void updateQuantity(String bouquetId, int quantity) {
    final item = _items.firstWhere(
      (item) => item.bouquet.id == bouquetId,
      orElse: () => throw Exception('Item not found'),
    );
    item.quantity = quantity;

    // Update in database
    if (_userId != null) {
      _dbService.updateCartItemQuantity(item.id, quantity);
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    if (_userId != null) {
      await _dbService.clearCart(_userId!);
    }
  }

  double getTotalPrice() {
    return _items.fold(0, (sum, item) => sum + item.total);
  }

  int getItemCount() {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }
}
