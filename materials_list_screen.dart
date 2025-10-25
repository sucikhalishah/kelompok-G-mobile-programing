import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- 1. TAMBAHKAN IMPORT INI
import 'package:url_launcher/url_launcher.dart';
import 'add_form_screen.dart'; // <-- 2. TAMBAHKAN IMPORT INI

// 3. UBAH MENJADI STATEFULWIDGET
class MaterialsListScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const MaterialsListScreen({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  _MaterialsListScreenState createState() => _MaterialsListScreenState();
}

class _MaterialsListScreenState extends State<MaterialsListScreen> {
  // LOGIKA CEK ROLE (SAMA SEPERTI COURSE_LIST)
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
  // --- AKHIR LOGIKA CEK ROLE ---

  // Fungsi untuk membuka link (tetap sama)
  Future<void> _launchURL(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa membuka link: $url')),
      );
    }
  }

  // Fungsi untuk memilih ikon (tetap sama)
  Widget _getIconForType(String type) {
    switch (type) {
      case 'link_pdf':
        return Icon(Icons.picture_as_pdf_rounded, color: Colors.red);
      case 'link_video':
        return Icon(Icons.video_library_rounded, color: Colors.blue);
      default:
        return Icon(Icons.link, color: Colors.grey);
    }
  }

  // --- 5. FUNGSI BARU UNTUK MENU ADMIN (EDIT/DELETE) ---
  void _showAdminMenu(BuildContext context, DocumentSnapshot document) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              // Tombol Edit
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Edit Materi'),
                onTap: () {
                  Navigator.pop(ctx); // Tutup bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Kirim dokumen yang mau di-edit ke AddFormScreen
                      builder: (context) => AddFormScreen(document: document),
                    ),
                  );
                },
              ),
              // Tombol Delete
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Hapus Materi'),
                onTap: () {
                  Navigator.pop(ctx); // Tutup bottom sheet
                  final title = (document.data() as Map<String, dynamic>)['title'] ?? 'Materi ini';
                  _showDeleteDialog(context, document, title);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  
  void _showDeleteDialog(BuildContext context, DocumentSnapshot document, String title) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus "$title"?'),
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
                document.reference.delete(); // Hapus dari Firestore
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$title" berhasil dihapus')),
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
        // Gunakan widget. untuk mengakses properti di StatefulWidget
        title: Text("Materials: ${widget.courseName}"), 
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('materials')
            .where('courseID', isEqualTo: widget.courseId) // Gunakan widget.
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi error'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Belum ada materi untuk mata pelajaran ini.'));
          }

          return ListView(
            padding: EdgeInsets.all(8.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              String type = data['type'] ?? 'link';

              return Card(
                elevation: 2.0,
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: ListTile(
                  leading: _getIconForType(type),
                  title: Text(data['title'] ?? 'Tanpa Judul'),
                  subtitle: Text(data['chapter'] ?? 'Chapter 1'),
                  // TOMBOL MENU JIKA GUru
                  trailing: _userRole == 'teacher'
                      ? IconButton(
                          icon: Icon(Icons.more_vert),
                          onPressed: () {
                            _showAdminMenu(context, document);
                          },
                        )
                      : null, // Siswa tidak melihat apa-apa
                  onTap: () {
                  
                    _launchURL(data['url'], context);
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