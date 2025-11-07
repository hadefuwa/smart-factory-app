import 'package:flutter/material.dart';
import 'screens/smart_factory_main.dart';
import 'screens/sf_settings_screen.dart';
import 'widgets/splash_screen.dart';

void main() {
  runApp(const SmartFactoryApp());
}

class SmartFactoryApp extends StatelessWidget {
  const SmartFactoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Factory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C27B0), // Purple
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        cardTheme: CardThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: const Color(0xFF1A1A2E),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF0F0F1E),
          foregroundColor: Color(0xFFE0B0FF),
        ),
      ),
      themeMode: ThemeMode.dark, // Force dark mode
      home: const SplashWrapper(),
      routes: {
        '/home': (context) => const SmartFactoryMain(),
        '/settings': (context) => const SFSettingsScreen(),
      },
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper>
    with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );
  }

  void _onSplashComplete() {
    _fadeController.forward().then((_) {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SplashScreen(onAnimationComplete: _onSplashComplete),
      );
    }
    return const SmartFactoryMain();
  }
}
