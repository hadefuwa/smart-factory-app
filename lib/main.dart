import 'package:flutter/material.dart';
import 'screens/products_list_screen.dart';

void main() {
  runApp(const MatrixApp());
}

class MatrixApp extends StatelessWidget {
  const MatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matrix TSL',
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
      home: const ProductsListScreen(),
    );
  }
}
