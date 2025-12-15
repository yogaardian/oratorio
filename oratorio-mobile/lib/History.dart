import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Konstanta Warna
const Color kPrimary = Color(0xFF004D40);
const String BASE_URL = 'http://192.168.1.26:5000';

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
      startedAt: DateTime.parse(json['started_at'] as String), 
    );
  }
}

class HistoryPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const HistoryPage({super.key, this.userData});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoryItem> _historyList = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    
    // Listen untuk event refresh jika ada
    // WidgetsBinding.instance.addObserver(this);
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   // Refresh saat kembali ke halaman ini
  //   _fetchHistory();
  // }

  // @override
  // void dispose() {
  //   WidgetsBinding.instance.removeObserver(this);
  //   super.dispose();
  // }

  // @override
  // void didUpdateWidget(HistoryPage oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   // Refresh data jika widget berubah (misalnya dari navigasi)
  //   if (widget.userData != oldWidget.userData) {
  //     _fetchHistory();
  //   }
  // }

  // Refresh dengan pull-to-refresh
  Future<void> _refreshHistory() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    await _fetchHistory();
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  // 1. FUNGSI FETCH DATA DARI FLASK API
  Future<void> _fetchHistory() async {
    print('🔄 HistoryPage: Fetching history data...');
    
    final int? userId = widget.userData?['user_id'] as int?;

    if (userId == null || userId == 0) {
      print('⚠️ HistoryPage: User ID tidak tersedia');
      setState(() {
        _isLoading = false;
        _errorMessage = "User ID tidak tersedia. Harap login ulang.";
      });
      return;
    }

    print('📊 HistoryPage: User ID: $userId');

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final url = Uri.parse('$BASE_URL/api/history/user/$userId');
    print('🌐 HistoryPage: Fetching from URL: $url');
    
    try {
      final response = await http.get(url);
      print('📥 HistoryPage: Response status: ${response.statusCode}');
      print('📥 HistoryPage: Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          print('✅ HistoryPage: Data parsed, count: ${data.length}');
          
          // Debug: print semua data
          for (var item in data) {
            print('   - ${item['history_id']}: ${item['destination_name']}');
          }
          
          setState(() {
            _historyList = data.map((item) => HistoryItem.fromJson(item)).toList();
            _isLoading = false;
          });
        } catch (e) {
          print('❌ HistoryPage: JSON Parse Error: $e');
          setState(() {
            _isLoading = false;
            _errorMessage = 'Format data tidak valid: $e';
          });
        }
      } else {
        print('❌ HistoryPage: HTTP Error ${response.statusCode}');
        String apiMessage;
        try {
          final errorData = json.decode(response.body);
          apiMessage = errorData['message'] ?? errorData['error'] ?? 'Gagal memuat riwayat.';
        } catch (_) {
          apiMessage = 'Gagal memuat riwayat (Status: ${response.statusCode})';
        }
        
        setState(() {
          _isLoading = false;
          _errorMessage = "Error ${response.statusCode}: $apiMessage";
        });
      }
    } catch (e) {
      print('❌ HistoryPage: Network Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal koneksi server: $e\nPastikan API berjalan di $BASE_URL';
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
        actions: [
          // Tombol refresh di AppBar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // 3. LOGIKA TAMPILAN
  Widget _buildBody() {
    if (_isLoading && !_isRefreshing) {
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

    // Gunakan RefreshIndicator untuk pull-to-refresh
    return RefreshIndicator(
      onRefresh: _refreshHistory,
      child: _historyList.isEmpty
          ? Center(
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
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _historyList.length,
              itemBuilder: (context, index) {
                final item = _historyList[index];
                return _HistoryCard(item: item);
              },
            ),
    );
  }
}

// 4. WIDGET CARD UNTUK SETIAP RIWAYAT
class _HistoryCard extends StatelessWidget {
  final HistoryItem item;

  const _HistoryCard({required this.item});
  
  String _formatDateTime(DateTime dt) {
    final date = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date, $time WIB';
  }

  IconData _getIcon(String action) {
    if (action.contains('success')) return Icons.check_circle_outline;
    if (action.contains('scan')) return Icons.qr_code_scanner;
    if (action.contains('view')) return Icons.visibility;
    return Icons.history;
  }

  Color _getIconColor(String action) {
    if (action.contains('success')) return Colors.green;
    if (action.contains('fail') || action.contains('error')) return Colors.red;
    return kPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          // Tampilkan detail
          _showHistoryDetails(context, item);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon dengan background circle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getIconColor(item.action).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(item.action),
                  color: _getIconColor(item.action),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informasi riwayat
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.destinationName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      'Aksi: ${item.action.replaceAll('_', ' ').toUpperCase()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        const Icon(Icons.email, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          item.userEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Waktu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDateTime(item.startedAt).split(',')[0],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatDateTime(item.startedAt).split(',')[1].trim(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryDetails(BuildContext context, HistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Riwayat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailRow(icon: Icons.location_on, text: item.destinationName),
            const SizedBox(height: 8),
            DetailRow(icon: Icons.play_arrow, text: 'Aksi: ${item.action}'),
            const SizedBox(height: 8),
            DetailRow(icon: Icons.person, text: 'Pengguna: ${item.userEmail}'),
            const SizedBox(height: 8),
            DetailRow(icon: Icons.access_time, text: 'Waktu: ${_formatDateTime(item.startedAt)}'),
            const SizedBox(height: 8),
            DetailRow(icon: Icons.info, text: 'ID: ${item.historyId}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

// Widget untuk detail row
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const DetailRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: kPrimary),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}