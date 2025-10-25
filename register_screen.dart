import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Import Cloud Firestore

// Ubah menjadi StatefulWidget
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Buat "controller" untuk mengambil teks
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Buat variabel untuk status loading & error
  bool _isLoading = false;
  String _errorMessage = '';

  // Buat fungsi untuk mendaftar (register)
  Future<void> _register() async {
    // Sembunyikan keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // fungsi Firebase untuk membuat user baru
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Dapatkan UID (ID unik) user yang baru daftar
      String userId = userCredential.user!.uid;

      // Dokumen ini akan memiliki ID yang sama dengan ID Auth user
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'email': _emailController.text.trim(),
        'role': 'student', // <-- Peran default adalah 'student'
        'uid': userId,
      });
      // --- AKHIR TAMBAHAN ---

      // Jika berhasil, otomatis kembali ke halaman login
      // (karena AuthGate akan mendeteksi login & pindah halaman)
      // Kita cukup 'pop' (tutup) halaman register ini
      if (mounted) Navigator.of(context).pop();

    } on FirebaseAuthException catch (e) {
      // Jika gagal, tampilkan pesan error
      setState(() {
        if (e.code == 'weak-password') {
          _errorMessage = 'Password terlalu lemah.';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'Email ini sudah terdaftar.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Format email tidak valid.';
        } else {
          _errorMessage = e.message ?? 'Terjadi kesalahan';
        }
      });
    } finally {
      // Selesai loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Bersihkan controller saat widget ditutup
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register Akun Baru"),
        backgroundColor: Colors.transparent, // Transparan
        elevation: 0, // Hilangkan bayangan
        foregroundColor: Colors.black, // Warna ikon 'kembali' jadi hitam
      ),
      backgroundColor: Color(0xFFFEF3E0),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "Buat Akun",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),

              // Hubungkan controller ke TextField
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              SizedBox(height: 20),

              // Tampilkan pesan error jika ada
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: 20),

              // Tampilkan tombol atau loading indicator
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        // Panggil fungsi _register saat ditekan
                        onPressed: _register,
                        child: Text('Register', style: TextStyle(fontSize: 18)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}