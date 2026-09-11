import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'presentation/home_screen.dart';
import 'presentation/login_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cloibccvjophbgybklut.supabase.co',
    publishableKey: 'sb_publishable_2MGV36gT3YY6aLlnFpBqQA_oe6ZE2fJ',
  );

  await StorageService.init();

  runApp(const GarbageDetectionApp());
}

class GarbageDetectionApp extends StatelessWidget {
  const GarbageDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Garbage Detection',

      themeMode: ThemeMode.system,

      // =========================
      // LIGHT THEME
      // =========================
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        colorScheme: const ColorScheme.light(
          primary: Color(0xFF256D3F),
          onPrimary: Colors.white,

          primaryContainer: Color(0xFFE0F0E5),
          onPrimaryContainer: Color(0xFF183C28),

          secondary: Color(0xFF4CAF70),
          onSecondary: Colors.white,

          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF183C28),

          surfaceContainerHighest: Color(0xFFEFF4F0),

          error: Color(0xFFBA1A1A),
          onError: Colors.white,
        ),

        scaffoldBackgroundColor: const Color(0xFFF5F8F5),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF183C28),
          elevation: 0,
        ),

        cardTheme: const CardThemeData(color: Colors.white, elevation: 0),
      ),

      // =========================
      // DARK THEME
      // =========================
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF65C98A),
          onPrimary: Color(0xFF00391B),

          primaryContainer: Color(0xFF1F4D32),
          onPrimaryContainer: Color(0xFFB9F5C8),

          secondary: Color(0xFF8ED5A5),
          onSecondary: Color(0xFF00391B),

          surface: Color(0xFF18221C),
          onSurface: Color(0xFFF1F7F3),

          surfaceContainerHighest: Color(0xFF26352C),

          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
        ),

        scaffoldBackgroundColor: const Color(0xFF0F1712),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFF1F7F3),
          elevation: 0,
        ),

        cardTheme: const CardThemeData(color: Color(0xFF18221C), elevation: 0),
      ),

      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _loginStatus;

  @override
  void initState() {
    super.initState();
    _loginStatus = AuthService.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _loginStatus,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF256D3F)),
            ),
          );
        }

        if (snapshot.data == true) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
