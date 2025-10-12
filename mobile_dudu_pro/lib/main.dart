import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'screens/driver_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const DUDUProApp());
}

class DUDUProApp extends StatelessWidget {
  const DUDUProApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DUDU Pro - Chauffeur',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00A651),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A651),
          primary: const Color(0xFF00A651),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
