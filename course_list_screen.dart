import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'course_detail_screen.dart';
import 'add_form_screen.dart';
import 'add_course_screen.dart';
import 'add_quiz_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  _CourseListScreenState createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted) {
          setState(() {
            _userRole = userData.get('role') ?? 'student';
          });
        }
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }

  void _showAddChoiceDialog(BuildContext context) {
    // ... (Fungsi ini tetap sama, tidak berubah) ...
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.school, color: Colors.orange),
                title: Text('Tambah Mata Pelajaran Baru'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddCourseScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.book, color: Colors.blue),
                title: Text('Tambah Materi Baru (PDF/Video)'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddFormScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.quiz, color: Colors.green),
                title: Text('Tambah Kuis Baru'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddQuizScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- FUNGSI BARU UNTUK MENU ADMIN (EDIT/DELETE) ---
  void _showAdminMenu(BuildContext context, DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final courseName = data['courseName'] ?? 'Mata pelajaran ini';

    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              // Tombol Edit
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Edit Mata Pelajaran'),
                onTap: () {
                  Navigator.pop(ctx); // Tutup bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Kirim dokumen yang mau di-edit ke AddCourseScreen
                      builder: (context) => AddCourseScreen(document: document),
                    ),
                  );
                },
              ),
              // Tombol Delete
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Hapus Mata Pelajaran'),
                onTap: () {
                  Navigator.pop(ctx); // Tutup bottom sheet
                  _showDeleteDialog(context, document, courseName);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- FUNGSI BARU UNTUK KONFIRMASI HAPUS ---
  void _showDeleteDialog(BuildContext context, DocumentSnapshot document, String courseName) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text(
            'Apakah Anda yakin ingin menghapus "$courseName"?\n\nPERHATIAN: Ini HANYA menghapus mata pelajarannya, BUKAN materi atau kuis di dalamnya.'
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // Panggil fungsi delete
                document.reference.delete();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$courseName" berhasil dihapus')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Courses"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _userRole == 'teacher'
          ? FloatingActionButton(
              onPressed: () {
                _showAddChoiceDialog(context);
              },
              backgroundColor: Colors.orange,
              child: Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan'));
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Belum ada mata pelajaran'));
          }

          return ListView(
            padding: EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              
              return Card(
                elevation: 4.0,
                margin: EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16.0),
                  title: Text(
                    data['courseName'] ?? 'Tanpa Judul',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(data['gradeLevel'] ?? 'Grade 10'),
                  
                  // --- PERUBAHAN DI SINI ---
                  // Tampilkan tombol menu jika admin, atau panah jika siswa
                  trailing: _userRole == 'teacher'
                      ? IconButton(
                          icon: Icon(Icons.more_vert),
                          onPressed: () {
                            _showAdminMenu(context, document);
                          },
                        )
                      : Icon(Icons.arrow_forward_ios),
                  // --- AKHIR PERUBAHAN ---
                  
                  onTap: () {
                    // Fungsi ini tetap sama, untuk navigasi
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(
                          courseId: document.id,
                          courseName: data['courseName'] ?? 'Detail',
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}