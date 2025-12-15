import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'register.dart';
import 'dashboard.dart';
import 'ARGalleryPage.dart';
import 'ScanARPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi SharedPreferences
  await SharedPreferences.getInstance();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oratorio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004D40)),
        useMaterial3: true,
      ),
      initialRoute: '/login', 
      routes: {
        '/login': (ctx) => const LoginPage(),
        '/register': (ctx) => const RegisterPage(),
        '/dashboard': (ctx) => const DashboardPage(),
        '/argallery': (ctx) => const ARGalleryPage(),
        '/scan': (ctx) => const ScanARPage(),
        '/arview': (ctx) => const ARViewPage(),
      },
    );
  }
}