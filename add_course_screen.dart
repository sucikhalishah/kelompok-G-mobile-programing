import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCourseScreen extends StatefulWidget {
  // --- BARU: Tambahkan parameter opsional untuk dokumen ---
  final DocumentSnapshot? document;

  const AddCourseScreen({super.key, this.document});

  @override
  _AddCourseScreenState createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _courseNameController = TextEditingController();
  final _gradeLevelController = TextEditingController();
  bool _isLoading = false;
  
  // --- BARU: Variabel untuk mode edit ---
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    
    // --- BARU: Cek jika ini mode edit ---
    if (widget.document != null) {
      _isEditMode = true;
      // Ambil data lama dan masukkan ke controller
      final data = widget.document!.data() as Map<String, dynamic>;
      _courseNameController.text = data['courseName'];
      _gradeLevelController.text = data['gradeLevel'];
    }
  }

  // --- BARU: Ubah nama fungsi menjadi _saveCourse ---
  Future<void> _saveCourse() async {
    // Validasi form
    if (_courseNameController.text.isEmpty || _gradeLevelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nama mata pelajaran dan tingkatan harus diisi')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // --- BARU: Logika IF/ELSE untuk Edit atau Add ---
      if (_isEditMode) {
        // Mode EDIT: Update dokumen yang ada
        await widget.document!.reference.update({
          'courseName': _courseNameController.text.trim(),
          'gradeLevel': _gradeLevelController.text.trim(),
        });
      } else {
        // Mode ADD: Tambahkan dokumen baru
        await FirebaseFirestore.instance.collection('courses').add({
          'courseName': _courseNameController.text.trim(),
          'gradeLevel': _gradeLevelController.text.trim(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mata pelajaran berhasil disimpan!')),
        );
        Navigator.of(context).pop(); // Kembali ke halaman list
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _gradeLevelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // --- BARU: Judul dinamis ---
        title: Text(_isEditMode ? 'Edit Mata Pelajaran' : 'Tambah Mata Pelajaran'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _courseNameController,
              decoration: InputDecoration(
                labelText: 'Nama Mata Pelajaran (Misal: Fisika)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _gradeLevelController,
              decoration: InputDecoration(
                labelText: 'Tingkatan (Misal: Grade 11)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    // --- BARU: Panggil fungsi _saveCourse ---
                    onPressed: _saveCourse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    // --- BARU: Teks tombol dinamis ---
                    child: Text(
                      _isEditMode ? 'Simpan Perubahan' : 'Simpan Mata Pelajaran', 
                      style: TextStyle(fontSize: 18, color: Colors.white)
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}