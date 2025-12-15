import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Konstanta Warna
const Color kPrimary = Color(0xFF004D40);
const String BASE_URL = 'http://192.168.1.26:5000';

// Model Data untuk menerima argumen dari Gallery/Dashboard
class ScanArguments {
  final int? destinationId;
  final String? destinationName;
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? destinationData;
  final String? jwtToken;

  ScanArguments({
    this.destinationId,
    this.destinationName,
    this.userData,
    this.destinationData,
    this.jwtToken,
  });
}

class ScanARPage extends StatefulWidget {
  const ScanARPage({super.key});

  @override
  _ScanARPageState createState() => _ScanARPageState();
}

class _ScanARPageState extends State<ScanARPage> with WidgetsBindingObserver {
  String _scanStatus = 'Tekan "Mulai Pindai" untuk mengaktifkan kamera.';
  bool _isScanning = false;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _destinationData;
  String? _jwtToken;
  int? _scannedDestinationId;
  String? _scannedDestinationName;
  
  // Variabel untuk kamera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('🚀 ScanARPage: Initialized');
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraController != null) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Dapatkan daftar kamera yang tersedia
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        print('⚠️ Tidak ada kamera tersedia');
        setState(() {
          _scanStatus = '❌ Tidak ada kamera tersedia di perangkat ini.';
        });
        return;
      }
      
      // Gunakan kamera belakang (rear camera)
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium, // Ubah ke medium untuk performa lebih baik
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraPermissionGranted = true;
          _scanStatus = 'Kamera siap. Tekan "Mulai Pindai" untuk memindai marker.';
        });
      }
      
      print('✅ Kamera berhasil diinisialisasi');
      
    } on CameraException catch (e) {
      print('❌ Camera Exception: $e');
      _handleCameraError(e);
    } catch (e) {
      print('❌ Error inisialisasi kamera: $e');
      _handleCameraError(null, e.toString());
    }
  }

  void _handleCameraError([CameraException? e, String? customMessage]) {
    String errorMessage;
    
    if (e != null) {
      switch (e.code) {
        case 'CameraAccessDenied':
          errorMessage = 'Izin kamera ditolak. Harap aktifkan izin kamera di pengaturan.';
          break;
        case 'CameraAccessRestricted':
          errorMessage = 'Akses kamera dibatasi.';
          break;
        default:
          errorMessage = 'Error kamera: ${e.description ?? e.code}';
      }
    } else {
      errorMessage = customMessage ?? 'Error tidak diketahui saat mengakses kamera.';
    }
    
    if (mounted) {
      setState(() {
        _scanStatus = '❌ $errorMessage';
        _isCameraInitialized = false;
      });
    }
  }

  void _disposeCamera() {
    if (_cameraController != null) {
      _cameraController!.dispose();
      _cameraController = null;
    }
    _isCameraInitialized = false;
  }

  Future<bool> _startCamera() async {
    if (_isCameraInitialized) {
      return true;
    }
    
    if (_cameraController == null) {
      await _initializeCamera();
    } else if (!_cameraController!.value.isInitialized) {
      try {
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _scanStatus = 'Kamera siap. Tekan "Mulai Pindai" untuk memindai marker.';
          });
        }
      } catch (e) {
        print('❌ Gagal memulai kamera: $e');
        setState(() {
          _scanStatus = '❌ Gagal memulai kamera: $e';
        });
        return false;
      }
    }
    
    return _isCameraInitialized;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parseArguments();
  }

  Future<void> _parseArguments() async {
    print('🚀 ScanARPage: Parsing arguments...');
    
    final args = ModalRoute.of(context)?.settings.arguments;
    print('📱 Arguments received: $args');
    
    // Reset state
    _userData = null;
    _destinationData = null;
    _scannedDestinationId = null;
    _scannedDestinationName = null;
    
    if (args != null) {
      if (args is Map<String, dynamic>) {
        _userData = args;
        print('✅ ScanARPage: Data dari Dashboard');
      } 
      else if (args is ScanArguments) {
        print('✅ ScanARPage: Data dari ARGallery (ScanArguments)');
        
        _userData = args.userData;
        _destinationData = args.destinationData;
        _jwtToken = args.jwtToken;
        
        if (_destinationData != null) {
          _scannedDestinationId = _destinationData?['id'] as int?;
          _scannedDestinationName = _destinationData?['name'] as String?;
        }
      }
    }
    
    if (_userData == null || _userData!.isEmpty) {
      await _loadUserDataFromSharedPreferences();
    }
    
    print('📊 ScanARPage Final Data:');
    print('   UserData: $_userData');
    print('   Destination ID: $_scannedDestinationId');
    print('   Destination Name: $_scannedDestinationName');
  }

  Future<void> _loadUserDataFromSharedPreferences() async {
    print('🔄 ScanARPage: Loading user data from SharedPreferences...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final userId = prefs.getInt('user_id');
      final email = prefs.getString('email');
      final username = prefs.getString('username');
      final jwtToken = prefs.getString('jwt_token');
      
      if (userId != null && email != null) {
        setState(() {
          _userData = {
            'user_id': userId,
            'email': email,
            'username': username ?? 'Pengguna',
            'jwt_token': jwtToken,
          };
        });
        print('✅ ScanARPage: User data loaded from SharedPreferences');
      }
    } catch (e) {
      print('❌ ScanARPage: Error loading from SharedPreferences: $e');
    }
  }

  Future<void> _recordScanSuccess(int destinationId, String destinationName) async {
    print('📝 ScanARPage: Recording scan history...');
    
    int? userId = _userData?['user_id'] as int?;
    String? userEmail = _userData?['email'] as String?;
    
    if (userId == null || userEmail == null || userId == 0) {
      setState(() {
        _scanStatus = '❌ Error: Data pengguna tidak valid. History gagal dicatat.';
      });
      return;
    }

    try {
      final Map<String, dynamic> requestBody = {
        "user_id": userId,
        "destination_id": destinationId,
        "action": "scan_success",
        "model_type": "AR",
      };
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      final String? token = _jwtToken ?? _userData?['jwt_token'];
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.post(
        Uri.parse('$BASE_URL/api/history'),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 5));

      print('📥 Response Status: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _scanStatus = '✅ Scan sukses: $destinationName. Riwayat berhasil dicatat!';
        });
        
        // Delay sebelum reset status
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted) {
          setState(() {
            _scanStatus = 'Kamera siap. Tekan "Mulai Pindai" untuk memindai marker.';
          });
        }
      } else {
        setState(() {
          _scanStatus = '❌ Gagal mencatat riwayat. Status: ${response.statusCode}';
        });
      }
    } on TimeoutException catch (_) {
      setState(() {
        _scanStatus = '❌ Waktu permintaan habis. Server tidak merespons.';
      });
    } catch (e) {
      print('❌ ScanARPage: Network Error: $e');
      setState(() {
        _scanStatus = '❌ Error jaringan: $e';
      });
    }
  }

  Future<bool> _checkServerConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/api/wisata'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode < 500;
    } catch (e) {
      return false;
    }
  }

  Future<void> _startScanning() async {
    print('🎬 ScanARPage: Start scanning triggered');
    
    if (_userData == null || _userData!.isEmpty) {
      setState(() {
        _scanStatus = '❌ Error: Data pengguna tidak ditemukan. Harap login ulang.';
      });
      return;
    }
    
    final userId = _userData?['user_id'];
    final userEmail = _userData?['email'];
    
    if (userId == null || userEmail == null) {
      setState(() {
        _scanStatus = '❌ Error: Data pengguna tidak lengkap. Harap login ulang.';
      });
      return;
    }
    
    // Jika kamera belum aktif, aktifkan dulu
    if (!_isCameraInitialized) {
      setState(() {
        _scanStatus = '🔄 Mengaktifkan kamera...';
      });
      
      final cameraStarted = await _startCamera();
      if (!cameraStarted) {
        setState(() {
          _scanStatus = '❌ Kamera belum siap. Harap izinkan akses kamera.';
        });
        return;
      }
    }
    
    // Cek koneksi server
    final isServerConnected = await _checkServerConnection();
    if (!isServerConnected) {
      setState(() {
        _scanStatus = '❌ Tidak dapat terhubung ke server. Periksa jaringan.';
      });
      return;
    }
    
    setState(() {
      _isScanning = true;
    });

    // Tentukan destination
    int destinationId;
    String destinationName;
    
    if (_scannedDestinationId != null && _scannedDestinationName != null) {
      destinationId = _scannedDestinationId!;
      destinationName = _scannedDestinationName!;
      setState(() {
        _scanStatus = '🔍 Memindai marker spesifik: $destinationName...';
      });
    } else {
      destinationId = 5; 
      destinationName = 'Candi Borobudur';
      setState(() {
        _scanStatus = '🔍 Memindai marker umum (mode General Scan)...';
      });
    }

    // Simulasi proses scanning dengan kamera aktif
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    // Catat history
    await _recordScanSuccess(destinationId, destinationName);
    
    setState(() {
      _isScanning = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan AR', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Informasi Login
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color.fromARGB(255, 202, 184, 184)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info, color: kPrimary, size: 18),
                    SizedBox(width: 8),
                    Text('Informasi Login:', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary)
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _userData?['username'] ?? 'Belum login',
                      style: TextStyle(
                        color: _userData != null ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _userData?['email'] ?? 'Email tidak tersedia',
                      style: TextStyle(
                        color: _userData != null ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _scannedDestinationName ?? 'General Scan',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Kamera Preview
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    // Kamera Preview
                    if (_isCameraInitialized && _cameraController != null)
                      CameraPreview(_cameraController!)
                    else
                      Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt, color: Colors.white70, size: 80),
                              const SizedBox(height: 20),
                              Text(
                                _scanStatus,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (!_isCameraInitialized && !_scanStatus.contains('Error'))
                                ElevatedButton(
                                  onPressed: _initializeCamera,
                                  child: const Text('Aktifkan Kamera'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Overlay saat scanning
                    if (_isScanning)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.7),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(color: Colors.white),
                                const SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    _scanStatus,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white, 
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    // Overlay untuk panduan scanning
                    if (!_isScanning && _isCameraInitialized)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.8),
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.qr_code_scanner,
                                    color: Colors.green.withOpacity(0.8),
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Status Scan dan Tombol
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _scanStatus.contains('❌') 
                        ? Colors.red[50]
                        : _scanStatus.contains('✅')
                          ? Colors.green[50]
                          : Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _scanStatus.contains('❌') 
                          ? Colors.red
                          : _scanStatus.contains('✅')
                            ? Colors.green
                            : Colors.blue,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _scanStatus.contains('❌') 
                            ? Icons.error
                            : _scanStatus.contains('✅')
                              ? Icons.check_circle
                              : Icons.info,
                        color: _scanStatus.contains('❌') 
                            ? Colors.red
                            : _scanStatus.contains('✅')
                              ? Colors.green
                              : Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _scanStatus,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _scanStatus.contains('❌') 
                                ? Colors.red[800]
                                : _scanStatus.contains('✅')
                                  ? Colors.green[800]
                                  : Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // Tombol Mulai/Scanning
                if (!_isScanning)
                  ElevatedButton.icon(
                    onPressed: _userData != null ? _startScanning : null,
                    icon: Icon(
                      _isCameraInitialized 
                          ? Icons.qr_code_scanner 
                          : Icons.camera_alt,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isCameraInitialized 
                          ? 'Mulai Pindai Marker' 
                          : 'Aktifkan Kamera Dulu',
                      style: const TextStyle(color: Colors.white, fontSize: 16)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _userData != null && _isCameraInitialized 
                          ? kPrimary 
                          : Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30, 
                        vertical: 15
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                
                if (_isScanning)
                  Column(
                    children: [
                      const CircularProgressIndicator(color: kPrimary),
                      const SizedBox(height: 10),
                      Text(
                        'Memindai...',
                        style: TextStyle(
                          color: kPrimary, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 10),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Kembali'),
                    ),
                    
                    if (_isCameraInitialized)
                      TextButton.icon(
                        onPressed: () {
                          _disposeCamera();
                          _initializeCamera();
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Restart Kamera'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}