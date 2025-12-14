import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
// import 'widget.dart'; // Jika CustomBottomNavBar dan ScanArguments ada di sini

// --- Konstanta Warna ---
const Color kPrimaryColor = Color(0xFF005954);
const Color kAccentColor = Color(0xFFC9E4E2);

// --- MODEL ARGUMEN SCAN (Jika belum ada di widget.dart, gunakan ini) ---
class ScanArguments {
  final Map<String, dynamic> destinationData;
  final String? jwtToken;
  
  ScanArguments({required this.destinationData, this.jwtToken});
}

// --- FUNGSI RESOLUSI IP ---
String resolveApiBase(String configured) {
  if (Platform.isAndroid) {
    if (configured.contains('localhost') || configured.contains('127.0.0.1')) {
      return 'http://192.168.1.26:5000';
    }
  }
  return configured;
}

// -------------------------------------------------------------------
// 🚀 AR GALLERY PAGE (Halaman Utama)
// -------------------------------------------------------------------

class ARGalleryPage extends StatefulWidget {
  const ARGalleryPage({super.key});

  @override
  State<ARGalleryPage> createState() => _ARGalleryPageState();
}

class _ARGalleryPageState extends State<ARGalleryPage> {
  final String apiBase = resolveApiBase('http://192.168.1.26:5000');
  List<dynamic> items = [];
  bool loading = true;

