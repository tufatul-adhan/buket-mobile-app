import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../widgets/custom_notification.dart';
import 'payment_screen.dart';

class CartScreen extends StatefulWidget {
  final CartService cartService;

  const CartScreen({
    Key? key,
    required this.cartService,
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  late CartService _cartService;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _cartService = widget.cartService;
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void removeItem(String bouquetId) {
    setState(() {
      _cartService.removeItem(bouquetId);
    });
    CustomNotification.showInfo(context,
        message: '🗑️ Item berhasil dihapus dari keranjang');
  }

  void updateQuantity(String bouquetId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(bouquetId);
      return;
    }
    setState(() {
      _cartService.updateQuantity(bouquetId, newQuantity);
    });
  }

  void checkout() {
    if (_cartService.items.isEmpty) {
      CustomNotification.showWarning(context,
          message:
              '🛒 Keranjang Anda kosong. Tambahkan produk terlebih dahulu untuk checkout');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          cartItems: _cartService.items,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Text('Keranjang Belanja'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cartService.items.isEmpty
          ? _buildEmptyCart(context)
          : SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                      parent: _slideController, curve: Curves.easeIn),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cartService.items.length,
                        itemBuilder: (context, index) {
                          final cartItem = _cartService.items[index];
                          return buildCartItemCard(cartItem);
                        },
                      ),
                    ),
                    buildCartSummary(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.softColor,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Keranjang Anda kosong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan buket favorit Anda untuk memulai',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Lanjut Belanja',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCartItemCard(CartItem cartItem) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.softColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppTheme.softColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product Image
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                    border: Border.all(color: AppTheme.softColor, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: cartItem.bouquet.images.isNotEmpty
                        ? buildImage(cartItem.bouquet.images.first)
                        : Icon(
                            Icons.local_florist,
                            size: 40,
                            color: AppTheme.primaryColor,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Product Info
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cartItem.bouquet.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${cartItem.bouquet.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Subtotal: Rp ${cartItem.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Quantity and Delete
                SizedBox(
                  width: 70,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Quantity selector
                      Container(
                        height: 32,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => updateQuantity(
                                    cartItem.bouquet.id,
                                    cartItem.quantity - 1,
                                  ),
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              color: AppTheme.softColor,
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  '${cartItem.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              color: AppTheme.softColor,
                            ),
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => updateQuantity(
                                    cartItem.bouquet.id,
                                    cartItem.quantity + 1,
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Delete button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => removeItem(cartItem.bouquet.id),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.red[200]!, width: 0.5),
                            ),
                            child: Icon(
                              Icons.delete_rounded,
                              size: 14,
                              color: Colors.red[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildImage(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.local_florist,
          color: AppTheme.primaryColor,
        ),
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.local_florist,
          color: AppTheme.primaryColor,
        ),
      );
    }
  }

  Widget buildCartSummary() {
    double totalPrice = _cartService.getTotalPrice();
    int totalItems = _cartService.getItemCount();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Items count with badge
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.softColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.softColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2_rounded,
                              color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Total Barang:',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '$totalItems',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Total price highlight
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.price_change_rounded,
                              color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Total Harga:',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      Flexible(
                        child: Text(
                          'Rp ${totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey[300]!, width: 2),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_rounded,
                                    color: Colors.grey[700], size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Lanjut',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              const Flexible(
                                child: Text(
                                  'Checkout',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
