import 'package:flutter/material.dart';

/// ===============================================================
///  CUSTOM BOTTOM NAVIGATION BAR (Versi Mobile, Berwarna, Reusable)
/// ===============================================================
///  - Cocok untuk semua halaman
///  - Tidak bergantung pada theme halaman
///  - Aksen warna modern & konsisten
///  - Kamera diletakkan di tengah sebagai tombol utama
/// ===============================================================

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Colors.white;
    const Color activeColor = Color(0xFF006D5B);   // hijau gelap elegan
    const Color inactiveColor = Color(0xFF9E9E9E); // abu lembut
    const Color cameraColor = Color(0xFF00B894);   // hijau neon modern

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(
            index: 0,
            icon: Icons.home_filled,
            label: "Home",
            active: selectedIndex == 0,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
          _buildItem(
            index: 1,
            icon: Icons.photo_library_rounded,
            label: "Gallery",
            active: selectedIndex == 1,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),

          /// CAMERA BUTTON (Center)
          _buildCameraButton(
            index: 2,
            color: cameraColor,
          ),

          _buildItem(
            index: 3,
            icon: Icons.history,
            label: "History",
            active: selectedIndex == 3,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
          _buildItem(
            index: 4,
            icon: Icons.person,
            label: "Profile",
            active: selectedIndex == 4,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
        ],
      ),
    );
  }

  /// normal item
  Widget _buildItem({
    required int index,
    required IconData icon,
    required String label,
    required bool active,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => onItemTapped(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: active ? 30 : 26,
                color: active ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? activeColor : inactiveColor,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// camera item (elevated)
  Widget _buildCameraButton({
    required int index,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onItemTapped(index),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }
}
