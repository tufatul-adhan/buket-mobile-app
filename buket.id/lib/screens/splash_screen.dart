import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();
  
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _loadingOpacity;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkSessionAndNavigate();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Loading animation controller
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start animations sequentially
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _textController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  _checkSessionAndNavigate() async {
    // Initialize auth service
    await _authService.init();

    // Wait for splash screen display
    await Future.delayed(const Duration(seconds: 3), () {});

    if (mounted) {
      // Check if user is already logged in
      final currentUser = await _authService.getCurrentUser();

      if (currentUser != null) {
        // User sudah login, langsung ke home
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // User belum login, ke login screen
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth * 0.4;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryColor,
              AppTheme.softColor,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: Container(
                      width: logoSize.clamp(100, 200),
                      height: logoSize.clamp(100, 200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.95),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SvgPicture.asset(
                          'assets/icons/bouquet_logo.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),

                // Animated App Name
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: Text(
                      'Buket.id',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontSize: screenWidth > 600 ? 48 : 36,
                              ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Animated Tagline
                SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.1,
                      ),
                      child: Text(
                        'Buket Bunga Terbaik untuk Momen Spesialmu',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                  letterSpacing: 0.5,
                                  fontSize:
                                      screenWidth > 600 ? 18 : 14,
                                ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.08),

                // Custom Loading Indicator
                FadeTransition(
                  opacity: _loadingOpacity,
                  child: _buildCustomLoader(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomLoader() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 3,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.9),
            ),
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}