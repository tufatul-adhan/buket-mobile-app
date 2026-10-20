// Extension & Guide untuk memudahkan penggunaan ApiService di screen

extension AuthServiceExtension on AuthServiceX {
  // TODO: Update AuthService untuk use ApiService
  // Contoh:
  
  // Future<bool> registerWithBackend(String email, String username, String password, String phone, String city) async {
  //   final result = await ApiService.register(
  //     email: email,
  //     username: username,
  //     password: password,
  //     phone: phone,
  //     city: city,
  //   );
  //   return result['success'];
  // }
}

class AuthServiceX {
  // Placeholder untuk extension
}

/// INTEGRASI CHECKLIST - Update sesuai urutan ini:
/// 
/// 1. ✅ Database setup - DONE
///    - Run migrations/schema.sql di XAMPP
/// 
/// 2. ✅ Backend Go - DONE
///    - go run main.go
///    - Test dengan Postman
/// 
/// 3. 🔄 Flutter Integration - IN PROGRESS
///    
///    a) Update LoginScreen:
///       - Replace hardcoded auth dengan ApiService.login()
///       - Save token di SharedPreferences
///       - Handle login errors
/// 
///    b) Update HomeScreen:
///       - Replace hardcoded products dengan ApiService.getAllProducts()
///       - Add city/category filter
///       - Handle loading state
/// 
///    c) Update ProductDetailScreen:
///       - Replace hardcoded product detail dengan ApiService.getProductDetail()
///       - Update "Add to Cart" untuk call ApiService.addToCart()
/// 
///    d) Update CartScreen:
///       - Load cart dari ApiService.getCart()
///       - Add/remove items via ApiService
///       - Create order dengan ApiService.createOrder()
/// 
///    e) Add OrderScreen (NEW):
///       - Show orders dari ApiService.getOrders()
///       - Show order detail dengan ApiService.getOrderDetail()
/// 
/// 4. 🔄 Seller Features - TODO
///    - Create SellerDashboard screen
///    - Seller product management
///    - Seller order management
/// 
/// 5. 🔄 Admin Features - TODO
///    - Create AdminDashboard screen
///    - Admin user management
///    - Admin analytics
/// 
/// 6. 🔄 Additional Features - TODO
///    - Reviews & ratings
///    - Notifications
///    - Payment integration
///

// ============================================================
// IMPLEMENTATION GUIDE - Copy-paste ke screen yang relevan
// ============================================================

/// UNTUK LOGIN SCREEN
/// 
/// import 'package:buket_id/services/api_service.dart';
/// 
/// onPressed: () async {
///   try {
///     final result = await ApiService.login(
///       email: _emailController.text,
///       password: _passwordController.text,
///     );
///     
///     if (result['success']) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         const SnackBar(content: Text('Login berhasil!')),
///       );
///       Navigator.pushReplacementNamed(context, '/home');
///     } else {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(result['error'])),
///       );
///     }
///   } catch (e) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text('Error: $e')),
///     );
///   }
/// }

/// UNTUK HOME SCREEN
/// 
/// @override
/// void initState() {
///   super.initState();
///   _loadProducts();
/// }
/// 
/// Future<void> _loadProducts() async {
///   try {
///     final products = await ApiService.getAllProducts(
///       city: _selectedCity,
///       category: _selectedCategory,
///     );
///     
///     setState(() {
///       _products = products;
///     });
///   } catch (e) {
///     print('Error loading products: $e');
///   }
/// }

/// UNTUK PRODUCT DETAIL SCREEN
/// 
/// Future<void> _addToCart() async {
///   try {
///     final result = await ApiService.addToCart(
///       productId: widget.bouquet.id,
///       quantity: _quantity,
///     );
///     
///     if (result['success']) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         const SnackBar(content: Text('Produk ditambahkan ke keranjang')),
///       );
///     }
///   } catch (e) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text('Error: $e')),
///     );
///   }
/// }

/// UNTUK CART SCREEN
/// 
/// @override
/// void initState() {
///   super.initState();
///   _loadCart();
/// }
/// 
/// Future<void> _loadCart() async {
///   try {
///     final cartData = await ApiService.getCart();
///     
///     setState(() {
///       _cartItems = cartData['items'];
///       _totalPrice = cartData['total'];
///     });
///   } catch (e) {
///     print('Error loading cart: $e');
///   }
/// }
/// 
/// Future<void> _checkout() async {
///   try {
///     final items = _cartItems.map((item) => {
///       'product_id': item['product_id'],
///       'quantity': item['quantity'],
///     }).toList();
///     
///     final result = await ApiService.createOrder(items);
///     
///     if (result['success']) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         const SnackBar(content: Text('Order berhasil dibuat')),
///       );
///       Navigator.pushNamed(context, '/payment', arguments: result['data']);
///     }
///   } catch (e) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text('Error: $e')),
///     );
///   }
/// }
