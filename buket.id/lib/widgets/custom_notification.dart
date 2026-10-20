import 'package:flutter/material.dart';

class CustomNotification {
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showNotification(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: const Color(0xFF4CAF50),
      duration: duration,
      type: NotificationType.success,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showNotification(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: const Color(0xFFEF5350),
      duration: duration,
      type: NotificationType.error,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showNotification(
      context,
      message: message,
      icon: Icons.warning_amber_outlined,
      backgroundColor: const Color(0xFFFFA726),
      duration: duration,
      type: NotificationType.warning,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showNotification(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: const Color(0xFF42A5F5),
      duration: duration,
      type: NotificationType.info,
    );
  }

  static void _showNotification(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
    required NotificationType type,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20,
        left: isMobile ? 16 : 24,
        right: isMobile ? 16 : 24,
        child: Material(
          color: Colors.transparent,
          child: _NotificationWidget(
            message: message,
            icon: icon,
            backgroundColor: backgroundColor,
            onClose: () => overlayEntry.remove(),
            type: type,
            duration: duration,
            isMobile: isMobile,
            onExpired: () {
              if (overlayEntry.mounted) {
                overlayEntry.remove();
              }
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }
}

enum NotificationType { success, error, warning, info }

class _NotificationWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onClose;
  final NotificationType type;
  final Duration duration;
  final bool isMobile;
  final VoidCallback onExpired;

  const _NotificationWidget({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.onClose,
    required this.type,
    required this.duration,
    required this.isMobile,
    required this.onExpired,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _progressController;
  late AnimationController _iconController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Slide animation untuk entrance
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -100),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );

    // Icon animation untuk bounce
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    // Progress bar animation
    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Mulai animasi
    _slideController.forward();
    _iconController.forward();
    _progressController.forward().then((_) {
      widget.onExpired();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: MouseRegion(
          onEnter: (_) {
            _progressController.stop();
          },
          onExit: (_) {
            _progressController.forward();
          },
          child: Container(
            constraints: BoxConstraints(
              maxWidth: widget.isMobile ? double.infinity : 520,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: widget.backgroundColor.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
              border: Border(
                left: BorderSide(
                  color: widget.backgroundColor,
                  width: 4,
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main notification content
                  Padding(
                    padding: EdgeInsets.all(widget.isMobile ? 14 : 16),
                    child: Row(
                      children: [
                        // Animated icon container
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: RotationTransition(
                            turns: _rotateAnimation,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.backgroundColor
                                        .withValues(alpha: 0.12),
                                    widget.backgroundColor
                                        .withValues(alpha: 0.06),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.backgroundColor
                                      .withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  widget.icon,
                                  color: widget.backgroundColor,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: widget.isMobile ? 12 : 14),
                        // Message text with better typography
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getTitle(widget.type),
                                style: TextStyle(
                                  color: widget.backgroundColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: widget.isMobile ? 13 : 14,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.message,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                  fontSize: widget.isMobile ? 12 : 13,
                                  height: 1.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: widget.isMobile ? 10 : 12),
                        // Close button dengan hover effect
                        GestureDetector(
                          onTap: widget.onClose,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.grey.shade500,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Animated progress bar dengan gradient
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                        ),
                        child: Stack(
                          children: [
                            Container(
                              height: 3,
                              width: MediaQuery.of(context).size.width *
                                  _progressController.value,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.backgroundColor,
                                    widget.backgroundColor
                                        .withValues(alpha: 0.7),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return 'Berhasil';
      case NotificationType.error:
        return 'Gagal';
      case NotificationType.warning:
        return 'Perhatian';
      case NotificationType.info:
        return 'Informasi';
    }
  }
}