  // 🎯 FUNGSI SIMULASI PENGAMBILAN JWT TOKEN
  // GANTIKAN ini dengan Shared Preferences yang sebenarnya!
  Future<String?> _getJwtToken() async {
    // Contoh nyata menggunakan SharedPreferences:
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getString('jwt_token');
    
    // SIMULASI
    await Future.delayed(const Duration(milliseconds: 100)); 
    return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjogMjMsImVtYWlsIjogImd1ZXN0QGV4YW1wbGUuY29tIn0.some_unique_signature_here"; 
  }

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse('$apiBase/api/wisata')).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body) as List<dynamic>;
        setState(() {
          items = data;
          loading = false;
        });
      } else {
        setState(() {
          items = [];
          loading = false;
        });
      }
    } catch (_) {
      setState(() {
        items = [];
        loading = false;
      });
    }
  }
  
  // FUNGSI UTAMA UNTUK MENGATASI ERROR ASYNC GAP DAN MENYIAPKAN TOKEN
  Future<void> _handleStartAR(Map<String, dynamic> item) async {
    // 1. Ambil JWT Token
    final String? token = await _getJwtToken();

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autentikasi diperlukan. Harap login untuk memulai AR Experience.')),
        );
      }
      return;
    }

    // 2. Post History (Scan Start) dengan JWT Token
    try {
      await http.post(
          Uri.parse('$apiBase/api/history'), 
          headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token', // Sertakan JWT Token
          }, 
          body: json.encode({
              'destination_id': item['id'],
              'action': 'scan_start',
              'started_at': DateTime.now().toUtc().toIso8601String(),
          }),
      );
    } catch (e) {
      // Jika post history gagal (misalnya karena server mati), tetap lanjut ke ScanARPage
      debugPrint('Error posting scan_start history: $e');
    }

    // 3. SOLUSI ERROR: Cek 'mounted' sebelum menggunakan Navigator
    if (!mounted) return; 

    // 4. Navigasi dengan Data Lengkap
    final scanArgs = ScanArguments(
      destinationData: item,
      jwtToken: token,
    );

    Navigator.pushNamed(context, '/scan', arguments: scanArgs);
  }

  // --- Navigasi Item Navbar Dihapus dari sini ---
  // Logika navigasi navbar harus berada di DashboardPage,
  // atau Anda harus memastikan Anda mengimpor CustomBottomNavBar dan menangani fungsi ini di sini.
  void _onNavItemTapped(int index) {
     // Placeholder untuk menghindari error jika CustomBottomNavBar memerlukan fungsi ini
     debugPrint('Nav Item Tapped: $index');
  }


  @override
  Widget build(BuildContext context) {
    // ❌ HILANGKAN Scaffold dan bottomNavigationBar DI SINI
    // Konten ini diasumsikan diletakkan di dalam body: Scaffold milik DashboardPage
    final width = MediaQuery.of(context).size.width;
    final cross = width > 900 ? 3 : (width > 600 ? 2 : 1);

    return RefreshIndicator(
      onRefresh: _fetchItems,
      child: ListView(
        children: [
          // Header / Hero Section (Menggunakan AppBar Kustom karena ini adalah konten)
          // Jika Anda ingin header ini tetap ada meskipun di dalam DashboardPage:
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryColor, Color(0xFF0B6B63)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Text('Augmented Reality Experience', style: TextStyle(color: kAccentColor, fontSize: 14)),
                SizedBox(height: 12),
                Text('Galeri AR', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 20)),
                SizedBox(height: 6),
                Text('Torio Wisata', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Stats bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(count: items.length, label: 'Destinasi'),
                _StatItem(countText: 'A-Frame', label: 'Framework'),
                _StatItem(countText: 'MindAR', label: 'Technology'),
              ],
            ),
          ),

          // Content Grid
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: loading
                ? SizedBox(
                    height: 220,
                    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [CircularProgressIndicator(), SizedBox(height: 8), Text('Memuat galeri AR...')])),
                  )
                : items.isEmpty
                    ? SizedBox(
                        height: 220,
                        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.photo_library, size: 48, color: Colors.grey), SizedBox(height: 8), Text('Galeri Kosong')])),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cross,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          final img = item['marker_image'] ?? '';
                          final imgUrl = img.isNotEmpty ? '$apiBase/static/uploads/$img' : null;
                          return _GalleryCard(
                            item: item,
                            imgUrl: imgUrl ?? '',
                            onStart: () => _handleStartAR(item), 
                          );
                        },
                      ),
          ),

          // footer
          Container(
            color: kPrimaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Center(child: Text('Powered by A-Frame & MindAR', style: TextStyle(color: kAccentColor))),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// 🧱 WIDGET-WIDGET PENDUKUNG
// -------------------------------------------------------------------

class _StatItem extends StatelessWidget {
  final int? count;
  final String? countText;
  final String label;
  const _StatItem({this.count, this.countText, required this.label});

  @override
  Widget build(BuildContext context) {
    final display = count != null ? count.toString() : (countText ?? '—');
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: const Color(0xFF005954).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(display, style: const TextStyle(color: Color(0xFF005954), fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _GalleryCard extends StatelessWidget {
  final dynamic item;
  final String imgUrl;
  final VoidCallback onStart;
  const _GalleryCard({required this.item, required this.imgUrl, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // image area
          SizedBox(
            height: 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
                // dark gradient
                Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.45)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                // id pill
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('#${item['id']}', style: const TextStyle(color: Color(0xFF005954), fontWeight: FontWeight.bold)),
                  ),
                ),
                // AR Ready badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF005954),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text('AR Ready', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // location pill
                if ((item['location'] ?? '').isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFC9E4E2).withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                    child: Text(item['location'] ?? '', style: const TextStyle(color: Color(0xFF005954), fontSize: 12)),
                  ),
                Text(item['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(item['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005954), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.play_arrow), SizedBox(width: 8), Text('Mulai AR Experience', style: TextStyle(fontSize: 16))]),
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

class ARViewPage extends StatelessWidget {
  const ARViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Asumsi ini adalah halaman yang menampilkan marker setelah scan berhasil
    final args = ModalRoute.of(context)?.settings.arguments;
    
    // Penanganan argumen yang masuk (diharapkan ScanArguments)
    final Map<String, dynamic> item; 
    
    if (args is ScanArguments) {
        item = args.destinationData;
        // String? jwtToken = args.jwtToken; // Token juga tersedia di sini jika diperlukan
    } else {
        item = (args as Map<String, dynamic>?) ?? {};
    }
    
    final img = item['marker_image'] ?? '';
    final resolvedBase = resolveApiBase('http://192.168.1.26:5000');
    final imgUrl = img.isNotEmpty ? '$resolvedBase/static/uploads/$img' : null;

    return Scaffold(
      appBar: AppBar(title: Text(item['name'] ?? 'AR Viewer'), backgroundColor: const Color(0xFF005954)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imgUrl != null)
              Expanded(child: Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const Center(child: Icon(Icons.broken_image))))
            else
              const SizedBox.shrink(),
            const SizedBox(height: 12),
            Text(item['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(item['description'] ?? '', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AR runtime not implemented (placeholder)')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005954)),
              child: const Text('Mulai AR Experience'),
            ),
          ],
        ),
      ),
    );
  }
}