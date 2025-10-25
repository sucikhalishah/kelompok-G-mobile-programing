import 'package:flutter/material.dart';
import 'materials_list_screen.dart'; 
import 'quiz_list_screen.dart';    

class CourseDetailScreen extends StatelessWidget {
  final String courseId;
  final String courseName;

  // Terima data courseId dan courseName dari halaman sebelumnya
  const CourseDetailScreen({
    Key? key, 
    required this.courseId, 
    required this.courseName
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(courseName), // Judulnya dinamis
        backgroundColor: Colors.orange,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card untuk Navigasi ke 'Materials'
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                leading: Icon(Icons.book, color: Colors.orange, size: 40),
                title: Text("Materials", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Lihat semua materi PDF dan video"),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  // Pindah ke halaman Materials
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MaterialsListScreen(
                        courseId: courseId, // Kirim courseId
                        courseName: courseName,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(height: 16), // Jarak

            // Card untuk Navigasi ke 'Quiz'
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                leading: Icon(Icons.quiz, color: Colors.blue, size: 40),
                title: Text("Quiz", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Kerjakan kuis untuk tes pemahaman"),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  // Pindah ke halaman Quiz
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizListScreen(
                        courseId: courseId, // Kirim courseId
                        courseName: courseName,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}