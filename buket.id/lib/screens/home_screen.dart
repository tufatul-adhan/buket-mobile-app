import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/bouquet.dart';
import '../services/bouquet_service.dart';
import '../services/cart_service.dart';
import '../services/city_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_widgets.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _bouquetService = BouquetService();
  final _cartService = CartService();
  final _cityService = CityService();

  String? _selectedCity;
  List<Bouquet> _bouquets = [];
  List<String> _categories = [];
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeData();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
  }

  Future<void> _initializeData() async {
    // Get user city from AuthService
    final authService = AuthService();
    await authService.init();
    final userCity = authService.getUserCity();

    final cities = _cityService.getCities();
    final selectedCity =
        userCity ?? (cities.isNotEmpty ? cities.first.name : null);

    setState(() {
      _selectedCity = selectedCity;
      if (selectedCity != null) {
        final allBouquets =
            _bouquetService.getBuketBerdasarkanKota(selectedCity);
        final categories = <String>{};
        for (var b in allBouquets) {
          categories.add(b.category);
        }
        _categories = categories.toList();
        _categories.insert(0, 'Semua');
      }
      _loadBouquets();
    });
  }

  void _loadBouquets() {
    if (_selectedCity == null) return;

    List<Bouquet> bouquets =
        _bouquetService.getBuketBerdasarkanKota(_selectedCity!);

    if (_selectedCategory != 'Semua') {
      bouquets = _bouquetService.filterBerdasarkanKategori(
          _selectedCity!, _selectedCategory);
    }

    if (_searchQuery.isNotEmpty) {
      bouquets = bouquets
          .where(
              (b) => b.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    setState(() => _bouquets = bouquets);
  }

  void _filterByCategory(String category) {
    setState(() => _selectedCategory = category);
    _loadBouquets();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authService = AuthService();
              await authService.init();
              await authService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;
    final isMedium = size.width < 900;
    final crossAxisCount = isSmall
        ? 2
        : isMedium
            ? 3
            : 4;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Buket.id',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: AppTheme.primaryColor),
            tooltip: 'Riwayat Pesanan',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart, color: AppTheme.primaryColor),
            tooltip: 'Keranjang',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CartScreen(cartService: _cartService),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: AppTheme.primaryColor),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan gradient menarik
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1).animate(
                    CurvedAnimation(
                        parent: _slideController, curve: Curves.easeOutCubic),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 16 : 24,
                      vertical: isSmall ? 20 : 28,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryLight.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmall ? 16 : 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Temukan buket bunga pilihan terbaik untuk orang tersayang Anda',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isSmall ? 12 : 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // City Display dengan design lebih bagus
                Padding(
                  padding: EdgeInsets.all(isSmall ? 12 : 16),
                  child: Container(
                    padding: EdgeInsets.all(isSmall ? 10 : 14),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppTheme.borderColor, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.softColor,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.borderColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.softColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: AppTheme.primaryDark,
                            size: isSmall ? 18 : 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Melayani Area',
                              style: TextStyle(
                                fontSize: isSmall ? 11 : 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _selectedCity ?? 'Tidak dipilih',
                              style: TextStyle(
                                fontSize: isSmall ? 13 : 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 12 : 16,
                    vertical: 8,
                  ),
                  child: CustomTextField(
                    hintText: 'Cari buket impian Anda...',
                    prefixIcon: Icons.search,
                  ),
                ),

                // Category Filter dengan scroll horizontal
                if (_categories.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.only(
                      left: isSmall ? 12 : 16,
                      top: 12,
                      bottom: 8,
                    ),
                    child: Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: isSmall ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _filterByCategory(category),
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey[100],
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[700],
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: isSmall ? 11 : 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Products Grid dengan responsif
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _bouquets.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.local_florist,
                                  size: 60,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada buket untuk pilihan ini',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: isSmall ? 12 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 8 : 16,
                            vertical: 8,
                          ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: isSmall ? 0.60 : 0.82,
                            crossAxisSpacing: isSmall ? 12 : 18,
                            mainAxisSpacing: isSmall ? 12 : 18,
                          ),
                          itemCount: _bouquets.length,
                          itemBuilder: (context, index) {
                            final bouquet = _bouquets[index];
                            return _BouquetCard(
                              bouquet: bouquet,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      bouquet: bouquet,
                                      cartService: _cartService,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BouquetCard extends StatefulWidget {
  final Bouquet bouquet;
  final VoidCallback onTap;

  const _BouquetCard({
    required this.bouquet,
    required this.onTap,
  });

  @override
  State<_BouquetCard> createState() => _BouquetCardState();
}

class _BouquetCardState extends State<_BouquetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Image dengan stack stock badge
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 148,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        colors: [AppTheme.softColor, AppTheme.softColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: widget.bouquet.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: _buildImage(widget.bouquet.images.first),
                          )
                        : Icon(
                            Icons.local_florist,
                            size: 60,
                            color: AppTheme.primaryColor,
                          ),
                  ),
                  // Stock badge di top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.bouquet.readyStock > 10
                            ? Colors.green
                            : widget.bouquet.readyStock > 5
                                ? Colors.amber
                                : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        widget.bouquet.readyStock > 10
                            ? '✓ Ready'
                            : widget.bouquet.readyStock > 5
                                ? '⚠ Terbatas'
                                : '❌ Habis',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.softColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.bouquet.category,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Name
                      Text(
                        widget.bouquet.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Rating dengan bintang
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.amber[500],
                          ),
                          const SizedBox(width: 1),
                          Text(
                            '${widget.bouquet.rating}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '(${widget.bouquet.reviews})',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Price dengan highlight
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.softColor,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: AppTheme.borderColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Rp ${widget.bouquet.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDark,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.local_florist,
          size: 60,
          color: AppTheme.primaryColor,
        ),
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.local_florist,
          size: 60,
          color: AppTheme.primaryColor,
        ),
      );
    }
  }
}
