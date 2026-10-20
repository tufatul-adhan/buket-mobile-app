import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart';

Widget buildGoogleAuthButton({
  required bool isLoading,
  required bool isRegister,
  required VoidCallback onPressed,
}) {
  if (isLoading) {
    return const SizedBox(
      height: 44,
      child: Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  return SizedBox(
    height: 44,
    child: renderButton(
      configuration: GSIButtonConfiguration(
        type: GSIButtonType.standard,
        theme: GSIButtonTheme.outline,
        size: GSIButtonSize.large,
        text: isRegister ? GSIButtonText.signupWith : GSIButtonText.signinWith,
        shape: GSIButtonShape.rectangular,
        minimumWidth: 150,
        locale: 'id',
      ),
    ),
  );
}
