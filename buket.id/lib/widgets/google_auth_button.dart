import 'package:flutter/material.dart';

import 'google_auth_button_stub.dart'
    if (dart.library.js_interop) 'google_auth_button_web.dart' as platform;

class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({
    super.key,
    required this.isLoading,
    required this.isRegister,
    required this.onPressed,
  });

  final bool isLoading;
  final bool isRegister;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return platform.buildGoogleAuthButton(
      isLoading: isLoading,
      isRegister: isRegister,
      onPressed: onPressed,
    );
  }
}
