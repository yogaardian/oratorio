import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Untuk Duration

// Konstanta Warna (Ambil dari login.dart untuk konsistensi)
const Color kPrimary = Color(0xFF004D40);
const String BASE_URL = 'http://192.168.1.26:5000'; // GANTI dengan IP Flask Anda yang benar

// Model Data untuk Riwayat Aktivitas
class HistoryItem {
  final int historyId;
  final String userEmail;
  final String action;
  final String destinationName;
  final DateTime startedAt;

  HistoryItem({
    required this.historyId,
    required this.userEmail,
    required this.action,
    required this.destinationName,
    required this.startedAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      historyId: json['history_id'] as int,
      userEmail: json['user_email'] as String,
      action: json['action'] as String,
      destinationName: json['destination_name'] as String? ?? 'Destinasi Tidak Dikenal',
      // Konversi string tanggal/waktu dari MySQL ke DateTime
      startedAt: DateTime.parse(json['started_at'] as String), 
    );
  }
}

class HistoryPage extends StatefulWidget {
  // Menerima data pengguna dari DashboardPage
  final Map<String, dynamic>? userData;
  
  const HistoryPage({super.key, this.userData});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoryItem> _historyList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // 1. FUNGSI FETCH DATA DARI FLASK API
  Future<void> _fetchHistory() async {
    final int? userId = widget.userData?['user_id'] as int?;

    if (userId == null || userId == 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = "User ID tidak tersedia. Harap login ulang.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final url = Uri.parse('$BASE_URL/api/history/user/$userId');
    
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _historyList = data.map((item) => HistoryItem.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        final apiMessage = json.decode(response.body)['message'] ?? 'Gagal memuat riwayat.';
        setState(() {
          _isLoading = false;
          _errorMessage = "Error ${response.statusCode}: $apiMessage";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal koneksi server: Pastikan API berjalan. $e';
      });
    }
  }

  // 2. BUILD WIDGET UTAMA
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas AR Anda', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  // 3. LOGIKA TAMPILAN (Loading, Error, Data Kosong, Data)
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 10),
              Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchHistory,
                child: const Text('Coba Muat Ulang'),
              ),
            ],
          ),
        ),
      );
    }

    if (_historyList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off, color: Colors.grey, size: 60),
            const SizedBox(height: 10),
            const Text('Belum ada riwayat aktivitas.', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchHistory,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // 4. TAMPILAN DATA RIWAYAT (ListView)
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _historyList.length,
      itemBuilder: (context, index) {
        final item = _historyList[index];
        return _HistoryCard(item: item);
      },
    );
  }
}

// 5. WIDGET CARD UNTUK SETIAP RIWAYAT
class _HistoryCard extends StatelessWidget {
  final HistoryItem item;

  const _HistoryCard({required this.item});
  
  // Helper untuk format tanggal
  String _formatDateTime(DateTime dt) {
    final date = '${dt.day}/${dt.month}/${dt.year}';
    final time = '${dt.hour}:${dt.minute}';
    return '$date, $time WIB';
  }

  // Helper untuk mendapatkan ikon berdasarkan aksi
  IconData _getIcon(String action) {
    if (action.contains('success')) return Icons.check_circle_outline;
    if (action.contains('scan')) return Icons.qr_code_scanner;
    return Icons.history;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(_getIcon(item.action), color: kPrimary, size: 30),
        title: Text(
          item.destinationName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('Aksi: ${item.action.toUpperCase()}'),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_formatDateTime(item.startedAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            // Text(item.userEmail, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ],
        ),
        onTap: () {
          // Aksi opsional: Tampilkan detail riwayat
        },
      ),
    );
  }
}