import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_auth_config.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final StreamController<String> _idTokens = StreamController.broadcast();
  Future<void>? _initialization;
  bool _initialized = false;

  Stream<String> get idTokens => _idTokens.stream;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (googleWebClientId.isEmpty) {
      throw Exception(
        'OAuth Google belum dikonfigurasi. Isi Web Client ID pada aplikasi dan backend.',
      );
    }

    await _googleSignIn.initialize(
      clientId: null,
      serverClientId: kIsWeb ? null : googleWebClientId,
    );
    _initialized = true;
    _googleSignIn.authenticationEvents.listen(
      (event) {
        if (kIsWeb && event is GoogleSignInAuthenticationEventSignIn) {
          final idToken = event.user.authentication.idToken;
          if (idToken == null || idToken.isEmpty) {
            _idTokens.addError(Exception('Google tidak memberikan ID token.'));
          } else {
            _idTokens.add(idToken);
          }
        }
      },
      onError: _idTokens.addError,
    );
  }

  Future<String?> signIn() async {
    await initialize();
    if (kIsWeb) return null;

    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google tidak memberikan ID token.');
    }
    return idToken;
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    await _googleSignIn.signOut();
  }
}
