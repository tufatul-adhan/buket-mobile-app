import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/bouquet.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../widgets/custom_notification.dart';
import 'payment_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Bouquet bouquet;
  final CartService cartService;

  const ProductDetailScreen({
    Key? key,
    required this.bouquet,
    required this.cartService,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _addToCart() {
    if (_quantity > widget.bouquet.readyStock) {
      CustomNotification.showWarning(context,
          message:
              '⚠️ Stok terbatas! Maksimal pemesanan hanya ${widget.bouquet.readyStock} item');
      return;
    }

    for (int i = 0; i < _quantity; i++) {
      widget.cartService.addItem(widget.bouquet);
    }

    CustomNotification.showSuccess(context,
        message:
            '🛒 ${widget.bouquet.name} x $_quantity berhasil ditambahkan ke keranjang');
  }

  void _buyNow() {
    final cartItem = CartItem(
      id: widget.bouquet.id,
      bouquet: widget.bouquet,
      quantity: _quantity,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(cartItems: [cartItem]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detail Produk',
          style: TextStyle(color: Colors.grey[800]),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: double.infinity,
                  height: 300,
                  color: AppTheme.softColor,
                  child: widget.bouquet.images.isNotEmpty
                      ? _buildImage(widget.bouquet.images.first)
                      : Icon(
                          Icons.local_florist,
                          size: 150,
                          color: AppTheme.primaryColor,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        widget.bouquet.name,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[900],
                                ),
                      ),
                      const SizedBox(height: 12),
                      // Rating
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.bouquet.rating}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${widget.bouquet.reviews} ulasan)',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Rp ${widget.bouquet.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.softColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.bouquet.category,
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Ready Stock Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.bouquet.readyStock > 10
                              ? Colors.green[50]
                              : widget.bouquet.readyStock > 5
                                  ? Colors.amber[50]
                                  : Colors.red[50],
                          border: Border.all(
                            color: widget.bouquet.readyStock > 10
                                ? Colors.green[300]!
                                : widget.bouquet.readyStock > 5
                                    ? Colors.amber[300]!
                                    : Colors.red[300]!,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.bouquet.readyStock > 5
                                  ? Icons.inventory_2
                                  : Icons.warning,
                              size: 18,
                              color: widget.bouquet.readyStock > 10
                                  ? Colors.green[600]
                                  : widget.bouquet.readyStock > 5
                                      ? Colors.amber[600]
                                      : Colors.red[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.bouquet.readyStock > 0
                                  ? 'Stok: ${widget.bouquet.readyStock} tersedia'
                                  : 'Stok habis',
                              style: TextStyle(
                                color: widget.bouquet.readyStock > 10
                                    ? Colors.green[700]
                                    : widget.bouquet.readyStock > 5
                                        ? Colors.amber[700]
                                        : Colors.red[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Divider
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      // Description
                      Text(
                        'Deskripsi',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.bouquet.description,
                        style: TextStyle(
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Quantity Selector dengan design modern
                      Text(
                        'Jumlah',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: _quantity > 1
                                        ? AppTheme.primaryColor
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  color: _quantity > 1
                                      ? AppTheme.primaryColor
                                      : Colors.grey[400],
                                  size: 20,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _quantity.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryDark,
                                        ),
                                  ),
                                  Text(
                                    'dari ${widget.bouquet.readyStock}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _quantity < widget.bouquet.readyStock
                                  ? () => setState(() => _quantity++)
                                  : null,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _quantity < widget.bouquet.readyStock
                                      ? AppTheme.primaryColor
                                      : Colors.grey[300],
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: _quantity < widget.bouquet.readyStock
                                      ? Colors.white
                                      : Colors.grey[500],
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Total Price
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.softColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Rp ${(widget.bouquet.price * _quantity).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryDark,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Add to Cart & Buy Now Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _addToCart,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Colors.grey[700],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Keranjang',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _buyNow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.flash_on,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Beli Sekarang',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
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
                      const SizedBox(height: 20),
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

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Network image
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.local_florist,
          size: 150,
          color: AppTheme.primaryColor,
        ),
      );
    } else {
      // Local asset image
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.local_florist,
          size: 150,
          color: AppTheme.primaryColor,
        ),
      );
    }
  }
}
