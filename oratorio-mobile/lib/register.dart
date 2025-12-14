import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Konstanta Warna (Perhatikan jika berbeda dari login.dart)
const Color kPrimaryR = Color(0xFF004D40);
const Color kPrimaryRDark = Color(0xFF00332A);
const Color kFooterBgR = Color(0xFF121212);
const Color kFooterTextR = Color(0xFFA7A7A7);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
    });

    final url = Uri.parse('http://192.168.1.26:5000/api/register');
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text.trim(), 'password': _passCtrl.text}),
      );
      final body = res.body.isEmpty ? {} : jsonDecode(res.body);
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        // --- NAVIGASI KEMBALI KE LOGIN SETELAH REGISTER SUKSES ---
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Register berhasil! Silakan Login.')));
        Navigator.of(context).pop(); // Kembali ke halaman login yang memanggilnya
        // ----------------------------------------------------
      } else {
        setState(() => _message = body['message'] ?? 'Gagal register');
      }
    } catch (e) {
      setState(() => _message = 'Terjadi kesalahan jaringan atau server tidak merespons');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width >= 600;
    final cardWidth = isWide ? 520.0 : mq.size.width * 0.92;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // PERBAIKAN: Menggunakan titleLarge (Pengganti headline6)
                        Text('Daftar dan Nikmati Sensasinya Sekarang!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        // PERBAIKAN: Menggunakan bodyMedium (Pengganti bodyText2)
                        Text('Create an account with your email and password.', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'Daftarkan email Anda',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Email tidak valid';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Daftarkan password Anda',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                ),
                                validator: (v) {
                                  if (v == null || v.length < 6) return 'Password minimal 6 karakter';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryR,
                                    disabledBackgroundColor: kPrimaryR.withOpacity(0.6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: _loading 
                                      ? const CircularProgressIndicator(color: Colors.white) 
                                      : const Text('Continue', style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 12),
                          Text(_message!, style: const TextStyle(color: Colors.red)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // NAVIGASI KEMBALI KE LOGIN
                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Have an account? Log in', style: TextStyle(color: kPrimaryR))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(children: const [
                          Expanded(child: Divider()),
                          SizedBox(width: 8),
                          Text('or continue with', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          SizedBox(width: 8),
                          Expanded(child: Divider()),
                        ]),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Google')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Facebook')),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  // Footer inside card
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: kFooterBgR,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(onPressed: () {}, icon: const Icon(Icons.facebook, color: Colors.white)),
                            const SizedBox(width: 12),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined, color: Colors.white)),
                            const SizedBox(width: 12),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.push_pin_outlined, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 24,
                          children: [
                            TextButton(onPressed: () {}, child: const Text('Help Center', style: TextStyle(color: kFooterTextR))),
                            TextButton(onPressed: () {}, child: const Text('FAQ', style: TextStyle(color: kFooterTextR))),
                            TextButton(onPressed: () {}, child: const Text('About Oratorio', style: TextStyle(color: kFooterTextR))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('© 2025 Oratorio, Inc.', style: const TextStyle(color: kFooterTextR, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}