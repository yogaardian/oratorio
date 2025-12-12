import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

String resolveApiBaseScan(String configured) {
  if (Platform.isAndroid) {
    if (configured.contains('localhost') || configured.contains('127.0.0.1')) {
      return 'http://10.0.2.2:5000';
    }
  }
  return configured;
}

class ScanARPage extends StatefulWidget {
  const ScanARPage({super.key});

  @override
  State<ScanARPage> createState() => _ScanARPageState();
}

class _ScanARPageState extends State<ScanARPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _scanning = false;
  DateTime? _scanStart;
  final String apiBase = resolveApiBaseScan('http://192.168.23.214:5000');

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(_cameras!.first, ResolutionPreset.medium, enableAudio: false);
        await _controller!.initialize();
        setState(() { _isInitialized = true; });
      }
    } catch (e) {
      // If initialization fails (likely due to missing permission), show guidance
      if (mounted) {
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('Camera Unavailable'),
          content: const Text('Camera could not be initialized. Please ensure the app has camera permission in system settings.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ));
      }
    }
  }

  Future<void> _captureAndRecognize(Map<String, dynamic>? args) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_scanning) return;
    setState(() { _scanning = true; });

    final start = DateTime.now();
    final XFile file = await _controller!.takePicture();
    final uri = Uri.parse('$apiBase/api/recognize');

    try {
      final req = http.MultipartRequest('POST', uri);
      req.files.add(await http.MultipartFile.fromPath('image', file.path));
      // optionally send expected destination id passed from args
      if (args != null && args['id'] != null) req.fields['expected_id'] = args['id'].toString();
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body) as Map<String, dynamic>;
        final matched = body['matched'] == true;
        final destinationId = body['destination_id'] ?? args?['id'];
        final end = DateTime.now();
        final duration = end.difference(start).inSeconds;

        // post history -> scan_end
        await http.post(Uri.parse('$apiBase/api/history'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'destination_id': destinationId,
            'action': matched ? 'scan_end' : 'scan_failed',
            'started_at': start.toUtc().toIso8601String(),
            'ended_at': end.toUtc().toIso8601String(),
            'duration_seconds': duration,
          }),
        );

        if (matched) {
          if (!mounted) return;
          showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Berhasil'), content: const Text('Marker terdeteksi!'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marker tidak terdeteksi')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghubungi server')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saat scanning')));
    } finally {
      setState(() { _scanning = false; });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return Scaffold(
      appBar: AppBar(title: Text(args?['name'] ?? 'Scan AR'), backgroundColor: const Color(0xFF005954)),
      body: Column(
        children: [
          Expanded(
            child: _isInitialized && _controller != null
                ? CameraPreview(_controller!)
                : const Center(child: Text('Camera not available')),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scanning ? null : () async {
                      // when opening page we can send scan_start to history
                      final start = DateTime.now();
                      try {
                        await http.post(Uri.parse('$apiBase/api/history'), headers: {'Content-Type':'application/json'}, body: json.encode({
                          'destination_id': args?['id'],
                          'action': 'scan_start',
                          'started_at': start.toUtc().toIso8601String(),
                        }));
                      } catch (_) {}
                      await _captureAndRecognize(args);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_scanning ? 'Scanning...' : 'Scan Marker'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005954)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
