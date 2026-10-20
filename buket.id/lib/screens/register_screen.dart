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
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _googleTokenSubscription.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate() || _selectedCity == null) {
      CustomNotification.showWarning(context,
          message: '⚠️ Mohon lengkapi semua kolom untuk mendaftar');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      CustomNotification.showWarning(context,
          message: '🔐 Password tidak cocok. Periksa kembali');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        city: _selectedCity!,
      );

      if (success && mounted) {
        CustomNotification.showSuccess(context,
            message:
                '✅ Selamat! Akun berhasil dibuat. Silakan login untuk memulai berbelanja');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        // Show full error for debugging
        debugPrint('Register error: $e');
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        CustomNotification.showError(context,
            message: '❌ Registrasi gagal: $errorMsg');
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

      final email = 'user.facebook@facebook.com';
      final success = await _authService.register(
        name: 'Facebook User',
        email: email,
        password: 'facebook_login_token',
        phone: '0812345678',
        city: _selectedCity!,
      );

      if (success && mounted) {
        CustomNotification.showSuccess(context,
            message:
                '✅ Selamat! Login dengan Facebook berhasil. Silakan login untuk melanjutkan');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.showError(context,
            message:
                '❌ Facebook login gagal: ${e.toString().split(':').last.trim()}');
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
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
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
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: label == 'Google'
                      ? const Color(0xFF4285F4)
                      : const Color(0xFF1877F2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1).animate(
                          CurvedAnimation(
                            parent: _scaleController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Daftar Akun Baru',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryDark,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bergabunglah dengan Buket.id sekarang',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            ScaleTransition(
                              scale: Tween<double>(begin: 0.9, end: 1).animate(
                                CurvedAnimation(
                                  parent: _slideController,
                                  curve: const Interval(0.1, 0.5,
                                      curve: Curves.easeOut),
                                ),
                              ),
                              child: CustomTextField(
                                hintText: 'Nama Lengkap',
                                label: 'Nama Lengkap',
                                prefixIcon: Icons.person_outline,
                                controller: _nameController,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Nama tidak boleh kosong';
                                  }
                                  if (value!.trim().length < 3) {
                                    return 'Nama minimal 3 karakter';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            ScaleTransition(
                              scale: Tween<double>(begin: 0.9, end: 1).animate(
                                CurvedAnimation(
                                  parent: _slideController,
                                  curve: const Interval(0.2, 0.6,
                                      curve: Curves.easeOut),
                                ),
                              ),
                              child: CustomTextField(
                                hintText: 'Email',
                                label: 'Email',
                                prefixIcon: Icons.email_outlined,
                                controller: _emailController,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Email tidak boleh kosong';
                                  }
                                  if (!value!.contains('@')) {
                                    return 'Email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            ScaleTransition(
                              scale: Tween<double>(begin: 0.9, end: 1).animate(
                                CurvedAnimation(
                                  parent: _slideController,
                                  curve: const Interval(0.3, 0.7,
                                      curve: Curves.easeOut),
                                ),
                              ),
                              child: CustomTextField(
                                hintText: 'Nomor Telepon',
                                label: 'Nomor Telepon',
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                controller: _phoneController,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Nomor telepon tidak boleh kosong';
                                  }
                                  if (value!.length < 10) {
                                    return 'Nomor telepon minimal 10 digit';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            ScaleTransition(
                              scale: Tween<double>(begin: 0.9, end: 1).animate(
                                CurvedAnimation(
                                  parent: _slideController,
                                  curve: const Interval(0.4, 0.8,
                                      curve: Curves.easeOut),
                                ),
                              ),
                              child: CustomDropdown(
                                hintText: 'Pilih Kota',
                                label: 'Pilih Kota',
                                prefixIcon: Icons.location_on_outlined,
                                items:
                                    _cities.map((city) => city.name).toList(),
                                value: _selectedCity,
                                onChanged: (value) {
                                  setState(() => _selectedCity = value);
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Pilih kota terlebih dahulu';
                                  }
                                  return null;
                                },
                                isCityPicker: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ScaleTransition(
                              scale: Tween<double>(begin: 0.9, end: 1).animate(
                                CurvedAnimation(
                                  parent: _slideController,
                                  curve: const Interval(0.5, 0.9,
                                      curve: Curves.easeOut),
                                ),
                              ),
                              child: CustomTextField(
                                hintText: 'Password',
                                label: 'Password',
                                prefixIcon: Icons.lock_outline,
                                controller: _passwordController,
                                isPassword: true,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Password tidak boleh kosong';
                                  }
                                  if (value!.length < 6) {
                                    return 'Password minimal 6 karakter';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            ScaleTransition(
                              scale: Tween<double>(begin: 0.9, end: 1).animate(
                                CurvedAnimation(
                                  parent: _slideController,
                                  curve: const Interval(0.6, 1.0,
                                      curve: Curves.easeOut),
                                ),
                              ),
                              child: CustomTextField(
                                hintText: 'Konfirmasi Password',
                                label: 'Konfirmasi Password',
                                prefixIcon: Icons.lock_outline,
                                controller: _confirmPasswordController,
                                isPassword: true,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Konfirmasi password tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            ScaleTransition(
                              scale: Tween<double>(begin: 0.9, end: 1).animate(
                                CurvedAnimation(
                                  parent: _slideController,
                                  curve: const Interval(0.7, 1.0,
                                      curve: Curves.easeOut),
                                ),
                              ),
                              child: PrimaryButton(
                                label: 'Daftar',
                                onPressed: _isLoading ? null : _handleRegister,
                                isLoading: _isLoading,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Social Login Buttons
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _slideController,
                            curve:
                                const Interval(0.6, 1.0, curve: Curves.easeOut),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: GoogleAuthButton(
                                isLoading: _isLoading,
                                isRegister: true,
                                onPressed: _handleGoogleLogin,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildEnhancedSocialButton(
                                label: 'Facebook',
                                logoBuilder: _buildFacebookLogo,
                                onPressed: _handleFacebookLogin,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Login Link
                      FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _fadeController,
                            curve:
                                const Interval(0.7, 1.0, curve: Curves.easeIn),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sudah punya akun? ',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Masuk',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
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
}
