import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahkan ini

class ProfilePage extends StatefulWidget {
  // 1. TAMBAHKAN VARIABEL UNTUK MENERIMA DATA DARI DASHBOARD
  final Map<String, dynamic>? userData;
  const ProfilePage({super.key, this.userData}); // Update constructor

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, bool> editMode = {
    'fullName': false,
    'email': false,
    'phone': false,
    'dob': false,
    'hometown': false,
  };

  Map<String, dynamic> currentUser = {};
  Map<String, dynamic> formData = {};

  bool isLoading = true;
  String errorMessage = '';
  
  final String _apiUrl = 'http://192.168.1.26:5000/api/users/profile'; 

  @override
  void initState() {
    super.initState();
    // 2. Cek jika ada userData yang diteruskan sebelum memanggil fetch
    if (widget.userData != null) {
        fetchUserProfile();
    } else {
        setState(() {
            isLoading = false;
            errorMessage = "Error: User data is missing. Please log in again.";
        });
    }
  }

  Future<void> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    if (token == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Token tidak ditemukan. Silakan login ulang.';
      });
      return;
    }
    
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentUser = data;
          formData = Map.from(currentUser);
          isLoading = false;
        });
      } else {
        String msg = 'Failed to load profile. Status: ${response.statusCode}.';
        print(msg);
        setState(() {
          isLoading = false;
          errorMessage = msg;
        });
      }
    } catch (e) {
      String msg = 'Network/API Error: $e';
      print(msg);
      setState(() {
        isLoading = false;
        errorMessage = msg;
      });
    }
  }

  Future<void> updateProfile(String field) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse(_apiUrl), 
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(formData),
      );

      if (response.statusCode == 200) {
        setState(() {
          currentUser = Map.from(formData);
          editMode[field] = false;
        });
      } else {
        print('Failed to update profile: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  void handleEdit(String field) {
    setState(() {
      formData = Map.from(currentUser);
      editMode[field] = true;
    });
  }

  void handleCancel(String field) {
    setState(() {
      editMode[field] = false;
    });
  }

  void handleChange(String key, String value) {
    setState(() {
      formData[key] = value;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (currentUser.isEmpty && errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: isMobile ? AppBar(title: const Text("Profile")) : null,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                Text('Error: $errorMessage', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: fetchUserProfile,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- Konten Sidebar (Sapaan & Avatar) ---
    final Widget sidebarContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 29,
              backgroundColor: const Color(0xFF008080),
              child: Text(
                (currentUser['firstName'] ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 15),
            Text(
              'Hello ${currentUser['username'] ?? 'User'}!',
              style: TextStyle(
                fontSize: isMobile ? 20 : 24, 
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ],
    );

    // --- Konten Utama (Daftar Profil) ---
    final Widget mainContent = Padding(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal information',
            style: TextStyle(fontSize: isMobile ? 28 : 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          buildInfoItem(
            'fullName', 
            'Full name', 
            '${currentUser['firstName'] ?? ''} ${currentUser['lastName'] ?? ''}', 
            [ buildTextField('firstName', 'First name'), buildTextField('lastName', 'Last name') ]
          ),
          buildInfoItem(
            'email', 
            'Email', 
            currentUser['email'] ?? 'Not provided', 
            [ buildTextField('email', 'Email address', keyboardType: TextInputType.emailAddress) ]
          ),
          buildInfoItem(
            'phone', 
            'Phone number', 
            currentUser['phone'] ?? 'Not provided', 
            [ buildTextField('phone', 'Phone number', keyboardType: TextInputType.phone) ]
          ),
          buildInfoItem(
            'dob', 
            'Date of birth', 
            currentUser['dob'] ?? 'Not provided', 
            [ buildTextField('dob', 'Date of birth') ]
          ),
          buildInfoItem(
            'hometown', 
            'Home town', 
            currentUser['hometown'] ?? 'Not provided', 
            [ buildTextField('hometown', 'Home town') ]
          ),
        ],
      ),
    );

    // --- Layout Utama (Conditional) ---
    return Scaffold(
      body: SingleChildScrollView( 
        child: isMobile
            ? Column( // MODE MOBILE
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 0),
                    child: sidebarContent,
                  ),
                  const Divider(),
                  mainContent,
                ],
              )
            : Row( // MODE WEB/DESKTOP
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 400,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey)),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            sidebarContent, 
                            const SizedBox(height: 40),
                            const Text(
                                'Personal information',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                        ]
                    ),
                  ),
                  Expanded(
                    child: mainContent,
                  ),
                ],
              ),
      ),
    );
  }

  // Widget untuk menampilkan/mengedit satu item informasi
  Widget buildInfoItem(String field, String label, String value, List<Widget> editFields) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bagian Display (Label dan Value)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          
          // Bagian Edit/Add Button
          if (!editMode[field]!)
            TextButton(
              onPressed: () => handleEdit(field),
              child: Text(value.isEmpty || value == 'Not provided' ? 'Add' : 'Edit'),
            )
          else
            // Bagian Form Edit (Jika editMode aktif)
            Expanded( 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => updateProfile(field),
                        child: const Text('Save'),
                      ),
                      TextButton(
                        onPressed: () => handleCancel(field),
                        child: const Text('Cancel'),
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

  // Widget untuk membuat TextField (digunakan di mode edit)
  Widget buildTextField(String key, String label, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        decoration: InputDecoration(labelText: label),
        keyboardType: keyboardType,
        onChanged: (value) => handleChange(key, value),
        controller: TextEditingController(text: formData[key] ?? ''),
      ),
    );
  }
}