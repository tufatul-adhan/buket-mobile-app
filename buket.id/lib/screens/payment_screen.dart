import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/telegram_notification_service.dart';
import '../widgets/custom_notification.dart';

// Payment Method Models
class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final List<String> options;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.options,
  });
}

class PaymentScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const PaymentScreen({
    Key? key,
    required this.cartItems,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  // Enhanced Payment Methods with sub-options
  late List<PaymentMethod> _paymentMethods;

  final List<String> _greetingCards = [
    'Tidak Ada',
    'Ucapan Selamat Ulang Tahun',
    'Ucapan Selamat Pernikahan',
    'Ucapan Selamat Wisuda',
    'Ucapan Terima Kasih',
    'Ucapan Kustom',
  ];

  late AnimationController _slideController;
  late AnimationController _fadeController;
  String? _selectedPaymentMethod;
  String? _selectedPaymentOption;
  String? _selectedGreetingCard = 'Tidak Ada';
  bool _isProcessing = false;
  bool _showPaymentOptions = false;

  @override
  void initState() {
    super.initState();
    _initializePaymentMethods();
    _initializeServices();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
  }

  void _initializePaymentMethods() {
    _paymentMethods = [
      PaymentMethod(
        id: 'credit_card',
        name: 'Kartu Kredit',
        icon: Icons.credit_card_rounded,
        options: ['Visa', 'Mastercard', 'American Express'],
      ),
      PaymentMethod(
        id: 'bank_transfer',
        name: 'Transfer Bank',
        icon: Icons.account_balance_rounded,
        options: ['BCA', 'Mandiri', 'BNI', 'CIMB Niaga', 'Permata', 'Danamon'],
      ),
      PaymentMethod(
        id: 'qris',
        name: 'QRIS',
        icon: Icons.qr_code_2_rounded,
        options: ['Scan QRIS'],
      ),
      PaymentMethod(
        id: 'ewallet',
        name: 'E-Wallet',
        icon: Icons.account_balance_wallet_rounded,
        options: ['Dana', 'GoPay', 'Shopee Pay', 'OVO'],
      ),
      PaymentMethod(
        id: 'cod',
        name: 'Bayar di Tempat (COD)',
        icon: Icons.payments_rounded,
        options: ['Cash'],
      ),
    ];
  }

  Future<void> _initializeServices() async {
    await _authService.init();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null ||
        _selectedPaymentOption == null ||
        _addressController.text.isEmpty) {
      CustomNotification.showWarning(context,
          message:
              '⚠️ Lengkapi semua data pembayaran (metode, alamat, pilihan pembayaran)');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Save order to database
        final dbService = DatabaseService();
        final authService = _authService;
        final currentUser = await authService.getCurrentUser();
        debugPrint('🔍 Payment Process Started');
        debugPrint(
            '👤 Current user: ${currentUser?.id} (${currentUser?.email})');

        if (currentUser != null) {
          final paymentMethodName = _paymentMethods
              .firstWhere((p) => p.id == _selectedPaymentMethod,
                  orElse: () => _paymentMethods.first)
              .name;

          final totalAmount = widget.cartItems
                  .fold<double>(0, (sum, item) => sum + item.total) +
              25000;
          debugPrint('🛒 Items: ${widget.cartItems.length}');
          debugPrint('💰 Total: Rp $totalAmount');
          debugPrint('📍 Address: ${_addressController.text}');
          debugPrint('💳 Payment Method: $paymentMethodName');

          final order = Order(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: currentUser.id,
            items: widget.cartItems,
            totalPrice: totalAmount,
            status: 'pending',
            createdAt: DateTime.now(),
            paymentMethod: paymentMethodName,
            address: _addressController.text,
          );
          debugPrint('📋 Order created: #${order.id.substring(0, 8)}');

          // Save to database
          try {
            debugPrint('💾 Saving order to database...');
            await dbService.createOrder(order, widget.cartItems);
            debugPrint('✅ Order saved to database successfully');
          } catch (dbError) {
            debugPrint('❌ Error saving order to database: $dbError');
            debugPrint('🔍 Stack trace: ${dbError.toString()}');
            if (mounted) {
              CustomNotification.showError(context,
                  message: '❌ Gagal menyimpan pesanan: $dbError');
            }
            setState(() => _isProcessing = false);
            return;
          }

          // 🚀 Kirim notifikasi ke Telegram (non-blocking)
          debugPrint('📤 Sending Telegram notification...');
          final telegramSent =
              await TelegramNotificationService.sendPaymentNotification(
            order: order,
            items: widget.cartItems,
            userName: currentUser.name,
            userEmail: currentUser.email,
          );

          if (telegramSent) {
            debugPrint('✅ Telegram notification sent');
          } else {
            debugPrint(
                '⚠️ Telegram notification failed - check Bot Token and Chat ID');
          }
        } else {
          debugPrint('❌ Current user is null');
          if (mounted) {
            CustomNotification.showError(context,
                message: '❌ User tidak ditemukan. Silakan login kembali');
          }
          setState(() => _isProcessing = false);
          return;
        }

        // Find payment method name for display
        final paymentMethodName = _paymentMethods
            .firstWhere((p) => p.id == _selectedPaymentMethod,
                orElse: () => _paymentMethods.first)
            .name;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: _SuccessPaymentDialog(
              cartItems: widget.cartItems,
              paymentMethodName: paymentMethodName,
              selectedPaymentOption: _selectedPaymentOption ?? '',
              selectedGreetingCard: _selectedGreetingCard ?? '',
              notes: _notesController.text,
              address: _addressController.text,
              onHomePressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                  (route) => false,
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.showError(context,
            message: '❌ Pembayaran gagal. Silakan periksa data dan coba lagi');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryFee = 25000.0;
    final subtotal =
        widget.cartItems.fold<double>(0, (sum, item) => sum + item.total);
    final total = subtotal + deliveryFee;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = isSmallScreen ? 16.0 : 32.0;
    final buttonHeight = isSmallScreen ? 48.0 : 54.0;

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pembayaran',
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Summary with Enhanced Design
                      _buildOrderSummaryCard(
                          context, subtotal, deliveryFee, total),
                      const SizedBox(height: 28),

                      // Delivery Address
                      _buildSectionHeader('Alamat Pengiriman', context),
                      const SizedBox(height: 12),
                      _buildAddressField(),
                      const SizedBox(height: 28),

                      // Greeting Card Section
                      _buildSectionHeader('Kartu Ucapan (Opsional)', context),
                      const SizedBox(height: 12),
                      _buildGreetingCardField(),
                      const SizedBox(height: 28),

                      // Notes Section
                      _buildSectionHeader(
                          'Catatan untuk Pesanan (Opsional)', context),
                      const SizedBox(height: 12),
                      _buildNotesField(),
                      const SizedBox(height: 28),

                      // Payment Method
                      _buildSectionHeader('Metode Pembayaran', context),
                      const SizedBox(height: 12),
                      _buildPaymentMethodsList(context),
                      const SizedBox(height: 28),

                      // Pay Button
                      _buildPayButton(buttonHeight),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[800],
              ),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard(
      BuildContext context, double subtotal, double deliveryFee, double total) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.softColor, AppTheme.softColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.borderColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag_rounded,
                  color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Ringkasan Pesanan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.cartItems.asMap().entries.map((entry) {
            int idx = entry.key;
            var cartItem = entry.value;
            return _buildOrderItemTile(
              cartItem,
              isLast: idx == widget.cartItems.length - 1,
            );
          }).toList(),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: AppTheme.primaryLight.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          _buildPriceTile('Biaya Pengiriman:', _formatPrice(deliveryFee)),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: AppTheme.primaryLight.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          _buildPriceTile(
            'Total:',
            _formatPrice(total),
            isBold: true,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemTile(CartItem cartItem, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.bouquet.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'x${cartItem.quantity}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatPrice(cartItem.total),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: AppTheme.primaryLight.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildPriceTile(String label, String price,
      {bool isBold = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 15 : 14,
            color: Colors.grey[isTotal ? 800 : 700],
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isBold ? 15 : 14,
            color: isTotal ? AppTheme.primaryDark : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _addressController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Masukkan alamat lengkap (jalan, nomor rumah, RT/RW, dll)',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(top: 12),
            child:
                Icon(Icons.location_on_rounded, color: AppTheme.primaryColor),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildGreetingCardField() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileSize = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobileSize ? 14 : 16,
            vertical: isMobileSize ? 10 : 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.softColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppTheme.softColor.withValues(alpha: 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.card_giftcard_rounded,
                    color: AppTheme.primaryColor,
                    size: isMobileSize ? 18 : 20,
                  ),
                  SizedBox(width: isMobileSize ? 8 : 10),
                  Text(
                    'Pilih Kartu Ucapan',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: isMobileSize ? 12 : 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobileSize ? 8 : 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade50,
                  border: Border.all(
                    color: AppTheme.softColor,
                    width: 1,
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedGreetingCard,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: Padding(
                    padding: EdgeInsets.only(right: isMobileSize ? 8 : 12),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: AppTheme.primaryColor,
                      size: isMobileSize ? 20 : 22,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobileSize ? 12 : 14,
                    vertical: isMobileSize ? 10 : 12,
                  ),
                  items: _greetingCards.map((String card) {
                    final isSpecial =
                        card != 'Tidak Ada' && card == _selectedGreetingCard;
                    return DropdownMenuItem<String>(
                      value: card,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            if (card == 'Tidak Ada')
                              Icon(
                                Icons.close_rounded,
                                color: Colors.grey.shade400,
                                size: isMobileSize ? 16 : 18,
                              )
                            else
                              Icon(
                                Icons.card_giftcard_rounded,
                                color: AppTheme.primaryColor,
                                size: isMobileSize ? 16 : 18,
                              ),
                            SizedBox(width: isMobileSize ? 8 : 10),
                            Expanded(
                              child: Text(
                                card,
                                style: TextStyle(
                                  fontSize: isMobileSize ? 12 : 13,
                                  color: isSpecial
                                      ? AppTheme.primaryDark
                                      : Colors.grey.shade700,
                                  fontWeight: isSpecial
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedGreetingCard = newValue);
                    }
                  },
                  style: TextStyle(
                    fontSize: isMobileSize ? 12 : 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: isMobileSize ? 8 : 10),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobileSize ? 10 : 12,
                  vertical: isMobileSize ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.softColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.softColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.primaryColor,
                      size: isMobileSize ? 14 : 16,
                    ),
                    SizedBox(width: isMobileSize ? 6 : 8),
                    Expanded(
                      child: Text(
                        _selectedGreetingCard == 'Tidak Ada'
                            ? 'Kartu ucapan opsional'
                            : 'Kartu ucapan akan disertakan',
                        style: TextStyle(
                          fontSize: isMobileSize ? 11 : 12,
                          color: AppTheme.primaryDark,
                          fontStyle: FontStyle.italic,
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
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText:
              'Contoh: Warna lebih ke merah muda, bunga kesayangan penerima adalah mawar...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(Icons.note_rounded, color: AppTheme.primaryColor),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paymentMethods.length,
      itemBuilder: (context, index) {
        final method = _paymentMethods[index];
        final isSelected = _selectedPaymentMethod == method.id;
        return _buildPaymentMethodTile(method, isSelected, index);
      },
    );
  }

  Widget _buildPaymentMethodTile(
      PaymentMethod method, bool isSelected, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedPaymentMethod = method.id;
              _selectedPaymentOption =
                  null; // Reset option when changing method
              _showPaymentOptions = true; // Show options for this method
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected ? AppTheme.softColor : Colors.white,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.grey[200]!,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        color:
                            isSelected ? AppTheme.primaryColor : Colors.white,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Icon(method.icon,
                        color: isSelected
                            ? AppTheme.primaryDark
                            : Colors.grey[600],
                        size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 15,
                              color: isSelected
                                  ? AppTheme.primaryDark
                                  : Colors.grey[700],
                            ),
                          ),
                          if (isSelected && _selectedPaymentOption != null)
                            Text(
                              'Pilihan: $_selectedPaymentOption',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.done_all_rounded,
                          color: AppTheme.primaryColor, size: 20),
                  ],
                ),
                if (isSelected && _showPaymentOptions)
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _buildPaymentOptionSelector(method),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOptionSelector(PaymentMethod method) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih ${method.name.toLowerCase()}:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: method.options
              .map((option) => ChoiceChip(
                    label: Text(option),
                    selected: _selectedPaymentOption == option,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPaymentOption = selected ? option : null;
                      });
                    },
                    selectedColor: AppTheme.borderColor,
                    backgroundColor: Colors.grey[100],
                    labelStyle: TextStyle(
                      color: _selectedPaymentOption == option
                          ? AppTheme.primaryDark
                          : Colors.grey[700],
                      fontWeight: _selectedPaymentOption == option
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPayButton(double buttonHeight) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isProcessing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Memproses...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Bayar Sekarang',
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
    );
  }

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
}

class _SuccessPaymentDialog extends StatefulWidget {
  final List<CartItem> cartItems;
  final String paymentMethodName;
  final String selectedPaymentOption;
  final String selectedGreetingCard;
  final String notes;
  final String address;
  final VoidCallback onHomePressed;

  const _SuccessPaymentDialog({
    required this.cartItems,
    required this.paymentMethodName,
    required this.selectedPaymentOption,
    required this.selectedGreetingCard,
    required this.notes,
    required this.address,
    required this.onHomePressed,
  });

  @override
  State<_SuccessPaymentDialog> createState() => _SuccessPaymentDialogState();
}

class _SuccessPaymentDialogState extends State<_SuccessPaymentDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _scaleController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total =
        widget.cartItems.fold<double>(0, (sum, item) => sum + item.total) +
            25000;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobileSize = screenWidth < 600;

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobileSize ? screenWidth - 24 : 520,
              maxHeight: screenHeight * 0.88,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, const Color(0xFFFAFAFA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.15),
                  blurRadius: 48,
                  offset: const Offset(0, 24),
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Header dengan pink gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE91E63),
                            const Color(0xFFC2185B),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: isMobileSize ? 28 : 36,
                        horizontal: isMobileSize ? 16 : 24,
                      ),
                      child: Column(
                        children: [
                          // Animated checkmark
                          ScaleTransition(
                            scale: Tween<double>(begin: 0.3, end: 1).animate(
                              CurvedAnimation(
                                parent: _scaleController,
                                curve: const Interval(0.2, 0.7,
                                    curve: Curves.elasticOut),
                              ),
                            ),
                            child: RotationTransition(
                              turns: Tween<double>(begin: 0, end: 1).animate(
                                CurvedAnimation(
                                  parent: _scaleController,
                                  curve: const Interval(0.4, 0.9,
                                      curve: Curves.easeOutBack),
                                ),
                              ),
                              child: Container(
                                width: isMobileSize ? 72 : 88,
                                height: isMobileSize ? 72 : 88,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: isMobileSize ? 48 : 56,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isMobileSize ? 14 : 18),
                          Text(
                            'Pembayaran Berhasil',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobileSize ? 22 : 26,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: isMobileSize ? 6 : 10),
                          Text(
                            'Pesanan Anda telah dikonfirmasi',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: isMobileSize ? 13 : 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobileSize ? 16 : 24,
                        vertical: isMobileSize ? 18 : 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order Items Section
                          _buildSectionTitle('Rincian Pesanan', isMobileSize),
                          SizedBox(height: isMobileSize ? 10 : 14),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFFFAFAFA),
                              border: Border.all(
                                color: const Color(0xFFE91E63)
                                    .withValues(alpha: 0.1),
                                width: 1.5,
                              ),
                            ),
                            padding: EdgeInsets.all(isMobileSize ? 12 : 16),
                            child: Column(
                              children: [
                                ...widget.cartItems
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  int idx = entry.key;
                                  var item = entry.value;
                                  return _buildOrderItemRow(
                                    item,
                                    isLast: idx == widget.cartItems.length - 1,
                                    isMobileSize: isMobileSize,
                                  );
                                }).toList(),
                                SizedBox(height: isMobileSize ? 10 : 12),
                                Container(
                                  height: 1,
                                  color: const Color(0xFFE91E63)
                                      .withValues(alpha: 0.15),
                                ),
                                SizedBox(height: isMobileSize ? 10 : 12),
                                _buildPriceRow(
                                  'Biaya Pengiriman',
                                  _formatPriceWithoutClass(25000),
                                  isMobileSize: isMobileSize,
                                ),
                                SizedBox(height: isMobileSize ? 10 : 12),
                                Container(
                                  height: 1.5,
                                  color: const Color(0xFFE91E63)
                                      .withValues(alpha: 0.2),
                                ),
                                SizedBox(height: isMobileSize ? 10 : 12),
                                _buildPriceRow(
                                  'Total Pembayaran',
                                  _formatPriceWithoutClass(total),
                                  isTotal: true,
                                  isMobileSize: isMobileSize,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: isMobileSize ? 16 : 22),

                          // Payment Method Section
                          _buildSectionTitle('Metode Pembayaran', isMobileSize),
                          SizedBox(height: isMobileSize ? 10 : 14),
                          _buildInfoCard(
                            icon: Icons.payment_rounded,
                            label: 'Metode',
                            value: widget.paymentMethodName,
                            isMobileSize: isMobileSize,
                          ),
                          SizedBox(height: isMobileSize ? 8 : 10),
                          _buildInfoCard(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Pilihan',
                            value: widget.selectedPaymentOption,
                            isMobileSize: isMobileSize,
                          ),

                          SizedBox(height: isMobileSize ? 16 : 22),

                          // Delivery Section
                          _buildSectionTitle('Pengiriman', isMobileSize),
                          SizedBox(height: isMobileSize ? 10 : 14),
                          _buildInfoCard(
                            icon: Icons.location_on_rounded,
                            label: 'Alamat Tujuan',
                            value: widget.address,
                            maxLines: 2,
                            isMobileSize: isMobileSize,
                          ),
                          if (widget.selectedGreetingCard != 'Tidak Ada') ...[
                            SizedBox(height: isMobileSize ? 8 : 10),
                            _buildInfoCard(
                              icon: Icons.card_giftcard_rounded,
                              label: 'Kartu Ucapan',
                              value: widget.selectedGreetingCard,
                              maxLines: 2,
                              isMobileSize: isMobileSize,
                            ),
                          ],
                          if (widget.notes.isNotEmpty) ...[
                            SizedBox(height: isMobileSize ? 8 : 10),
                            _buildInfoCard(
                              icon: Icons.note_rounded,
                              label: 'Catatan',
                              value: widget.notes,
                              maxLines: 2,
                              isMobileSize: isMobileSize,
                            ),
                          ],

                          SizedBox(height: isMobileSize ? 20 : 28),

                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            height: isMobileSize ? 48 : 54,
                            child: ElevatedButton(
                              onPressed: widget.onHomePressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE91E63),
                                disabledBackgroundColor: Colors.grey[300],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                                shadowColor: const Color(0xFFE91E63)
                                    .withValues(alpha: 0.4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.home_rounded,
                                    size: isMobileSize ? 18 : 20,
                                  ),
                                  SizedBox(width: isMobileSize ? 8 : 10),
                                  Text(
                                    'Kembali ke Beranda',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: isMobileSize ? 14 : 15,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isMobileSize) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFE91E63),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF212121),
            fontWeight: FontWeight.bold,
            fontSize: isMobileSize ? 13 : 15,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemRow(
    CartItem item, {
    bool isLast = false,
    bool isMobileSize = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.bouquet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobileSize ? 12 : 13,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'x${item.quantity}',
                    style: TextStyle(
                      fontSize: isMobileSize ? 11 : 12,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatPriceWithoutClass(item.total),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobileSize ? 12 : 13,
                color: const Color(0xFF212121),
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          SizedBox(height: isMobileSize ? 8 : 10),
          Container(
            height: 1,
            color: const Color(0xFFE91E63).withValues(alpha: 0.1),
          ),
          SizedBox(height: isMobileSize ? 8 : 10),
        ],
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    String price, {
    bool isTotal = false,
    bool isMobileSize = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? const Color(0xFF212121) : const Color(0xFF757575),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isMobileSize ? 12 : 13,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobileSize ? 12 : 13,
            color: isTotal ? const Color(0xFFE91E63) : const Color(0xFF212121),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
    bool isMobileSize = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFFAFAFA),
        border: Border.all(
          color: const Color(0xFFE91E63).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(isMobileSize ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFE91E63),
            size: isMobileSize ? 18 : 20,
          ),
          SizedBox(width: isMobileSize ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xFF757575),
                    fontSize: isMobileSize ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: isMobileSize ? 3 : 4),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF212121),
                    fontWeight: FontWeight.w600,
                    fontSize: isMobileSize ? 12 : 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPriceWithoutClass(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
}
