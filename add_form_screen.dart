import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Model CourseItem 
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

class AddFormScreen extends StatefulWidget {
 
  final DocumentSnapshot? document;

  const AddFormScreen({super.key, this.document});

  @override
  _AddFormScreenState createState() => _AddFormScreenState();
}

class _AddFormScreenState extends State<AddFormScreen> {
  final _titleController = TextEditingController();
  final _chapterController = TextEditingController();
  final _urlController = TextEditingController();
  
  CourseItem? _selectedCourse;
  String _selectedType = 'link_pdf';
  bool _isLoading = false;
  
  
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    
    // 3. LOGIKA UNTUK MENGISI FORM SAAT EDIT
    if (widget.document != null) {
      _isEditMode = true;
      final data = widget.document!.data() as Map<String, dynamic>;

      _titleController.text = data['title'] ?? '';
      _chapterController.text = data['chapter'] ?? '';
      _urlController.text = data['url'] ?? '';
      _selectedType = data['type'] ?? 'link_pdf';
      

    }
  }


  Future<void> _saveMaterial() async {
    // Validasi form
    // Hanya validasi course jika BUKAN mode edit
    if (!_isEditMode && _selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan pilih mata pelajaran')),
      );
      return;
    }
    if (_titleController.text.isEmpty ||
        _chapterController.text.isEmpty ||
        _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    // 5. BUAT DATA MAP
    final Map<String, dynamic> materialData = {
      'title': _titleController.text,
      'chapter': _chapterController.text,
      'url': _urlController.text,
      'type': _selectedType,
    };

    try {
      //LOGIKA IF/ELSE UNTUK EDIT ATAU ADD
      if (_isEditMode) {
        // Mode EDIT: Update dokumen yang ada
        // Kita tidak mengubah 'courseID'
        await widget.document!.reference.update(materialData);
      } else {
        // Mode ADD: Tambahkan 'courseID' dan buat dokumen baru
        materialData['courseID'] = _selectedCourse!.id;
        await FirebaseFirestore.instance.collection('materials').add(materialData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Materi berhasil disimpan!')),
        );
        Navigator.of(context).pop();
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
    _titleController.dispose();
    _chapterController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //JUDUL DINAMIS
        title: Text(_isEditMode ? 'Edit Materi' : 'Tambah Materi Baru'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // SEMBUNYIKAN DROPDOWN JIKA MODE EDIT
            if (!_isEditMode) ...[
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
            ],
            // --- AKHIR BLOK IF ---

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Judul (misal: Bab 1: Sel)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            
            TextField(
              controller: _chapterController,
              decoration: InputDecoration(
                labelText: 'Chapter (misal: Chapter 1)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Link Google Drive / YouTube',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Pilih Tipe Link',
                border: OutlineInputBorder()
              ),
              value: _selectedType,
              items: [
                DropdownMenuItem(value: 'link_pdf', child: Text('Link PDF')),
                DropdownMenuItem(value: 'link_video', child: Text('Link Video/YouTube')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      // PANGGIL FUNGSI '_saveMaterial'
                      onPressed: _saveMaterial, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      // TEKS TOMBOL DINAMIS
                      child: Text(
                        _isEditMode ? 'Simpan Perubahan' : 'Simpan',
                        style: TextStyle(fontSize: 18, color: Colors.white)
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}