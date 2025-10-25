import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; 

class QuizListScreen extends StatelessWidget {
  final String courseId; 
  final String courseName;

  const QuizListScreen({
    Key? key, 
    required this.courseId, 
    required this.courseName
  }) : super(key: key);

 
  Future<void> _launchURL(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa membuka link: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quiz: $courseName"),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<QuerySnapshot>(

        // --- FILTER KEMBALI KE 'courseID' ---
        // Ini membaca data yang baru saja dibuat oleh 'add_quiz_screen.dart'
        stream: FirebaseFirestore.instance
            .collection('quizzes')
            .where('courseID', isEqualTo: courseId) // <-- FILTER YANG BENAR
            .snapshots(),
        // --- AKHIR PERUBAHAN ---
            
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi error'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Belum ada kuis untuk mata pelajaran ini.'));
          }

          // Tampilkan data dalam list
          return ListView(
            padding: EdgeInsets.all(8.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              
              return Card(
                elevation: 2.0,
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: ListTile(
                  leading: Icon(Icons.quiz_rounded, color: Colors.green),
                  title: Text(data['title'] ?? 'Tanpa Judul Kuis'),
                  subtitle: Text(data['description'] ?? 'Klik untuk mengerjakan'),
                  onTap: () {
                    // Buka link kuis eksternal
                    _launchURL(data['externalUrl'], context); 
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