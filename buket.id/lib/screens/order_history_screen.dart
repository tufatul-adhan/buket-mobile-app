import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/order.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    await _authService.init();
    setState(() {
      _ordersFuture = _fetchOrders();
    });
  }

  Future<List<Order>> _fetchOrders() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        return [];
      }

      final orders = await _dbService.getUserOrders(user.id);
      return orders;
    } catch (e) {
      debugPrint('Error loading orders: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        backgroundColor: AppTheme.bgColor,
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum Ada Pesanan',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Mulai belanja sekarang untuk membuat pesanan pertama Anda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Lanjut Belanja'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView.builder(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildOrderCard(context, order, isMobile);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order, bool isMobile) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.shopping_bag,
            color: statusColor,
            size: 24,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesanan #${order.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(order.createdAt),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Rp${order.totalPrice.toStringAsFixed(0)}',
            style: TextStyle(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor, width: 1),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header details grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth > 400;
                    return isTablet
                        ? _buildTabletDetails(order, statusColor, statusLabel)
                        : _buildMobileDetails(order, statusColor, statusLabel);
                  },
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade300, thickness: 1),
                const SizedBox(height: 16),
                _buildItemsSection(order, isMobile),
                const SizedBox(height: 16),
                _buildTotalSection(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletDetails(
      Order order, Color statusColor, String statusLabel) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildDetailCard('📍 Alamat', order.address),
            _buildDetailCard('💳 Pembayaran', order.paymentMethod),
            _buildDetailCard('🔄 Status', statusLabel, statusColor),
            _buildDetailCard('📦 Jumlah Item', '${order.items.length} produk'),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade400, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pesanan dibuat: ${_formatDate(order.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileDetails(
      Order order, Color statusColor, String statusLabel) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderDetail('📍 Alamat Pengiriman', order.address),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 12),
              _buildOrderDetail('💳 Metode Pembayaran', order.paymentMethod),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 12),
              _buildOrderDetail('🔄 Status', statusLabel, color: statusColor),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 12),
              _buildOrderDetail(
                  '📦 Jumlah Item', '${order.items.length} produk'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: Colors.blue.shade400, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dibuat: ${_formatDate(order.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(String label, String value, [Color? color]) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color ?? Colors.black87,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(Order order, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2_outlined,
                color: AppTheme.primaryLight, size: 20),
            const SizedBox(width: 8),
            Text(
              'Detail Produk (${order.items.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (order.items.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: order.items.asMap().entries.map((entry) {
                final item = entry.value;
                final isLast = entry.key == order.items.length - 1;
                return _buildItemRow(item, isLast, isMobile);
              }).toList(),
            ),
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tidak ada item',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemRow(dynamic item, bool isLast, bool isMobile) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          child: Row(
            children: [
              // Item Number Badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.softColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${item.quantity}x',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.bouquet.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Rp${item.bouquet.price.toStringAsFixed(0)}/pcs',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            'Qty: ${item.quantity}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp${(item.bouquet.price * item.quantity).toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '(${item.quantity} produk)',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.grey.shade300, height: 1),
      ],
    );
  }

  Widget _buildTotalSection(Order order) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.softColor, AppTheme.softColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pesanan:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                'Rp${order.totalPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: AppTheme.borderColor, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'Status: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Text(
                _getStatusLabel(order.status),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: _getStatusColor(order.status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetail(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'delivered':
        return Colors.green;
      case 'pending':
      case 'diproses':
        return Colors.blue;
      case 'dibatalkan':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'delivered':
        return 'Selesai';
      case 'pending':
        return 'Pending';
      case 'diproses':
        return 'Diproses';
      case 'dibatalkan':
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
