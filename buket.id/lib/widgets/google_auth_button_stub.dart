import 'package:flutter/material.dart';

Widget buildGoogleAuthButton({
  required bool isLoading,
  required bool isRegister,
  required VoidCallback onPressed,
}) {
  return OutlinedButton.icon(
    onPressed: isLoading ? null : onPressed,
    icon: const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
    label:
        Text(isRegister ? 'Daftar dengan Google' : 'Lanjutkan dengan Google'),
  );
}
