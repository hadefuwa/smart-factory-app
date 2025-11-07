import 'package:flutter/material.dart';
import 'sf_home_screen.dart';
import 'sf_run_screen.dart';
import 'sf_io_screen.dart';
import 'sf_worksheets_screen.dart';
import 'sf_analytics_screen.dart';
import '../widgets/app_drawer.dart';

class SmartFactoryMain extends StatefulWidget {
  const SmartFactoryMain({super.key});

  @override
  State<SmartFactoryMain> createState() => _SmartFactoryMainState();
}

class _SmartFactoryMainState extends State<SmartFactoryMain> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const SFHomeScreen(),
    const SFRunScreen(),
    const SFIOScreen(),
    const SFWorksheetsScreen(),
    const SFAnalyticsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F0F1E),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.white.withValues(alpha: 0.6),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow),
            label: 'Run',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cable),
            label: 'I/O',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Worksheets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
