import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Konstanta Warna (Ambil dari dashboard.dart)
const Color kPrimary = Color(0xFF004D40);
// ⚠️ GANTI IP INI DENGAN IP FLASK ANDA YANG AKTIF (misalnya: 192.168.1.26:5000)
// Karena log terakhir Anda menunjukkan IP 192.168.1.26
const String BASE_URL = 'http://192.168.1.26:5000'; 

// Model Data untuk menerima argumen dari Gallery/Dashboard
class ScanArguments {
  final int? destinationId;
  final String? destinationName;
  final Map<String, dynamic>? userData;

  ScanArguments({this.destinationId, this.destinationName, this.userData});
}

class ScanARPage extends StatefulWidget {
  const ScanARPage({super.key});

  @override
  _ScanARPageState createState() => _ScanARPageState();
}

class _ScanARPageState extends State<ScanARPage> {
  String _scanStatus = 'Tekan "Mulai Pindai" untuk mengaktifkan kamera.';
  bool _isScanning = false;
  
  // Data pengguna yang sedang login (disediakan oleh Dashboard)
  Map<String, dynamic>? _userData;
  
  // Data Scan yang berhasil (ID dan Nama Destinasi - untuk simulasi)
  int? _scannedDestinationId;
  String? _scannedDestinationName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mengambil data pengguna dari arguments yang dikirim Dashboard atau Gallery
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args is Map<String, dynamic>) {
      // Pemicu dari Tombol Kamera Tengah (hanya membawa Map userData)
      _userData = args;
      _scannedDestinationId = null; 
      _scannedDestinationName = null;
    } else if (args is ScanArguments) {
      // Pemicu dari Gallery (membawa info destinasi)
      _userData = args.userData;
      _scannedDestinationId = args.destinationId;
      _scannedDestinationName = args.destinationName;
    } 
  }

  // 1. FUNGSI UNTUK MENCATAT HISTORY KE FLASK (Action: scan_success)
  // Ini adalah pengganti logika scan_start/scan_end yang ada di ScanARPage.jsx
  Future<void> _recordScanSuccess(int destinationId, String destinationName) async {
    final int? userId = _userData?['user_id'] as int?;
    final String? userEmail = _userData?['email'] as String?;

    if (userId == null || userEmail == null || userId == 0) {
      setState(() {
        _scanStatus = 'Error: Data pengguna tidak valid. History gagal dicatat.';
      });
      return;
    }

    try {
      final response = await http.post(
          Uri.parse('$BASE_URL/api/history'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
              "user_id": userId,
              "user_email": userEmail,
              "destination_id": destinationId,
              "action": "scan_success", // 🎯 History dicatat saat sukses scan
              "model_type": "AR",
          }),
      );

      if (response.statusCode == 201) {
          setState(() {
            _scanStatus = 'Scan sukses: $destinationName. Riwayat berhasil dicatat!';
          });
      } else {
          final apiMessage = json.decode(response.body)['message'] ?? 'API error';
          setState(() {
            _scanStatus = 'Gagal mencatat riwayat. Pesan API: $apiMessage';
          });
      }
    } catch (e) {
      setState(() {
        _scanStatus = 'Error jaringan saat mencatat riwayat. $e';
      });
    }
  }

  // 2. LOGIKA SIMULASI PEMINDAIAN (GENERAL ATAU SPESIFIK)
  void _startScanning() {
    if (_userData == null) {
      setState(() {
        _scanStatus = 'Error: Harap login untuk memulai pemindaian.';
      });
      return;
    }
    
    setState(() {
        _isScanning = true;
    });

    // Simulasi: 3 detik untuk menemukan marker
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      // Kasus A: Dipicu dari Gallery (Spesifik)
      if (_scannedDestinationId != null && _scannedDestinationName != null) {
        _recordScanSuccess(_scannedDestinationId!, _scannedDestinationName!);
      } else {
        // Kasus B: Dipicu dari Tombol Tengah (General Scan)
        // Simulasi berhasil menemukan marker default (ID 5, Candi Borobudur)
        const int generalScanId = 5; 
        const String generalScanName = 'Candi Borobudur';
        _recordScanSuccess(generalScanId, generalScanName);
      }
      
      setState(() {
          _isScanning = false;
      });
    });

    setState(() {
        _scanStatus = (_scannedDestinationName != null) 
            ? 'Memindai marker spesifik: $_scannedDestinationName...'
            : 'Memindai marker umum (mode General Scan)...';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan AR', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Konten Simulasi Kamera
              Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white70, size: 80),
              ),
              
              const SizedBox(height: 30),
              
              // Tampilan Status Scan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _scanStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _scanStatus.contains('Error') ? Colors.red : kPrimary,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),

              // Tombol Mulai/Scanning
              _isScanning
                  ? const CircularProgressIndicator(color: kPrimary)
                  : ElevatedButton.icon(
                      onPressed: _startScanning,
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      label: const Text('Mulai Pindai Marker', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}