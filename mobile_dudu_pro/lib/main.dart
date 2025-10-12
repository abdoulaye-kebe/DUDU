import 'package:flutter/material.dart';
import 'screens/driver_dashboard_screen.dart';

void main() {
  runApp(const DUDUProApp());
}

class DUDUProApp extends StatelessWidget {
  const DUDUProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DUDU Pro - Chauffeurs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A651),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00A651),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const DriverDashboardScreen(),
    );
  }
}
