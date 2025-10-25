import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'register_screen.dart';
import 'course_list_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini LMS',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Color(0xFFFEF3E0),
      ),
      debugShowCheckedModeBanner: false,
      // 'home' tetap ke AuthGate
      home: AuthGate(),
    );
  }
}

// --- BAGIAN AUTH GATE (PENJAGA GERBANG) ---
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Dengarkan status login dari Firebase
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Jika masih loading, tampilkan putaran
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // --- PERUBAHAN 2: GANTI TUJUAN SETELAH LOGIN ---
        if (snapshot.hasData) {
          // Jika user SUDAH login (snapshot punya data)
          // Arahkan ke Halaman Course List (Dashboard Anda)
          return CourseListScreen(); 
        }
       

        // Jika user BELUM login
        return LoginScreen();
      },
    );
  }
}


// --- PERUBAHAN 3: CLASS 'HomeScreen' (YANG LAMA) SUDAH DIHAPUS ---


// --- BAGIAN LOGIN SCREEN (TETAP SAMA, TIDAK BERUBAH) ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller, loading, dan error
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  // Fungsi untuk login
  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Panggil fungsi Firebase untuk login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      // Jika gagal, tampilkan pesan error
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          _errorMessage = 'Email atau password salah.';
        } else {
          _errorMessage = e.message ?? 'Terjadi kesalahan';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.lightbulb_outline,
                size: 100,
                color: Colors.orange,
              ),
              SizedBox(height: 40),
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
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 20),
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
                        onPressed: _login,
                        child: Text('Login', style: TextStyle(fontSize: 18)),
                      ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Navigasi ke Halaman Register
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()),
                  );
                },
                child: Text(
                  'Belum punya akun? Register di sini',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}