import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widget.dart'; // Mengandung CustomBottomNavBar
import 'profile.dart'; // Import ProfilePage
import 'ARGalleryPage.dart'; // Import ARGalleryPage
import 'ScanARPage.dart'; // Import ScanARPage
import 'history.dart'; // Import HistoryPage

// --- Konstanta Warna ---
const Color kPrimary = Color(0xFF004D40);
const Color kFooterText = Color(0xFFA7A7A7);
const Color kFooterBg = Color(0xFF121212);

// --- Assets Paths ---
const String assetHero = 'assets/images/hero-bg2.jpg';
const String assetBorobudur = 'assets/images/fav-dest-section-candi-borobudur.jpg';
const String assetMonas = 'assets/images/fav-dest-section-tugu-monas.jpg';
const String assetTugu = 'assets/images/fav-dest-section-tugu-jogja.jpg';
const String assetGadang = 'assets/images/fav-dest-section-jam-gadang.jpg';
const String assetKresek = 'assets/images/fav-dest-section-monumen-kresek.jpg';
const String assetPrambanan = 'assets/images/fav-dest-section-candi-prambanan.jpg';

final List<Map<String, dynamic>> destinationsData = [
  {'name': 'Monumen Kresek', 'image': assetKresek},
  {'name': 'Monas', 'image': assetMonas},
  {'name': 'Tugu Yogyakarta', 'image': assetTugu},
  {'name': 'Jam Gadang', 'image': assetGadang},
  {'name': 'Candi Borobudur', 'image': assetBorobudur},
  {'name': 'Candi Prambanan', 'image': assetPrambanan},
];

final List<Map<String, dynamic>> vrDestinations = [
  {'slug': 'candi-borobudur', 'image': assetBorobudur, 'title': 'Candi Borobudur', 'location': 'Magelang, Jawa Tengah'},
  {'slug': 'monumen-nasional', 'image': assetMonas, 'title': 'Monumen Nasional', 'location': 'Jakarta, DKI Jakarta'},
  {'slug': 'tugu-jogja', 'image': assetTugu, 'title': 'Tugu Jogjakarta', 'location': 'D.I.Yogyakarta'},
  {'slug': 'jam-gadang', 'image': assetGadang, 'title': 'Jam Gadang', 'location': 'Bukit Tinggi, Sumatera Barat'},
];

// --- Dashboard Component Widgets ---

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _currentProfileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Fungsi untuk memuat data pengguna dari SharedPreferences
  Future<void> _loadUserData() async {
    print('🔄 Dashboard: Loading user data from SharedPreferences...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final userId = prefs.getInt('user_id');
      final email = prefs.getString('email');
      final username = prefs.getString('username');
      final jwtToken = prefs.getString('jwt_token');
      
      print('📊 Dashboard SharedPreferences:');
      print('   user_id: $userId');
      print('   email: $email');
      print('   username: $username');
      print('   jwt_token: $jwtToken');
      
      if (userId != null && email != null) {
        setState(() {
          _currentProfileData = {
            'user_id': userId,
            'email': email,
            'username': username ?? 'Pengguna',
            'jwt_token': jwtToken,
          };
          _isLoading = false;
        });
        print('✅ Dashboard: User data loaded successfully');
      } else {
        // Jika tidak ada data di SharedPreferences, coba ambil dari arguments
        _loadFromArguments();
      }
    } catch (e) {
      print('❌ Dashboard: Error loading from SharedPreferences: $e');
      _loadFromArguments();
    }
  }

  void _loadFromArguments() {
    final argumentsData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (argumentsData != null && _currentProfileData == null) {
      print('📱 Dashboard: Loading from arguments: $argumentsData');
      
      setState(() {
        _currentProfileData = argumentsData;
        _isLoading = false;
      });
      
      // Simpan ke SharedPreferences untuk penggunaan selanjutnya
      _saveToSharedPreferences(argumentsData);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToSharedPreferences(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', userData['user_id'] as int);
      await prefs.setString('email', userData['email'] as String);
      await prefs.setString('username', userData['username'] as String);
      if (userData['jwt_token'] != null) {
        await prefs.setString('jwt_token', userData['jwt_token'] as String);
      }
      print('💾 Dashboard: User data saved to SharedPreferences');
    } catch (e) {
      print('❌ Dashboard: Error saving to SharedPreferences: $e');
    }
  }

  List<Widget> _pageOptions(Map<String, dynamic>? userData) => <Widget>[
    const _DashboardContent(),
    const ARGalleryPage(),
    const ScanARPage(),
    HistoryPage(userData: userData),
    ProfilePage(userData: userData),
  ];

  void _onNavBarItemTapped(int index) {
    print('🎯 Dashboard: NavBar tapped index $index');
    print('🎯 Dashboard: Current userData: $_currentProfileData');
    
    if (index == 2) {
      // Tombol Kamera Tengah
      if (_currentProfileData != null) {
        print('📸 Dashboard: Navigating to scan with userData');
        Navigator.pushNamed(
          context, 
          '/scan', 
          arguments: _currentProfileData
        );
      } else {
        print('⚠️ Dashboard: No userData available, showing error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan login terlebih dahulu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: kPrimary),
        ),
      );
    }

    final String username = _currentProfileData?['username'] ?? 'Pengguna';
    final List<Widget> pageOptionsWithData = _pageOptions(_currentProfileData);
    Widget currentBody = pageOptionsWithData.elementAt(_selectedIndex);

    if (_selectedIndex == 0) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            _CustomHeader(username: username),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  _HeroSection(username: username),
                  const _FavoriteDestinationsSection(),
                  const _ARTorioSection(),
                  const _VRTorioSection(),
                  const _FooterSection(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onNavBarItemTapped,
        ),
      );
    }

    return Scaffold(
      body: currentBody,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onNavBarItemTapped,
      ),
    );
  }
}

