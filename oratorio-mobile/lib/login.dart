import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Untuk TimeoutException

// Konstanta Warna 
const Color kPrimary = Color(0xFF004D40);
const Color kPrimaryDark = Color(0xFF00332A);
const Color kFooterBg = Color(0xFF121212);
const Color kFooterText = Color(0xFFA7A7A7);

// ⚠️ GANTI INI DENGAN IP KOMPUTER LOKAL KAMU (misalnya 'http://192.168.1.10:5000')
// Jika menggunakan emulator Android, coba 'http://10.0.2.2:5000'
// Berdasarkan gambar kamu, IP-mu mungkin:
const String BASE_URL = 'http://192.168.23.214:5000'; 

class LoginPage extends StatefulWidget {
    const LoginPage({super.key});

    @override
    State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
    final _formKey = GlobalKey<FormState>();
    final _emailCtl = TextEditingController();
    final _passCtl = TextEditingController();
    bool _loading = false;
    String? _message;

    @override
    void dispose() {
        _emailCtl.dispose();
        _passCtl.dispose();
        super.dispose();
    }

    // 🚀 FUNGSI SUBMIT DENGAN PANGGILAN API FLASK (MENGGUNAKAN /api/login)
    Future<void> _submit() async {
        if (!_formKey.currentState!.validate()) return;
        
        setState(() {
            _loading = true;
            _message = null;
        });

        final String email = _emailCtl.text.trim();
        final String password = _passCtl.text;
        
        // 1. Siapkan data yang akan dikirim
        final body = json.encode({
            "email": email,
            "password": password,
        });
        
        try {
            // 2. Kirim Permintaan HTTP POST ke ENDPOINT /api/login (Database)
            final response = await http.post(
                Uri.parse('$BASE_URL/api/login'), // 🎯 PERUBAHAN DI SINI! Menggunakan endpoint DB
                headers: {'Content-Type': 'application/json'},
                body: body,
            ).timeout(const Duration(seconds: 10)); // Tambahkan timeout untuk penanganan error

            // 3. Proses Respon
            final Map<String, dynamic> responseData = json.decode(response.body);

            if (response.statusCode == 200 && responseData['status'] == 'ok') {
                // ✅ Login Sukses
                if (!mounted) return;
                
                final user = responseData['user']; 
                
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Login berhasil! Selamat datang, ${user['username']}'),
                        backgroundColor: kPrimary,
                    ),
                );
                // Navigasi ke Dashboard dan kirim data user
                Navigator.pushReplacementNamed(context, '/dashboard', arguments: user);
                
            } else {
                // ❌ Login Gagal (Status code 401, 400, atau status: error)
                final errorMessage = responseData['message'] ?? 'Login gagal, coba lagi.';
                if (mounted) {
                    setState(() {
                        _message = errorMessage;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
                    );
                }
            }
            
        } on TimeoutException {
             if (mounted) {
                setState(() {
                    _message = 'Gagal terhubung: Server lambat atau tidak merespons (Timeout 10s).';
                });
            }
        } catch (e) {
            // ⚠️ Error Jaringan (SocketException)
            if (mounted) {
                setState(() {
                    _message = 'Gagal koneksi. Pastikan Flask Server berjalan di $BASE_URL.';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error Jaringan: ${e.runtimeType}'), backgroundColor: Colors.red),
                );
            }
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
                                                Text('Masuk dan Mulai Jelajahi Semuanya!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                                                const SizedBox(height: 8),
                                                Text('Log into your account with your email, or create one below. Quick and easy - promise!', style: Theme.of(context).textTheme.bodyMedium),
                                                const SizedBox(height: 20),
                                                Form(
                                                    key: _formKey,
                                                    child: Column(
                                                        children: [
                                                            TextFormField(
                                                                controller: _emailCtl,
                                                                keyboardType: TextInputType.emailAddress,
                                                                decoration: const InputDecoration(
                                                                    labelText: 'Email',
                                                                    hintText: 'Masukkan email Anda',
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
                                                                controller: _passCtl,
                                                                obscureText: true,
                                                                decoration: const InputDecoration(
                                                                    labelText: 'Password',
                                                                    hintText: 'Masukkan password Anda',
                                                                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                                                ),
                                                                validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                                                            ),
                                                            const SizedBox(height: 16),
                                                            SizedBox(
                                                                width: double.infinity,
                                                                height: 52,
                                                                child: ElevatedButton(
                                                                    onPressed: _loading ? null : _submit,
                                                                    style: ElevatedButton.styleFrom(
                                                                        backgroundColor: kPrimary,
                                                                        disabledBackgroundColor: kPrimary.withOpacity(0.6),
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
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                        TextButton(
                                                            onPressed: () => Navigator.pushNamed(context, '/register'), 
                                                            child: const Text('Register Now', style: TextStyle(color: kPrimary)),
                                                        ),
                                                        TextButton(onPressed: () {}, child: const Text('Lupa Sandi?', style: TextStyle(color: kPrimary))),
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
                                                                    backgroundColor: Colors.white,
                                                                ),
                                                                child: const Padding(
                                                                    padding: EdgeInsets.symmetric(vertical: 12),
                                                                    child: Text('Google'),
                                                                ),
                                                            ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                            child: OutlinedButton(
                                                                onPressed: () {},
                                                                style: OutlinedButton.styleFrom(
                                                                    side: const BorderSide(color: Colors.grey),
                                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                                    backgroundColor: Colors.white,
                                                                ),
                                                                child: const Padding(
                                                                    padding: EdgeInsets.symmetric(vertical: 12),
                                                                    child: Text('Facebook'),
                                                                ),
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                                const SizedBox(height: 12),
                                                Text.rich(
                                                    TextSpan(
                                                        text: 'By creating an account, you agree to our ',
                                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                        children: [
                                                            TextSpan(text: 'Terms & Conditions', style: const TextStyle(color: kPrimary)),
                                                            const TextSpan(text: ', '),
                                                            TextSpan(text: 'Privacy Policy', style: const TextStyle(color: kPrimary)),
                                                            const TextSpan(text: ' and Agreement with Oratorio.'),
                                                        ],
                                                    ),
                                                ),
                                                const SizedBox(height: 16),
                                            ],
                                        ),
                                    ),
                                    // Footer inside card
                                    Container(
                                        width: double.infinity,
                                        decoration: const BoxDecoration(
                                            color: kFooterBg,
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
                                                        TextButton(onPressed: () {}, child: const Text('Help Center', style: TextStyle(color: kFooterText))),
                                                        TextButton(onPressed: () {}, child: const Text('FAQ', style: TextStyle(color: kFooterText))),
                                                        TextButton(onPressed: () {}, child: const Text('About Oratorio', style: TextStyle(color: kFooterText))),
                                                    ],
                                                ),
                                                const SizedBox(height: 12),
                                                Text('© 2025 Oratorio, Inc.', style: const TextStyle(color: kFooterText, fontSize: 12)),
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