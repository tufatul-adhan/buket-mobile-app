import 'dart:async';

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/city_service.dart';
import '../models/city.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/custom_notification.dart';
import '../widgets/google_auth_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _cityService = CityService();

  String? _selectedCity;
  bool _isLoading = false;
  List<City> _cities = [];
  late final StreamSubscription<String> _googleTokenSubscription;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _cities = _cityService.getCities();
    _googleTokenSubscription = GoogleAuthService.instance.idTokens.listen(
      _finishGoogleSignIn,
      onError: _showGoogleError,
    );
    unawaited(
      GoogleAuthService.instance.initialize().catchError(_showGoogleError),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  Future<void> _initializeServices() async {
    await _authService.init();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _googleTokenSubscription.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || _selectedCity == null) {
      CustomNotification.showWarning(context,
          message:
              '⚠️ Mohon lengkapi semua kolom: email, password, dan pilih kota');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
        city: _selectedCity!,
      );

      if (success && mounted) {
        await _authService.updateUserCity(_selectedCity!);
        CustomNotification.showSuccess(context,
            message:
                '✅ Selamat! Anda berhasil login. Temukan buket impian Anda sekarang');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        CustomNotification.showError(context,
            message: '❌ Login gagal: $errorMsg');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_selectedCity == null) {
      CustomNotification.showWarning(
        context,
        message: 'Pilih kota terlebih dahulu untuk melanjutkan.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final idToken = await GoogleAuthService.instance.signIn();
      if (idToken != null) await _finishGoogleSignIn(idToken);
    } catch (error) {
      _showGoogleError(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _finishGoogleSignIn(String idToken) async {
    if (!mounted) return;
    if (_selectedCity == null) {
      CustomNotification.showWarning(
        context,
        message: 'Pilih kota terlebih dahulu untuk melanjutkan.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.loginWithGoogle(
        idToken: idToken,
        city: _selectedCity!,
      );
      if (mounted) {
        CustomNotification.showSuccess(
          context,
          message: 'Berhasil masuk dengan Google. Selamat datang!',
        );
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (error) {
      _showGoogleError(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGoogleError(Object error) {
    if (!mounted) return;
    final message = error.toString().replaceFirst('Exception: ', '');
    CustomNotification.showError(context, message: 'Google gagal: $message');
  }

  Future<void> _handleFacebookLogin() async {
    setState(() => _isLoading = true);

    try {
      if (_selectedCity == null) {
        CustomNotification.showWarning(context,
            message: '🏙️ Mohon pilih kota terlebih dahulu untuk melanjutkan');
        setState(() => _isLoading = false);
        return;
      }

      // Simulate Facebook login with demo email
      final email = 'user.facebook@facebook.com';
      final success = await _authService.login(
        email: email,
        password: 'facebook_login_token',
        city: _selectedCity!,
      );

      if (success && mounted) {
        await _authService.updateUserCity(_selectedCity!);
        CustomNotification.showSuccess(context,
            message: '✅ Selamat! Login dengan Facebook berhasil');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.showError(context,
            message:
                '❌ Login Facebook gagal. Silakan coba dengan akun email lain');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildFacebookLogo() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSocialButton({
    required String label,
    required Widget Function() logoBuilder,
    required VoidCallback onPressed,
    required bool isSmall,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmall ? 12 : 14,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: label == 'Google'
                  ? const Color(0xFF4285F4).withValues(alpha: 0.3)
                  : const Color(0xFF1877F2).withValues(alpha: 0.3),
              width: 2,
            ),
            color: label == 'Google'
                ? const Color(0xFF4285F4).withValues(alpha: 0.08)
                : const Color(0xFF1877F2).withValues(alpha: 0.08),
            boxShadow: [
              BoxShadow(
                color: label == 'Google'
                    ? const Color(0xFF4285F4).withValues(alpha: 0.1)
                    : const Color(0xFF1877F2).withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              logoBuilder(),
              if (!isSmall) ...[const SizedBox(width: 8), Text(label)],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;
    final headerHeight = (isSmall ? 180.0 : 250.0);
    final iconSize = isSmall ? 35.0 : 50.0;
    final titleFontSize = isSmall ? 22.0 : 28.0;
    final iconContainerSize = isSmall ? 60.0 : 80.0;

    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    final scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.softColor, AppTheme.softColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              // Header
              ScaleTransition(
                scale: scaleAnimation,
                child: Container(
                  height: headerHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: iconContainerSize,
                            height: iconContainerSize,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Icon(
                              Icons.local_florist_rounded,
                              size: iconSize,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Buket.id',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Form
              FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 20 : 40,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Selamat Datang',
                                style: Theme.of(context).textTheme.displaySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Login untuk lanjut berbelanja',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ScaleTransition(
                                scale:
                                    Tween<double>(begin: 0.9, end: 1).animate(
                                  CurvedAnimation(
                                    parent: _slideController,
                                    curve: const Interval(0.2, 0.6,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: CustomTextField(
                                  hintText: 'Masukkan email',
                                  label: 'Email',
                                  prefixIcon: Icons.email_outlined,
                                  controller: _emailController,
                                  validator: (v) {
                                    if (v?.isEmpty ?? true)
                                      return 'Email wajib';
                                    if (!v!.contains('@'))
                                      return 'Email tidak valid';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              ScaleTransition(
                                scale:
                                    Tween<double>(begin: 0.9, end: 1).animate(
                                  CurvedAnimation(
                                    parent: _slideController,
                                    curve: const Interval(0.3, 0.7,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: CustomTextField(
                                  hintText: 'Masukkan password',
                                  label: 'Password',
                                  prefixIcon: Icons.lock_outline,
                                  controller: _passwordController,
                                  isPassword: true,
                                  validator: (v) {
                                    if (v?.isEmpty ?? true)
                                      return 'Password wajib';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              ScaleTransition(
                                scale:
                                    Tween<double>(begin: 0.9, end: 1).animate(
                                  CurvedAnimation(
                                    parent: _slideController,
                                    curve: const Interval(0.4, 0.8,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: CustomDropdown(
                                  hintText: 'Pilih kota',
                                  label: 'Kota',
                                  prefixIcon: Icons.location_on_outlined,
                                  items: _cities.map((c) => c.name).toList(),
                                  value: _selectedCity,
                                  onChanged: (v) =>
                                      setState(() => _selectedCity = v),
                                  validator: (v) {
                                    if (v == null) return 'Pilih kota';
                                    return null;
                                  },
                                  isCityPicker: true,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ScaleTransition(
                                scale:
                                    Tween<double>(begin: 0.9, end: 1).animate(
                                  CurvedAnimation(
                                    parent: _slideController,
                                    curve: const Interval(0.5, 0.9,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: PrimaryButton(
                                  label: 'Login',
                                  onPressed: _handleLogin,
                                  isLoading: _isLoading,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 0),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                            color: AppTheme.borderColor)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text('atau',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color: AppTheme.borderColor)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Social Login Buttons
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _slideController,
                                    curve: const Interval(0.6, 1.0,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: GoogleAuthButton(
                                        isLoading: _isLoading,
                                        isRegister: false,
                                        onPressed: _handleGoogleLogin,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildEnhancedSocialButton(
                                        label: 'Facebook',
                                        logoBuilder: _buildFacebookLogo,
                                        onPressed: _handleFacebookLogin,
                                        isSmall: isSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              FadeTransition(
                                opacity:
                                    Tween<double>(begin: 0, end: 1).animate(
                                  CurvedAnimation(
                                    parent: _fadeController,
                                    curve: const Interval(0.7, 1.0,
                                        curve: Curves.easeIn),
                                  ),
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  children: [
                                    Text('Belum punya akun? ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (c) =>
                                                const RegisterScreen()),
                                      ),
                                      child: Text(
                                        'Daftar',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
