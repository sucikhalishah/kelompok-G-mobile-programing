import 'package:flutter/material.dart'; // <-- PASTIKAN BARIS INI TEPAT
import 'package:cloud_firestore/cloud_firestore.dart';

// Model sederhana untuk data Course di dropdown
class CourseItem {
  final String id;
  final String name;
  CourseItem({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AddQuizScreen extends StatefulWidget {
  const AddQuizScreen({super.key});

  @override
  _AddQuizScreenState createState() => _AddQuizScreenState();
}

class _AddQuizScreenState extends State<AddQuizScreen> {
  // Controller untuk form
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  
  // Variabel untuk dropdown
  CourseItem? _selectedCourse;
  bool _isLoading = false;

  Future<void> _addQuiz() async {
    // Validasi form
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan pilih mata pelajaran')),
      );
      return;
    }
    if (_titleController.text.isEmpty || 
        _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Judul kuis dan Link URL harus diisi')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // Simpan ke koleksi 'quizzes'
      await FirebaseFirestore.instance.collection('quizzes').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'externalUrl': _urlController.text, 
        'courseID': _selectedCourse!.id, 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kuis berhasil ditambahkan!')),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Kuis Baru'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            // --- DROPDOWN MATA PELAJARAN ---
            Text(
              "Pilih Mata Pelajaran:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('courses').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                
                var courseItems = snapshot.data!.docs.map((doc) {
                  return CourseItem(
                    id: doc.id,
                    name: doc['courseName'],
                  );
                }).toList();

                return DropdownButtonFormField<CourseItem>(
                  decoration: InputDecoration(
                    labelText: 'Pilih Mata Pelajaran',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCourse,
                  items: courseItems.map((course) {
                    return DropdownMenuItem<CourseItem>(
                      value: course,
                      child: Text(course.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCourse = value;
                    });
                  },
                );
              },
            ),
            SizedBox(height: 20),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Judul Kuis (misal: Kuis 1: Struktur Sel)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Deskripsi Singkat (Opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Link URL ke Quizizz',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _addQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('Simpan Kuis', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}