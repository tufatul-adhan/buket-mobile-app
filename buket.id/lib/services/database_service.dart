import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/index.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'buket_id.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreateDatabase,
    );
  }

  Future<void> _onCreateDatabase(Database db, int version) async {
    // Tabel User (Akun Pengguna)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT,
        phone TEXT,
        city TEXT,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabel Cart Items (Keranjang Belanja)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cart_items (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        bouquet_id TEXT NOT NULL,
        bouquet_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        image_path TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Tabel Bouquets (Produk Bunga)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bouquets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        city TEXT,
        category TEXT,
        rating REAL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabel Orders (Riwayat Pesanan)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        order_number TEXT NOT NULL UNIQUE,
        total_price REAL NOT NULL,
        status TEXT NOT NULL,
        payment_method TEXT,
        shipping_address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Tabel Order Items (Item dalam Pesanan)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        bouquet_id TEXT NOT NULL,
        bouquet_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        image_path TEXT,
        notes TEXT,
        greeting_card TEXT,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (bouquet_id) REFERENCES bouquets (id)
      )
    ''');

    // Tabel Favorites (Produk Favorit)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        bouquet_id TEXT NOT NULL,
        bouquet_name TEXT NOT NULL,
        city TEXT NOT NULL,
        price REAL NOT NULL,
        image_path TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Tabel Product Reviews (Review Produk)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reviews (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        bouquet_id TEXT NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // ==================== USER METHODS ====================

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'password': user.password,
        'phone': user.phone,
        'city': user.city,
        'address': user.address,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> createUser(User user) async {
    final db = await database;
    try {
      await db.insert(
        'users',
        {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'password': user.password,
          'phone': user.phone,
          'city': user.city,
          'address': user.address,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('✅ User created: ${user.email}');
    } catch (e) {
      debugPrint('❌ Error creating user: $e');
    }
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isEmpty) return null;

    return User(
      id: result[0]['id'] as String,
      name: result[0]['name'] as String,
      email: result[0]['email'] as String,
      phone: result[0]['phone'] as String? ?? '',
      city: result[0]['city'] as String? ?? '',
      address: result[0]['address'] as String?,
      password: result[0]['password'] as String?,
    );
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;

    return User(
      id: result[0]['id'] as String,
      name: result[0]['name'] as String,
      email: result[0]['email'] as String,
      phone: result[0]['phone'] as String? ?? '',
      city: result[0]['city'] as String? ?? '',
      address: result[0]['address'] as String?,
      password: result[0]['password'] as String?,
    );
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      {
        'name': user.name,
        'phone': user.phone,
        'city': user.city,
        'address': user.address,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ==================== CART METHODS ====================

  Future<void> addToCart(String userId, CartItem item) async {
    final db = await database;
    await db.insert(
      'cart_items',
      {
        'id': item.id,
        'user_id': userId,
        'bouquet_id': item.bouquet.id,
        'bouquet_name': item.bouquet.name,
        'price': item.bouquet.price,
        'quantity': item.quantity,
        'image_path': item.bouquet.images.isNotEmpty
            ? item.bouquet.images[0]
            : 'assets/images/placeholder.png',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CartItem>> getCartItems(String userId) async {
    final db = await database;
    final result = await db.query(
      'cart_items',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return result.map((row) {
      return CartItem(
        id: row['id'] as String,
        bouquet: Bouquet(
          id: row['bouquet_id'] as String,
          name: row['bouquet_name'] as String,
          description: '',
          price: row['price'] as double,
          city: '',
          images: [(row['image_path'] as String?)?.split(',').first ?? ''],
          category: '',
          rating: 0,
          reviews: 0,
          readyStock: 0,
        ),
        quantity: row['quantity'] as int,
      );
    }).toList();
  }

  Future<void> removeFromCart(String cartItemId) async {
    final db = await database;
    await db.delete(
      'cart_items',
      where: 'id = ?',
      whereArgs: [cartItemId],
    );
  }

  Future<void> updateCartItemQuantity(String cartItemId, int quantity) async {
    final db = await database;
    await db.update(
      'cart_items',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [cartItemId],
    );
  }

  Future<void> clearCart(String userId) async {
    final db = await database;
    await db.delete(
      'cart_items',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ==================== ORDER METHODS ====================

  Future<void> createOrder(Order order, List<CartItem> items) async {
    final db = await database;

    await db.transaction((txn) async {
      // Insert order
      await txn.insert('orders', {
        'id': order.id,
        'user_id': order.userId,
        'order_number': 'ORD-${order.id}',
        'total_price': order.totalPrice,
        'status': order.status,
        'payment_method': order.paymentMethod,
        'shipping_address': order.address,
        'notes': '',
        'created_at': order.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Insert order items
      for (var item in items) {
        // First, ensure bouquet exists in bouquets table
        final existingBouquet = await txn.query(
          'bouquets',
          where: 'id = ?',
          whereArgs: [item.bouquet.id],
        );

        if (existingBouquet.isEmpty) {
          // Insert bouquet if not exists
          await txn.insert('bouquets', {
            'id': item.bouquet.id,
            'name': item.bouquet.name,
            'description': item.bouquet.description,
            'price': item.bouquet.price,
            'city': item.bouquet.city,
            'category': item.bouquet.category,
            'rating': item.bouquet.rating,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        // Insert order item
        await txn.insert('order_items', {
          'id': '${order.id}_${item.id}',
          'order_id': order.id,
          'bouquet_id': item.bouquet.id,
          'bouquet_name': item.bouquet.name,
          'price': item.bouquet.price,
          'quantity': item.quantity,
          'image_path':
              item.bouquet.images.isNotEmpty ? item.bouquet.images[0] : '',
          'notes': item.notes ?? '',
          'greeting_card': item.greetingCard ?? '',
        });
      }
    });
  }

  Future<List<Order>> getUserOrders(String userId) async {
    final db = await database;
    final result = await db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    List<Order> orders = [];
    for (var row in result) {
      final orderId = row['id'] as String;

      // Get items for this order
      final itemsResult = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

      List<CartItem> items = [];
      for (var itemRow in itemsResult) {
        final bouquetId = itemRow['bouquet_id'] as String;

        // Get bouquet details
        final bouquetResult = await db.query(
          'bouquets',
          where: 'id = ?',
          whereArgs: [bouquetId],
        );

        if (bouquetResult.isNotEmpty) {
          final bouquetRow = bouquetResult[0];
          final bouquet = Bouquet(
            id: bouquetRow['id'] as String,
            name: bouquetRow['name'] as String,
            description: bouquetRow['description'] as String? ?? '',
            price: (bouquetRow['price'] as num).toDouble(),
            city: bouquetRow['city'] as String? ?? '',
            images: [],
            category: bouquetRow['category'] as String? ?? '',
            rating: (bouquetRow['rating'] as num?)?.toDouble() ?? 0.0,
            reviews: 0,
          );

          items.add(CartItem(
            id: itemRow['id'] as String,
            bouquet: bouquet,
            quantity: itemRow['quantity'] as int? ?? 1,
            notes: itemRow['notes'] as String?,
            greetingCard: itemRow['greeting_card'] as String?,
          ));
        }
      }

      orders.add(Order(
        id: orderId,
        userId: row['user_id'] as String,
        items: items,
        totalPrice: row['total_price'] as double,
        status: row['status'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        paymentMethod: row['payment_method'] as String? ?? '',
        address: row['shipping_address'] as String? ?? '',
      ));
    }

    return orders;
  }

  Future<Order?> getOrderById(String orderId) async {
    final db = await database;
    final result = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );

    if (result.isEmpty) return null;

    final row = result[0];

    // Get items for this order
    final itemsResult = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    List<CartItem> items = [];
    for (var itemRow in itemsResult) {
      final bouquetId = itemRow['bouquet_id'] as String;

      // Get bouquet details
      final bouquetResult = await db.query(
        'bouquets',
        where: 'id = ?',
        whereArgs: [bouquetId],
      );

      if (bouquetResult.isNotEmpty) {
        final bouquetRow = bouquetResult[0];
        final bouquet = Bouquet(
          id: bouquetRow['id'] as String,
          name: bouquetRow['name'] as String,
          description: bouquetRow['description'] as String? ?? '',
          price: (bouquetRow['price'] as num).toDouble(),
          city: bouquetRow['city'] as String? ?? '',
          images: [],
          category: bouquetRow['category'] as String? ?? '',
          rating: (bouquetRow['rating'] as num?)?.toDouble() ?? 0.0,
          reviews: 0,
        );

        items.add(CartItem(
          id: itemRow['id'] as String,
          bouquet: bouquet,
          quantity: itemRow['quantity'] as int? ?? 1,
          notes: itemRow['notes'] as String?,
          greetingCard: itemRow['greeting_card'] as String?,
        ));
      }
    }

    return Order(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      items: items,
      totalPrice: row['total_price'] as double,
      status: row['status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      paymentMethod: row['payment_method'] as String? ?? '',
      address: row['shipping_address'] as String? ?? '',
    );
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final db = await database;
    await db.update(
      'orders',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // ==================== FAVORITES METHODS ====================

  Future<void> addToFavorites(String userId, Bouquet bouquet) async {
    final db = await database;
    await db.insert(
      'favorites',
      {
        'id': '${userId}_${bouquet.id}',
        'user_id': userId,
        'bouquet_id': bouquet.id,
        'bouquet_name': bouquet.name,
        'city': bouquet.city,
        'price': bouquet.price,
        'image_path':
            bouquet.images.isNotEmpty ? bouquet.images[0] : 'assets/images/',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFromFavorites(String userId, String bouquetId) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'user_id = ? AND bouquet_id = ?',
      whereArgs: [userId, bouquetId],
    );
  }

  Future<List<Bouquet>> getUserFavorites(String userId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return result.map((row) {
      return Bouquet(
        id: row['bouquet_id'] as String,
        name: row['bouquet_name'] as String,
        description: '',
        price: row['price'] as double,
        city: row['city'] as String,
        images: [(row['image_path'] as String?)?.split(',').first ?? ''],
        category: '',
        rating: 0,
        reviews: 0,
        readyStock: 0,
      );
    }).toList();
  }

  Future<bool> isFavorited(String userId, String bouquetId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'user_id = ? AND bouquet_id = ?',
      whereArgs: [userId, bouquetId],
    );

    return result.isNotEmpty;
  }

  // ==================== REVIEWS METHODS ====================

  Future<void> addReview(
      String userId, String bouquetId, int rating, String comment) async {
    final db = await database;
    final reviewId =
        '${userId}_${bouquetId}_${DateTime.now().millisecondsSinceEpoch}';

    await db.insert(
      'reviews',
      {
        'id': reviewId,
        'user_id': userId,
        'bouquet_id': bouquetId,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getProductReviews(String bouquetId) async {
    final db = await database;
    return await db.query(
      'reviews',
      where: 'bouquet_id = ?',
      whereArgs: [bouquetId],
      orderBy: 'created_at DESC',
    );
  }

  // ==================== UTILITY METHODS ====================

  Future<void> clearAllData() async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('reviews');
      await txn.delete('favorites');
      await txn.delete('order_items');
      await txn.delete('orders');
      await txn.delete('cart_items');
      await txn.delete('users');
    });
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
