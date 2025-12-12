import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'widget.dart';

String resolveApiBase(String configured) {
  // On Android emulator use 10.0.2.2 to reach host machine
  if (Platform.isAndroid) {
    // If configured host is on local network, prefer it; but emulator cannot reach host's LAN IP sometimes
    // Use 10.0.2.2 (emulator -> host) if configured is localhost or 127.0.0.1
    if (configured.contains('localhost') || configured.contains('127.0.0.1')) {
      return 'http://10.0.2.2:5000';
    }
    // If configured is a LAN IP, emulator can usually reach it directly; keep it.
  }
  return configured;
}


class ARGalleryPage extends StatefulWidget {
  const ARGalleryPage({super.key});

  @override
  State<ARGalleryPage> createState() => _ARGalleryPageState();
}

class _ARGalleryPageState extends State<ARGalleryPage> {
  final String apiBase = resolveApiBase('http://192.168.23.214:5000');
  List<dynamic> items = [];
  bool loading = true;

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

  void _onNavItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/dashboard');
    if (index == 1) return; // already on gallery
    if (index == 2) {
      // Camera action placeholder
    }
    if (index == 3) Navigator.pushReplacementNamed(context, '/dashboard');
    if (index == 4) Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cross = width > 900 ? 3 : (width > 600 ? 2 : 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeri AR'),
        backgroundColor: const Color(0xFF005954),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchItems,
        child: ListView(
          children: [
            // Hero
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF005954), Color(0xFF0B6B63)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text('Augmented Reality Experience', style: TextStyle(color: Color(0xFFC9E4E2), fontSize: 14)),
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

            // Content
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
                              onStart: () async {
                                // post history scan_start then navigate to ScanARPage
                                try {
                                  await http.post(Uri.parse('$apiBase/api/history'), headers: {'Content-Type':'application/json'}, body: json.encode({
                                    'destination_id': item['id'],
                                    'action': 'scan_start',
                                    'started_at': DateTime.now().toUtc().toIso8601String(),
                                  }));
                                } catch (_) {}
                                Navigator.pushNamed(context, '/scan', arguments: item);
                              },
                            );
                          },
                        ),
            ),

            // footer
            Container(
              color: const Color(0xFF005954),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Center(child: Text('Powered by A-Frame & MindAR', style: TextStyle(color: Color(0xFFC9E4E2)))),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(selectedIndex: 1, onItemTapped: _onNavItemTapped),
    );
  }
}

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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final item = args ?? {};
    final img = item['marker_image'] ?? '';
    final resolvedBase = resolveApiBase('http://192.168.23.214:5000');
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