// --- Widget Bawaan (Sama seperti sebelumnya, disingkat) ---

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(children: [],);
  }
}

class _CustomHeader extends StatelessWidget {
  final String username;
  const _CustomHeader({required this.username});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: Colors.white,
      foregroundColor: kPrimary,
      elevation: 4.0,
      title: Text(
        'Hi, $username!',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          fontSize: 20,
          color: kPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () async {
            // Clear SharedPreferences saat logout
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/login', 
              (route) => false
            );
          },
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  final String username;
  const _HeroSection({required this.username});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.5,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage(assetHero),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5), 
            BlendMode.darken
          ),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Jelajahi Bersama Oratorio. Hidupkan Kembali Sejarah. Jelajahi Budaya Indonesia di Mana Saja.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final String imageSrc;
  final String name;

  const _DestinationCard({required this.imageSrc, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imageSrc,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteDestinationsSection extends StatelessWidget {
  const _FavoriteDestinationsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 40, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Destinasi Favorit',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.9,
            ),
            itemCount: destinationsData.length,
            itemBuilder: (context, index) {
              final destination = destinationsData[index];
              return _DestinationCard(
                name: destination['name'] as String,
                imageSrc: destination['image'] as String,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ARTorioSection extends StatelessWidget {
  const _ARTorioSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const _SectionTitle(title: 'AR TORIO', color: kPrimary),
          const SizedBox(height: 16),
          const Text(
            'Jelajahi Warisan Budaya dengan Augmented Reality',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Candi Borobudur',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/argallery');
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                  label: const Text('Lihat Semua Koleksi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)
                    ),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.grey, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.grey, thickness: 1)),
      ],
    );
  }
}

class _VRTorioSection extends StatelessWidget {
  const _VRTorioSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(title: 'VR TORIO', color: kPrimary),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.8,
            ),
            itemCount: vrDestinations.length,
            itemBuilder: (context, index) {
              final item = vrDestinations[index];
              return InkWell(
                onTap: () {},
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          item['image'] as String,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey)
                            ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '📍 ${item['title']}, ${item['location']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kFooterBg,
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {}, 
                icon: const Icon(Icons.facebook, color: Colors.white, size: 28)
              ),
              IconButton(
                onPressed: () {}, 
                icon: const Icon(Icons.share, color: Colors.white, size: 28)
              ),
              IconButton(
                onPressed: () {}, 
                icon: const Icon(Icons.videocam, color: Colors.white, size: 28)
              ),
              IconButton(
                onPressed: () {}, 
                icon: const Icon(Icons.photo_camera, color: Colors.white, size: 28)
              ),
            ],
          ),
          const SizedBox(height: 32),
          const _FooterLink(text: 'Help Center'),
          const _FooterLink(text: 'FAQ'),
          const _FooterLink(text: 'About Oratorio'),
          const _FooterLink(text: 'Destinasi'),
          const _FooterLink(text: 'Augmented Reality Interface'),
          const _FooterLink(text: 'Virtual Reality Interface'),
          const _FooterLink(text: 'Kebijakan Privasi'),
          const _FooterLink(text: 'Syarat & Ketentuan'),
          const SizedBox(height: 24),
          const Divider(color: Colors.grey, height: 1),
          const SizedBox(height: 16),
          const Text(
            '© 2025 Oratorio, Inc.',
            style: TextStyle(color: kFooterText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  const _FooterLink({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextButton(
        onPressed: () {},
        child: Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}