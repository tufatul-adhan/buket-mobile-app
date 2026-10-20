import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'config/app_theme.dart';
import 'screens/index.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // SQLite and path_provider are native plugins. The web app uses the API
  // backend (PostgreSQL), so initializing the local database on web causes a
  // MissingPluginException before authentication can complete.
  if (!kIsWeb) {
    try {
      final dbService = DatabaseService();
      await dbService.database;
    } catch (e) {
      debugPrint('Database init error: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buket.id',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
