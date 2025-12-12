import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';
import 'dashboard.dart'; // Pastikan file dashboard.dart sudah tersedia
import 'ARGalleryPage.dart';
import 'ScanARPage.dart';

// Asumsi: LoginPage dan RegisterPage didefinisikan sebagai StatelessWidget atau StatefulWidget 
// di file 'login.dart' dan 'register.dart'.

void main() {
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
                // Penggunaan 'const' di sini sudah tepat.
                '/login': (ctx) => const LoginPage(),
                // Asumsi RegisterPage sudah ada
                '/register': (ctx) => const RegisterPage(), 
                
                // Asumsi DashboardPage sudah ada
                '/dashboard': (ctx) => const DashboardPage(), 
                // AR Gallery
                '/argallery': (ctx) => const ARGalleryPage(),
                '/scan': (ctx) => const ScanARPage(),
                '/arview': (ctx) => const ARViewPage(),
            },
        );
    }
}